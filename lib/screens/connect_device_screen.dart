import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'plant_zones_screen.dart';

/// Figma: "FloraPulse - Hubungkan Kotak Alat"
///
/// Kartu alat hanya muncul kalau alat benar-benar menjawab ping lewat MQTT.
class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final _mqtt = MqttService.instance;

  @override
  void initState() {
    super.initState();
    _mqtt.scan();
  }

  @override
  void dispose() {
    _mqtt.stopScan();
    super.dispose();
  }

  void _hubungkan() {
    final device = _mqtt.selected;
    if (device == null) return;
    // Alat bisa saja mati setelah ditemukan: cek lagi sebelum lanjut.
    if (!device.isFresh) {
      showSnack(context, '${device.name} tidak merespons lagi. Mencari ulang...');
      _mqtt.scan();
      return;
    }
    _mqtt.stopScan();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlantZonesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _mqtt,
      builder: (context, _) {
        final devices = _mqtt.devices;
        final selected = _mqtt.selected;
        return SetupScaffold(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: StepProgress(step: 1, label: 'Langkah 1 dari 3 • Hubungkan Alat'),
            ),
            const SizedBox(height: 24),
            _RadarCard(
              state: _mqtt.scanState,
              found: devices.length,
              onRetry: _mqtt.scan,
            ),
            if (devices.isNotEmpty) ...[
              const SizedBox(height: 24),
              _DeviceList(
                devices: devices,
                selectedId: _mqtt.selectedId,
                onSelect: _mqtt.select,
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: selected == null ? 'Belum Ada Alat Dipilih' : 'Hubungkan ke Kotak Ini',
              leading: Icons.hub_outlined,
              height: 56,
              onPressed: selected == null ? null : _hubungkan,
            ),
            const SizedBox(height: 16),
            TipBox(
              padding: const EdgeInsets.all(8),
              radius: 8,
              text: TextSpan(children: [
                const TextSpan(text: 'Kotak alat belum terhubung? '),
                TextSpan(
                  text: 'Pastikan mesin FloraPulse menyala',
                  style: AppText.inter(12, weight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const TextSpan(
                    text: ' dan dalam jangkauan sinyal agar otomatis tersambung online.'),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class _RadarCard extends StatefulWidget {
  const _RadarCard({required this.state, required this.found, required this.onRetry});

  final ScanState state;
  final int found;
  final VoidCallback onRetry;

  @override
  State<_RadarCard> createState() => _RadarCardState();
}

class _RadarCardState extends State<_RadarCard> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  bool get _busy =>
      widget.state == ScanState.connecting || widget.state == ScanState.scanning;

  @override
  void didUpdateWidget(covariant _RadarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_busy && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!_busy && _anim.isAnimating) {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  (String, String, IconData) get _content {
    switch (widget.state) {
      case ScanState.idle:
      case ScanState.connecting:
        return (
          'Menghubungkan ke Server FloraPulse...',
          'Sebentar, sedang menyiapkan koneksi internet ke kebun.',
          Icons.cloud_sync_outlined,
        );
      case ScanState.serverError:
        return (
          'Tidak Bisa Terhubung ke Server',
          'Periksa data seluler atau WiFi HP Anda, lalu coba lagi.',
          Icons.cloud_off_outlined,
        );
      case ScanState.scanning:
        return widget.found > 0
            ? (
                'Kotak Mesin Ditemukan!',
                'Pilih kotak di bawah. Pencarian masih berjalan untuk alat lain.',
                Icons.check_circle_outline,
              )
            : (
                'Mencari Kotak Mesin FloraPulse...',
                'Pastikan lampu indikator hijau di kotak alat Anda menyala berkedip santai.',
                Icons.settings_input_antenna,
              );
      case ScanState.done:
        return widget.found > 0
            ? (
                'Kotak Mesin Ditemukan!',
                'Pilih kotak di bawah lalu tekan Hubungkan.',
                Icons.check_circle_outline,
              )
            : (
                'Alat Belum Ditemukan',
                'Pastikan kotak alat menyala dan tersambung internet, lalu cari lagi.',
                Icons.search_off,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, desc, icon) = _content;
    return Container(
      height: 360,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -48,
            top: -48,
            child: GlowBlob(size: 160, color: Color(0x66BDECB7)),
          ),
          const Positioned(
            left: -40,
            bottom: -40,
            child: GlowBlob(size: 144, color: Color(0x4DBCF0AE)),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Animasi diisolasi supaya kartu lain tidak ikut dicat ulang.
                  RepaintBoundary(child: _pulse(icon)),
                  const SizedBox(height: 20),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: AppText.jakarta(20, height: 28, spacing: -0.2)),
                  const SizedBox(height: 4),
                  Text(desc, textAlign: TextAlign.center, style: AppText.inter(14, height: 22)),
                  const SizedBox(height: 16),
                  RepaintBoundary(child: _busy ? _scanPill() : _retryPill()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulse(IconData icon) {
    return SizedBox(
      width: 128,
      height: 128,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _busy ? _anim.value : 0.0;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.9 + 0.2 * t,
                child: Opacity(
                  opacity: 0.75 * (1 - t * 0.6),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Color(0x66C0EFBA), shape: BoxShape.circle),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration:
                    const BoxDecoration(color: Color(0x80BDECB7), shape: BoxShape.circle),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration:
                    const BoxDecoration(color: AppColors.container, shape: BoxShape.circle),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.card,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
              if (_busy)
                const Positioned(
                  right: 24,
                  top: -4,
                  child: _Dot(size: 14, color: AppColors.primary),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _scanPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.containerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, h) in const [8.0, 16.0, 12.0, 20.0, 8.0].indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              Container(
                width: 4,
                height: h * (0.6 + 0.4 * (((_anim.value * 5) + i) % 5 / 5)),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
            const SizedBox(width: 4),
            SizedBox(
              height: 20,
              child: Center(
                child: Text(
                    widget.state == ScanState.connecting
                        ? 'Menghubungkan server'
                        : 'Memindai alat via internet',
                    style: AppText.jakarta(11, color: AppColors.primary, spacing: 0.44)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _retryPill() {
    return Material(
      color: AppColors.containerHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.refresh, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('Cari Lagi',
                style: AppText.jakarta(11, color: AppColors.primary, spacing: 0.44)),
          ]),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.devices, required this.selectedId, required this.onSelect});

  final List<FloraDevice> devices;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.onSurface),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Alat Ditemukan',
                  style: AppText.jakarta(12, spacing: 0.24, height: 16)),
            ),
            Text('${devices.length} Perangkat Siap',
                style: AppText.jakarta(11, color: AppColors.secondary, spacing: 0.44)),
          ]),
        ),
        const SizedBox(height: 8),
        for (final d in devices) ...[
          _DeviceCard(
            device: d,
            selected: d.id == selectedId,
            onTap: () => onSelect(d.id),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.selected, required this.onTap});

  final FloraDevice device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
          border: Border.all(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.router_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(device.name,
                            style: AppText.jakarta(16, height: 22, spacing: -0.08)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(device.id,
                              style: AppText.jakarta(11,
                                  weight: FontWeight.w700,
                                  color: AppColors.secondaryText,
                                  spacing: 0.44)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.water_drop_outlined,
                          size: 13, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Kran siap kontrol: '),
                            TextSpan(
                              text: '${device.valves} Jalur Siram',
                              style: AppText.inter(12,
                                  weight: FontWeight.w600, color: AppColors.onSurface),
                            ),
                          ]),
                          style: AppText.inter(12, height: 18, spacing: 0.12),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.radio_button_checked, color: AppColors.primarySoft)
              else
                const Icon(Icons.radio_button_off, color: AppColors.onSurfaceVariant),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.container,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(device.signalLabel,
                        style: AppText.jakarta(11, color: AppColors.primary, spacing: 0.44)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.battery_charging_full,
                      size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text('Baterai/Aki: ${device.batteryLabel}',
                        style: AppText.jakarta(11,
                            weight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                            spacing: 0.44)),
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
