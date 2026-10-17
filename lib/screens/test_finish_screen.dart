import 'dart:async';

import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import 'plant_zones_screen.dart';

/// Figma: "FloraPulse - Uji Coba & Selesai"
class TestFinishScreen extends StatefulWidget {
  const TestFinishScreen({super.key, required this.zones});

  final List<PlantZone> zones;

  @override
  State<TestFinishScreen> createState() => _TestFinishScreenState();
}

class _TestFinishScreenState extends State<TestFinishScreen> {
  final _mqtt = MqttService.instance;
  /// Perintah yang menunggu konfirmasi alat (true = nyala, false = mati).
  bool? _pending;
  bool _noReply = false;
  Timer? _replyTimer;

  @override
  void initState() {
    super.initState();
    _mqtt.addListener(_onMqtt);
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _mqtt.removeListener(_onMqtt);
    super.dispose();
  }

  void _onMqtt() {
    if (!mounted) return;
    setState(() {
      final device = _mqtt.selected;
      // Alat melapor status pompa sesuai perintah -> terkonfirmasi.
      if (_pending != null && device != null && device.pumpOn == _pending) {
        _pending = null;
        _replyTimer?.cancel();
      }
    });
  }

  Future<void> _kirim(bool nyala) async {
    if (!_mqtt.isConnected) {
      final ok = await _mqtt.connect();
      if (!mounted) return;
      if (!ok) {
        showSnack(context, 'Belum terhubung ke server. Perintah tidak bisa dikirim.');
        return;
      }
    }
    if (!_mqtt.kirimPerintah(nyala)) return;
    setState(() {
      _pending = nyala;
      _noReply = false;
    });
    // Batas tunggu balasan alat, bukan durasi kran menyala.
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _pending == null) return;
      setState(() {
        _pending = null;
        _noReply = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: StepProgress(step: 3, label: 'Langkah 3 dari 3 • Selesai'),
        ),
        const SizedBox(height: 16),
        _CelebrationCard(device: _mqtt.selected),
        const SizedBox(height: 16),
        _testCard(),
        const SizedBox(height: 16),
        _summaryCard(),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Masuk ke Beranda Kebun',
          fontSize: 16,
          trailing: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen(zones: widget.zones)),
            (_) => false,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => showSnack(context, 'Panduan PDF sedang disiapkan...'),
          icon: const Icon(Icons.download_for_offline_outlined,
              size: 16, color: AppColors.secondary),
          label: Text(
            'Simpan Panduan Penggunaan ke HP (PDF)',
            style: AppText.jakarta(14,
                color: AppColors.secondary,
                spacing: 0.14,
                decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _testCard() {
    final device = _mqtt.selected;
    final online = device?.isFresh ?? false;
    final pumpOn = device?.pumpOn ?? false;
    final waiting = _pending != null;

    final String status;
    final String sub;
    final Color dotColor;
    if (waiting) {
      status = 'Perintah ${_pending! ? 'NYALA' : 'MATI'} terkirim';
      sub = 'Menunggu konfirmasi dari alat...';
      dotColor = Colors.amber;
    } else if (_noReply) {
      status = 'Alat tidak mengonfirmasi';
      sub = 'Cek koneksi alat dan kode ESP32, lalu coba lagi';
      dotColor = const Color(0xFFB3261E);
    } else if (!online) {
      status = 'Alat tidak merespons';
      sub = 'Pastikan kotak alat menyala dan tersambung';
      dotColor = const Color(0xFFB3261E);
    } else {
      status = 'Alat konfirmasi: kran ${pumpOn ? 'TERBUKA' : 'TERTUTUP'}';
      sub = pumpOn ? 'Air sedang mengalir' : 'Siap diuji coba';
      dotColor = pumpOn ? Colors.lightBlue : AppColors.primarySoft;
    }

    // Tombol mengikuti status yang dilaporkan alat, bukan tebakan app.
    final nextNyala = !pumpOn;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const IconCircle(icon: Icons.shower_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Uji Kran Air Jalur 1',
                      style: AppText.jakarta(16, height: 22, spacing: -0.08)),
                  Text('Nyalakan lalu matikan kran secara manual',
                      style: AppText.inter(12, height: 18, spacing: 0.12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.container,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status, style: AppText.jakarta(12, spacing: 0.24, height: 16)),
                    Text(sub, style: AppText.inter(12, height: 18, spacing: 0.12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Material(
            color: nextNyala ? AppColors.containerHighest : AppColors.primary,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: waiting ? null : () => _kirim(nextNyala),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (waiting) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: nextNyala ? AppColors.primary : Colors.white),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      nextNyala ? '💧 Nyalakan Kran' : 'Matikan Kran',
                      style: AppText.jakarta(16,
                          color: nextNyala ? AppColors.primary : Colors.white,
                          height: 22,
                          spacing: -0.08),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DataLog(entries: _mqtt.log),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final kran = [for (var i = 0; i < widget.zones.length; i++) '${i + 1}'].join(', ');
    final device = _mqtt.selected;
    final online = device?.isFresh ?? false;
    final baterai = device?.battery;
    final items = [
      (
        _mqtt.isConnected ? 'Server Terhubung' : 'Server Terputus',
        device?.signalLabel ?? 'Alat belum dipilih',
        AppColors.secondary,
        _mqtt.isConnected,
      ),
      (
        '${widget.zones.length} Jalur Tanaman Terdaftar',
        'Kran Solenoid $kran',
        AppColors.onSurfaceVariant,
        widget.zones.isNotEmpty,
      ),
      (
        'Kotak Alat',
        device == null ? '-' : '${device.id} • ${online ? 'Online' : 'Offline'}',
        AppColors.primary,
        online,
      ),
      (
        'Daya Baterai/Aki',
        device?.batteryLabel ?? '-',
        AppColors.secondary,
        device != null && (baterai == null || baterai >= 30),
      ),
    ];
    final valid = items.where((i) => i.$4).length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(
                child: Text('Ringkasan Konfigurasi',
                    style: AppText.jakarta(16, height: 22, spacing: -0.08)),
              ),
              Text('$valid/${items.length} VALID',
                  style: AppText.jakarta(11,
                      weight: FontWeight.w700,
                      color: valid == items.length ? AppColors.primary : const Color(0xFFB3261E),
                      spacing: 0.55)),
            ]),
          ),
          const SizedBox(height: 4),
          for (final (title, value, color, ok) in items) ...[
            _SummaryRow(title: title, value: value, valueColor: color, ok: ok),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.value,
    required this.valueColor,
    this.ok = true,
  });

  final String title;
  final String value;
  final Color valueColor;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xB3EBF7E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        ok
            ? const IconCircle(icon: Icons.check, size: 28, iconSize: 16)
            : const IconCircle(
                icon: Icons.priority_high,
                size: 28,
                iconSize: 16,
                color: Color(0xFFFBE4E1),
                iconColor: Color(0xFFB3261E),
              ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: AppText.inter(14, color: AppColors.onSurface, height: 20)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: AppText.jakarta(12, color: valueColor, spacing: 0.24, height: 16)),
        ),
      ]),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({required this.device});

  final FloraDevice? device;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.container,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -32,
            top: -32,
            child: GlowBlob(size: 128, color: Color(0x66C0EFBA)),
          ),
          const Positioned(
            left: -24,
            bottom: -24,
            child: GlowBlob(size: 112, color: Color(0x4DBCF0AE), blur: 12),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.card,
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      decoration: const BoxDecoration(
                          color: Color(0x4DBCF0AE), shape: BoxShape.circle),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                          color: AppColors.primarySoft, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_outline,
                          color: AppColors.accentLight, size: 32),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Text('Alat Siap Digunakan!',
                    textAlign: TextAlign.center,
                    style: AppText.jakarta(26, height: 34, spacing: -0.52)),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    'Kotak FloraPulse Anda sudah terhubung dan siap menjaga kebun tetap segar secara otomatis.',
                    textAlign: TextAlign.center,
                    style: AppText.inter(14, height: 22),
                  ),
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  title: 'Daya Baterai/Aki',
                  value: device?.batteryLabel ?? '-',
                  valueColor: AppColors.secondary,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xCCDAE6D7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.primarySoft, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(device == null ? 'Belum ada alat' : '${device!.id} • ${device!.name}',
                        style: AppText.jakarta(12, spacing: 0.24, height: 16)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataLog extends StatelessWidget {
  const _DataLog({required this.entries});

  final List<MqttLogEntry> entries;

  static String _jam(DateTime t) =>
      [t.hour, t.minute, t.second].map((v) => v.toString().padLeft(2, '0')).join(':');

  @override
  Widget build(BuildContext context) {
    final mono = AppText.inter(11, color: AppColors.onSurface, height: 16)
        .copyWith(fontFamily: 'monospace');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.swap_vert, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text('Data Terkirim & Diterima',
                style: AppText.jakarta(12, color: AppColors.primary, spacing: 0.24)),
          ),
          Text('${entries.length} pesan',
              style: AppText.jakarta(11, color: AppColors.secondary, spacing: 0.44)),
        ]),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.container,
            borderRadius: BorderRadius.circular(8),
          ),
          child: entries.isEmpty
              ? Text('Belum ada data.', style: AppText.inter(12))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 10),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_jam(e.time)}  ${e.sent ? '↑ KIRIM' : '↓ TERIMA'}  ${e.topic}',
                          style: AppText.jakarta(10,
                              weight: FontWeight.w700,
                              color: e.sent ? AppColors.secondary : AppColors.primary,
                              spacing: 0.3),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(e.payload, style: mono),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
