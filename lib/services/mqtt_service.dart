import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_factory.dart';

/// Data kotak alat FloraPulse, diisi dari pesan status yang dikirim alat.
///
/// Format pesan di topik `florapulse/device/<id>/status` (JSON):
/// `{"id":"FP-Desa-01","name":"Kotak Kebun Utama","online":true,
///   "valves":6,"battery":98,"rssi":-58,"pump":false}`
/// `battery` boleh `null` kalau alat tidak punya sensor baterai.
class FloraDevice {
  FloraDevice({
    required this.id,
    required this.name,
    required this.valves,
    required this.lastSeen,
    this.battery,
    this.rssi,
    this.pumpOn = false,
  });

  final String id;
  final String name;
  final int valves;
  final int? battery;
  final int? rssi;
  final bool pumpOn;
  final DateTime lastSeen;

  static FloraDevice? fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    return FloraDevice(
      id: id,
      name: (j['name'] as String?) ?? id,
      valves: (j['valves'] as num?)?.toInt() ?? 1,
      battery: (j['battery'] as num?)?.toInt(),
      rssi: (j['rssi'] as num?)?.toInt(),
      pumpOn: j['pump'] == true,
      lastSeen: DateTime.now(),
    );
  }

  bool get isFresh => DateTime.now().difference(lastSeen) < MqttService.deviceTtl;

  String get signalLabel {
    final r = rssi;
    if (r == null) return 'Sinyal WiFi tidak diketahui';
    final kualitas = r >= -60
        ? 'Sangat Kuat'
        : r >= -70
            ? 'Kuat'
            : r >= -80
                ? 'Sedang'
                : 'Lemah';
    return 'Sinyal WiFi $kualitas ($r dBm)';
  }

  String get batteryLabel {
    final b = battery;
    if (b == null) return 'Tanpa sensor baterai';
    final kondisi = b >= 60
        ? 'Sehat'
        : b >= 30
            ? 'Cukup'
            : 'Lemah';
    return '$b% ($kondisi)';
  }
}

/// Satu baris log pesan MQTT (dikirim app atau diterima dari alat).
class MqttLogEntry {
  MqttLogEntry({required this.sent, required this.topic, required this.payload})
      : time = DateTime.now();

  final DateTime time;
  final bool sent;
  final String topic;
  final String payload;
}

enum ScanState { idle, connecting, scanning, done, serverError }

/// Koneksi MQTT ke broker publik EMQX: cari alat, kontrol pompa/kran.
class MqttService extends ChangeNotifier {
  MqttService._();
  static final MqttService instance = MqttService._();

  static const String host = 'broker.emqx.io';
  static const String topic = 'florapulse/pompa/kontrol';
  static const String discoverTopic = 'florapulse/discover';
  static const String statusTopic = 'florapulse/device/+/status';
  static const Duration scanTimeout = Duration(seconds: 15);

  /// Alat dianggap hilang kalau tidak kirim status selama ini.
  static const Duration deviceTtl = Duration(seconds: 45);

  MqttClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  Timer? _scanTimer;
  Timer? _pruneTimer;

  bool isConnected = false;
  bool isConnecting = false;
  bool isPompaOn = false;

  ScanState scanState = ScanState.idle;
  final Map<String, FloraDevice> _devices = {};
  String? selectedId;

  /// Riwayat pesan terbaru (paling baru di depan).
  final List<MqttLogEntry> log = [];
  static const int _maxLog = 30;

  void _addLog(bool sent, String topic, String payload) {
    log.insert(0, MqttLogEntry(sent: sent, topic: topic, payload: payload));
    if (log.length > _maxLog) log.removeLast();
  }

  List<FloraDevice> get devices =>
      _devices.values.where((d) => d.isFresh).toList()..sort((a, b) => a.id.compareTo(b.id));

  FloraDevice? get selected {
    final id = selectedId;
    return id == null ? null : _devices[id];
  }

  Future<bool> connect() async {
    if (isConnected) return true;
    if (isConnecting) return false;
    isConnecting = true;
    notifyListeners();

    try {
      isConnected = await _connectClient();
    } catch (e) {
      debugPrint('Gagal terhubung: $e');
      isConnected = false;
    } finally {
      isConnecting = false;
      notifyListeners();
    }
    return isConnected;
  }

  Future<bool> _connectClient() async {
    // Membuat Client ID acak
    final clientId = 'FlutterApp-${Random().nextInt(100000)}';
    final client = buatMqttClient(host, clientId)
      ..keepAlivePeriod = 60
      ..onDisconnected = _onDisconnected;
    client.logging(on: false);
    client.connectionMessage =
        MqttConnectMessage().withClientIdentifier(clientId).startClean();
    _client = client;

    try {
      debugPrint('Menghubungkan ke MQTT Broker...');
      await client.connect();
    } catch (e) {
      debugPrint('Gagal terhubung: $e');
      client.disconnect();
    }

    final ok = client.connectionStatus?.state == MqttConnectionState.connected;
    debugPrint(ok
        ? 'Terhubung ke Broker MQTT!'
        : 'Koneksi gagal, status: ${client.connectionStatus?.state}');
    if (ok) {
      await _updatesSub?.cancel();
      _updatesSub = client.updates?.listen(_onMessages);
      client.subscribe(statusTopic, MqttQos.atLeastOnce);
      _pruneTimer?.cancel();
      _pruneTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pruneStale());
    }
    return ok;
  }

  /// Buang alat yang sudah tidak kirim status (mati/putus tanpa pamit).
  void _pruneStale() {
    final before = _devices.length;
    _devices.removeWhere((_, d) => !d.isFresh);
    if (_devices.length != before) notifyListeners();
  }

  void _onDisconnected() {
    isConnected = false;
    notifyListeners();
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    var changed = false;
    for (final m in messages) {
      final msg = m.payload;
      if (msg is! MqttPublishMessage) continue;
      // Pesan retained bisa basi (alat sudah mati). Hanya percaya pesan live.
      if (msg.header?.retain ?? false) continue;
      final text = utf8.decode(msg.payload.message, allowMalformed: true);
      _addLog(false, m.topic, text);
      changed = true;
      try {
        final data = jsonDecode(text);
        if (data is! Map<String, dynamic>) continue;
        final id = data['id'];
        if (data['online'] == false && id is String) {
          _devices.remove(id);
          continue;
        }
        final device = FloraDevice.fromJson(data);
        if (device == null) continue;
        _devices[device.id] = device;
        if (device.id == selectedId) isPompaOn = device.pumpOn;
        changed = true;
      } catch (e) {
        debugPrint('Status alat tidak valid di ${m.topic}: $e');
      }
    }
    if (changed) {
      if (selectedId == null && devices.length == 1) selectedId = devices.first.id;
      notifyListeners();
    }
  }

  /// Cari alat: kirim ping ke `florapulse/discover`, tunggu alat menjawab
  /// lewat topik status. Hanya alat yang benar-benar menjawab yang muncul.
  Future<void> scan() async {
    _scanTimer?.cancel();
    _devices.clear();
    selectedId = null;
    scanState = ScanState.connecting;
    notifyListeners();

    if (!await connect()) {
      scanState = ScanState.serverError;
      notifyListeners();
      return;
    }

    scanState = ScanState.scanning;
    notifyListeners();
    _publish(discoverTopic, jsonEncode({'from': 'app'}));

    _scanTimer = Timer(scanTimeout, () {
      scanState = ScanState.done;
      notifyListeners();
    });
  }

  void stopScan() {
    _scanTimer?.cancel();
    if (scanState == ScanState.scanning) scanState = ScanState.done;
  }

  void select(String id) {
    selectedId = id;
    notifyListeners();
  }

  void _publish(String t, String text) {
    final builder = MqttClientPayloadBuilder()..addString(text);
    _client?.publishMessage(t, MqttQos.atLeastOnce, builder.payload!);
    _addLog(true, t, text);
  }

  /// Kirim "1" untuk nyala, "0" untuk mati.
  bool kirimPerintah(bool turnOn) {
    if (!isConnected || _client == null) return false;
    _publish(topic, turnOn ? '1' : '0');
    isPompaOn = turnOn;
    notifyListeners();
    debugPrint(turnOn ? 'Mengirim perintah NYALA' : 'Mengirim perintah MATI');
    return true;
  }
}
