import 'dart:async';

import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'notifications_screen.dart';
import 'plant_zones_screen.dart';
import 'welcome_screen.dart';

const _danger = Color(0xFFB3261E);
const _dangerSoft = Color(0xFFFFDAD6);

const _cardShadow = [
  BoxShadow(
    color: Color(0x0A19231A),
    offset: Offset(0, 4),
    blurRadius: 20,
    spreadRadius: -2,
  ),
  BoxShadow(
    color: Color(0x0519231A),
    offset: Offset(0, 2),
    blurRadius: 6,
    spreadRadius: -1,
  ),
];
const _bigShadow = [
  BoxShadow(
    color: Color(0x0D2D5A27),
    offset: Offset(0, 12),
    blurRadius: 32,
    spreadRadius: -4,
  ),
  BoxShadow(
    color: Color(0x0819231A),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: -2,
  ),
];

/// Figma: "FloraPulse - Beranda Kebun"
///
/// Semua angka diambil dari status yang dikirim alat. Kalau alat belum
/// punya sensornya, kartu menampilkan "belum ada sensor", bukan angka karangan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.zones = const []});

  final List<PlantZone> zones;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mqtt = MqttService.instance;

  @override
  void initState() {
    super.initState();
    if (!_mqtt.isConnected) _mqtt.connect();
  }

  void _segera(String halaman) =>
      showSnack(context, 'Halaman $halaman belum dibuat.');

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _Header(
        onBell: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        onTap: (i) {
          if (i != 0) {
            _segera(const ['Beranda', 'Jadwal', 'Rak Kebun', 'Pengaturan'][i]);
          }
        },
      ),
      body: ListenableBuilder(
        listenable: _mqtt,
        builder: (context, _) {
          final device = _mqtt.selected;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              64 + pad.top + 8,
              16,
              80 + pad.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Greeting(device: device, connected: _mqtt.isConnected),
                const SizedBox(height: 24),
                // Tombol siram paling sering dipakai: taruh di atas kartu sensor.
                _ManualWatering(
                  mqtt: _mqtt,
                  activeZones: widget.zones.where((z) => z.enabled).length,
                ),
                const SizedBox(height: 24),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _BatteryCard(device: device)),
                      const SizedBox(width: 16),
                      Expanded(child: _TankCard(device: device)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _RackCard(
                  zones: widget.zones,
                  device: device,
                  lastWateredAt: _mqtt.lastWateredAt,
                  onToggle: (z) => setState(() => z.enabled = !z.enabled),
                  onResetup: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  ),
                ),
                if (!_mqtt.isConnected && !_mqtt.isConnecting) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Hubungkan Ulang ke Server',
                    leading: Icons.refresh,
                    onPressed: _mqtt.connect,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header & navigasi

class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header({required this.onBell});

  final VoidCallback onBell;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // Tanpa blur latar: berat di HP kelas bawah.
    return Container(
      height: 64 + top,
      padding: EdgeInsets.only(top: top, left: 16, right: 8),
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const FloraLogo(size: 32),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'FloraPulse',
              style: AppText.jakarta(
                18,
                color: AppColors.primary,
                height: 24,
                spacing: -0.45,
              ),
            ),
          ),
          // Hanya lonceng yang ikut rebuild saat jumlah notifikasi berubah.
          ListenableBuilder(
            listenable: MqttService.instance,
            builder: (context, _) {
              final unread = MqttService.instance.unreadCount;
              return IconButton(
                onPressed: onBell,
                tooltip: 'Notifikasi',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  backgroundColor: _danger,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: Icon(
                    unread > 0 ? Icons.notifications_active_outlined : Icons.notifications_none,
                    color: AppColors.onSurface,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onTap});

  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.yard_outlined, 'Beranda'),
    (Icons.water_drop_outlined, 'Jadwal'),
    (Icons.grid_view, 'Rak Kebun'),
    (Icons.settings_outlined, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 80 + bottom,
      padding: EdgeInsets.only(bottom: bottom, left: 8, right: 8),
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, -1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          for (final (i, (icon, label)) in _items.indexed)
            Expanded(
              child: InkResponse(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: i == 0
                          ? AppColors.primarySoft
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppText.jakarta(
                        12,
                        color: i == 0
                            ? AppColors.primarySoft
                            : AppColors.onSurfaceVariant,
                        height: 16,
                        spacing: 0.24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sapaan & status

class _Greeting extends StatelessWidget {
  const _Greeting({required this.device, required this.connected});

  final FloraDevice? device;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final online = connected && (device?.isFresh ?? false);
    final status = !connected
        ? 'SERVER TERPUTUS'
        : device == null
        ? 'BELUM ADA ALAT'
        : online
        ? 'SISTEM NORMAL'
        : 'ALAT OFFLINE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS KEBUN & KONTROL',
          style: AppText.jakarta(
            11,
            color: AppColors.secondary,
            height: 14,
            spacing: 0.55,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                device?.name ?? 'Kebun Saya',
                style: AppText.jakarta(26, height: 34, spacing: -0.65),
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(label: status, ok: online),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          device == null
              ? 'Hubungkan kotak alat lewat Pengaturan untuk mulai.'
              : '${device!.id} • ${device!.signalLabel}',
          style: AppText.inter(12, height: 18, spacing: 0.12),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final fg = ok ? AppColors.secondaryText : _danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? AppColors.accent : _dangerSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ok ? AppColors.primary : _danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.jakarta(11, color: fg, height: 14, spacing: 0.55),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu telemetri (aki & tangki)

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.icon,
    required this.pill,
    required this.label,
    required this.value,
    required this.note,
    this.unit,
    this.progress,
    this.barColor = AppColors.primarySoft,
  });

  final IconData icon;
  final String? pill;
  final String label;
  final String value;
  final String? unit;
  final String note;
  final double? progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0x66BDECB7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const Spacer(),
              if (pill != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pill!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.jakarta(
                        11,
                        color: AppColors.secondaryText,
                        height: 14,
                        spacing: 0.44,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppText.jakarta(
              11,
              color: AppColors.onSurfaceVariant,
              height: 14,
              spacing: 0.44,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            children: [
              Text(
                value,
                style: AppText.jakarta(24, height: 32, spacing: -0.6),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit!,
                    style: AppText.jakarta(
                      11,
                      color: AppColors.secondary,
                      spacing: 0.44,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(note, style: AppText.inter(10, height: 16)),
          const Spacer(),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress ?? 0,
              minHeight: 6,
              backgroundColor: AppColors.containerHigh,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({required this.device});

  final FloraDevice? device;

  @override
  Widget build(BuildContext context) {
    final b = device?.battery;
    final v = device?.batteryVolt;
    final String? pill;
    if (b == null) {
      pill = null;
    } else if (v != null) {
      pill = '${v.toStringAsFixed(1)}V • ${device!.batteryCondition}';
    } else {
      pill = device!.batteryCondition;
    }
    return _TelemetryCard(
      icon: Icons.battery_charging_full,
      pill: pill,
      label: 'Daya Aki Mandiri',
      value: b == null ? '—' : '$b%',
      note: b == null ? 'Sensor aki belum terpasang' : 'Dari sensor alat',
      progress: b == null ? null : b / 100,
      barColor: b != null && b < 30 ? _danger : AppColors.primarySoft,
    );
  }
}

class _TankCard extends StatelessWidget {
  const _TankCard({required this.device});

  final FloraDevice? device;

  static String _l(double v) => v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final d = device;
    var pct = d?.tankPercent;
    final liters = d?.tankLiters;
    final cap = d?.tankCapacity;
    if (pct == null && liters != null && cap != null && cap > 0) {
      pct = (liters / cap * 100).round();
    }
    final volume = liters != null && cap != null
        ? '${_l(liters)}L / ${_l(cap)}L'
        : null;
    return _TelemetryCard(
      icon: Icons.water_drop_outlined,
      pill: volume,
      label: 'Kapasitas Tangki Air',
      value: pct == null ? '—' : '$pct%',
      unit: pct == null
          ? null
          : pct >= 70
          ? 'Penuh'
          : pct >= 30
          ? 'Cukup'
          : 'Hampir habis',
      note: pct == null ? 'Sensor tangki belum terpasang' : 'Dari sensor alat',
      progress: pct == null ? null : pct / 100,
      barColor: pct != null && pct < 30 ? _danger : AppColors.primary,
    );
  }
}

// ---------------------------------------------------------------------------
// Rak & baris kran

class _RackCard extends StatelessWidget {
  const _RackCard({
    required this.zones,
    required this.device,
    required this.lastWateredAt,
    required this.onToggle,
    required this.onResetup,
  });

  final List<PlantZone> zones;
  final FloraDevice? device;
  final DateTime? lastWateredAt;
  final ValueChanged<PlantZone> onToggle;
  final VoidCallback onResetup;

  @override
  Widget build(BuildContext context) {
    final online = device?.isFresh ?? false;
    final pumpOn = device?.pumpOn ?? false;
    final active = zones.where((z) => z.enabled).length;
    final flow = device?.flow;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _bigShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.containerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shelves,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rak 1',
                        style: AppText.jakarta(
                          18,
                          height: 22.5,
                          spacing: -0.18,
                        ),
                      ),
                      Text(
                        '$active Jalur Irigasi Aktif',
                        style: AppText.inter(12, height: 18, spacing: 0.12),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: online && active > 0 ? 'Aktif' : 'Nonaktif',
                  ok: online && active > 0,
                ),
                PopupMenuButton<int>(
                  tooltip: 'Opsi rak',
                  icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
                  onSelected: (_) => onResetup(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 0,
                      child: Text('Ulangi setup alat & jalur'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: zones.isEmpty
                ? Text(
                    'Belum ada jalur. Atur lewat menu ⋮ di atas.',
                    style: AppText.inter(12, height: 18),
                  )
                : Column(
                    children: [
                      for (final (i, z) in zones.indexed) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _ZoneRow(
                          index: i + 1,
                          zone: z,
                          online: online,
                          pumpOn: pumpOn,
                          lastWateredAt: lastWateredAt,
                          onToggle: () => onToggle(z),
                        ),
                      ],
                    ],
                  ),
          ),
          Container(
            color: AppColors.containerHigh,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 14,
                  color: pumpOn ? Colors.lightBlue : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    !online
                        ? 'Kran Solenoid: tidak diketahui'
                        : 'Kran Solenoid: ${pumpOn ? 'Terbuka' : 'Tertutup'}',
                    style: AppText.jakarta(
                      11,
                      weight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      spacing: 0.44,
                    ),
                  ),
                ),
                const Icon(
                  Icons.speed,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  flow == null
                      ? 'Aliran: tanpa sensor'
                      : 'Aliran Air: ${flow.toStringAsFixed(1)} L/mnt',
                  style: AppText.jakarta(
                    11,
                    color: AppColors.onSurfaceVariant,
                    spacing: 0.44,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.index,
    required this.zone,
    required this.online,
    required this.pumpOn,
    required this.lastWateredAt,
    required this.onToggle,
  });

  final int index;
  final PlantZone zone;
  final bool online;
  final bool pumpOn;
  final DateTime? lastWateredAt;
  final VoidCallback onToggle;

  static String _lalu(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inHours < 1) return '${d.inMinutes} mnt lalu';
    if (d.inDays < 1) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final String status;
    final Color statusColor;
    if (!zone.enabled) {
      status = 'Nonaktif';
      statusColor = AppColors.onSurfaceVariant;
    } else if (!online) {
      status = 'Alat offline';
      statusColor = _danger;
    } else if (pumpOn) {
      status = 'Sedang menyiram';
      statusColor = Colors.lightBlue.shade700;
    } else {
      status = 'Siap / Standby';
      statusColor = AppColors.secondaryText;
    }
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: zone.enabled ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.container,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_damage_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Baris $index (Kran $index)',
                    overflow: TextOverflow.ellipsis,
                    style: AppText.jakarta(16, height: 22, spacing: -0.08),
                  ),
                ),
                Switch(
                  value: zone.enabled,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primarySoft,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              decoration: BoxDecoration(
                color: const Color(0x99FFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Info(
                      label: 'Durasi Siram',
                      value: '${zone.durationSec} dtk',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Info(
                      label: lastWateredAt != null && !pumpOn
                          ? 'Terakhir Siram'
                          : 'Status Jalur',
                      value:
                          lastWateredAt != null &&
                              !pumpOn &&
                              zone.enabled &&
                              online
                          ? _lalu(lastWateredAt!)
                          : status,
                      color:
                          lastWateredAt != null &&
                              !pumpOn &&
                              zone.enabled &&
                              online
                          ? AppColors.onSurface
                          : statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
    this.color = AppColors.onSurface,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.jakarta(
            11,
            weight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            height: 14,
            spacing: 0.44,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.jakarta(12, color: color, height: 16, spacing: 0.24),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Siram manual: satu tombol power besar ala aplikasi smart plug (Bardi).

class _ManualWatering extends StatefulWidget {
  const _ManualWatering({required this.mqtt, required this.activeZones});

  final MqttService mqtt;
  final int activeZones;

  @override
  State<_ManualWatering> createState() => _ManualWateringState();
}

class _ManualWateringState extends State<_ManualWatering>
    with SingleTickerProviderStateMixin {
  /// Pilihan timer mati otomatis (detik). 0 = tanpa timer.
  static const _timers = [0, 10, 30, 60];
  int _timer = 0;

  /// Perintah yang menunggu konfirmasi alat (true = nyala, false = mati).
  bool? _pending;
  Timer? _replyTimeout;

  /// Sisa detik sebelum kran ditutup otomatis; null = timer tidak jalan.
  int? _sisa;
  Timer? _countdown;

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    widget.mqtt.addListener(_onMqtt);
    if (_on) _glow.repeat();
  }

  @override
  void dispose() {
    widget.mqtt.removeListener(_onMqtt);
    _replyTimeout?.cancel();
    _countdown?.cancel();
    _glow.dispose();
    super.dispose();
  }

  bool get _on => widget.mqtt.selected?.pumpOn ?? false;

  void _onMqtt() {
    if (!mounted) return;
    // Alat melapor status sesuai perintah -> terkonfirmasi.
    if (_pending != null && _on == _pending) {
      _pending = null;
      _replyTimeout?.cancel();
    }
    // Kran ditutup dari tempat lain: hentikan hitung mundur.
    if (!_on && _pending == null) _stopCountdown();
    if (_on && !_glow.isAnimating) _glow.repeat();
    if (!_on && _glow.isAnimating) _glow.stop();
    setState(() {});
  }

  void _send(bool target) {
    if (!widget.mqtt.kirimPerintah(target)) {
      showSnack(context, 'Belum terhubung ke server. Perintah tidak terkirim.');
      return;
    }
    setState(() => _pending = target);
    _replyTimeout?.cancel();
    _replyTimeout = Timer(const Duration(seconds: 5), () {
      if (!mounted || _pending == null) return;
      setState(() => _pending = null);
      showSnack(context, 'Alat tidak merespons. Cek kotak alat.');
    });
  }

  void _toggle() {
    final target = !_on;
    _send(target);
    if (target && _timer > 0) {
      _startCountdown(_timer);
    } else if (!target) {
      _stopCountdown();
    }
  }

  void _startCountdown(int detik) {
    _countdown?.cancel();
    _sisa = detik;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      final next = (_sisa ?? 0) - 1;
      if (next <= 0) {
        t.cancel();
        _sisa = null;
        _send(false);
      } else {
        setState(() => _sisa = next);
      }
    });
  }

  void _stopCountdown() {
    _countdown?.cancel();
    _sisa = null;
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.mqtt.selected;
    final online = widget.mqtt.isConnected && (device?.isFresh ?? false);
    final on = _on;
    final waiting = _pending != null;

    final String status;
    final String sub;
    if (!online) {
      status = 'Alat Offline';
      sub = 'Pastikan kotak alat menyala';
    } else if (waiting) {
      status = _pending! ? 'Membuka kran...' : 'Menutup kran...';
      sub = 'Menunggu konfirmasi alat';
    } else if (on) {
      status = 'Kran Terbuka';
      sub = _sisa != null
          ? 'Mati otomatis dalam $_sisa dtk'
          : 'Ketuk untuk menutup';
    } else {
      status = 'Kran Tertutup';
      sub = 'Ketuk untuk menyiram ${widget.activeZones} jalur aktif';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142D5A27),
            offset: Offset(0, 12),
            blurRadius: 32,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x0819231A),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.shower_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Siram Manual',
                  style: AppText.jakarta(16, height: 22, spacing: -0.08),
                ),
              ),
              Text(
                '${widget.activeZones} Jalur Aktif',
                style: AppText.jakarta(
                  11,
                  weight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  spacing: 0.44,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animasi tombol di-repaint sendiri, tidak ikut mengecat seluruh kartu.
          RepaintBoundary(
            child: _PowerButton(
              on: on,
              enabled: online && !waiting,
              waiting: waiting,
              glow: _glow,
              onTap: _toggle,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: AppText.jakarta(
              20,
              weight: FontWeight.w700,
              color: !online
                  ? _danger
                  : on
                  ? AppColors.primary
                  : AppColors.onSurface,
              spacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: AppText.inter(12, height: 18),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Timer mati otomatis',
                style: AppText.jakarta(
                  11,
                  weight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  spacing: 0.44,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (i, d) in _timers.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: _timer == d
                        ? AppColors.primary
                        : AppColors.containerHigh,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      // Timer dikunci selama kran terbuka.
                      onTap: on || waiting
                          ? null
                          : () => setState(() => _timer = d),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          d == 0 ? 'Tanpa' : '$d dtk',
                          textAlign: TextAlign.center,
                          style: AppText.jakarta(
                            12,
                            color: _timer == d
                                ? Colors.white
                                : AppColors.onSurface,
                            height: 16,
                            spacing: 0.24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol power bulat besar. Hijau + gelombang saat kran terbuka.
class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.on,
    required this.enabled,
    required this.waiting,
    required this.glow,
    required this.onTap,
  });

  final bool on;
  final bool enabled;
  final bool waiting;
  final Animation<double> glow;
  final VoidCallback onTap;

  static const _size = 132.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size + 40,
      height: _size + 40,
      child: AnimatedBuilder(
        animation: glow,
        builder: (context, _) {
          final t = on ? glow.value : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (on)
                Transform.scale(
                  scale: 1 + 0.28 * t,
                  child: Opacity(
                    opacity: (1 - t) * 0.45,
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? AppColors.primarySoft : AppColors.containerHigh,
                  border: Border.all(
                    color: on ? AppColors.accent : Colors.white,
                    width: 6,
                  ),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: AppColors.primarySoft.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : AppShadows.card,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: enabled ? onTap : null,
                    child: Center(
                      child: waiting
                          ? SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: on ? Colors.white : AppColors.primary,
                              ),
                            )
                          : Icon(
                              Icons.power_settings_new,
                              size: 56,
                              color: !enabled
                                  ? AppColors.onSurfaceVariant.withValues(
                                      alpha: 0.4,
                                    )
                                  : on
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
