import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'test_finish_screen.dart';

class PlantZone {
  PlantZone({
    required this.name,
    required this.location,
    required this.durationSec,
    this.iconColor = AppColors.accent,
    this.enabled = true,
  });

  String name;
  String location;
  int durationSec;
  Color iconColor;
  bool enabled;
}

/// Figma: "FloraPulse - Atur Jalur Tanaman"
class PlantZonesScreen extends StatefulWidget {
  const PlantZonesScreen({super.key});

  @override
  State<PlantZonesScreen> createState() => _PlantZonesScreenState();
}

class _PlantZonesScreenState extends State<PlantZonesScreen> {
  static const _presets = [15, 30, 45, 60];
  static const _urutan = ['Pertama', 'Kedua', 'Ketiga', 'Keempat', 'Kelima', 'Keenam'];

  final _zones = [
    PlantZone(name: 'Baris Pertama (Kran 1)', location: 'Bedengan Depan', durationSec: 30),
    PlantZone(
        name: 'Baris Kedua (Kran 2)',
        location: 'Rak Bibit & Semai',
        durationSec: 15,
        iconColor: AppColors.accentAlt),
    PlantZone(
        name: 'Baris Ketiga (Kran 3)',
        location: 'Hortikultura & Buah',
        durationSec: 45,
        iconColor: AppColors.accentLight),
  ];

  /// Jumlah kran sesuai laporan alat yang dipilih di langkah 1.
  final int _maxJalur = MqttService.instance.selected?.valves ?? 1;

  @override
  void initState() {
    super.initState();
    if (_zones.length > _maxJalur) _zones.removeRange(_maxJalur, _zones.length);
  }

  void _tambahJalur() {
    if (_zones.length >= _maxJalur) {
      showSnack(context, 'Kotak alat ini hanya punya $_maxJalur jalur siram.');
      return;
    }
    final n = _zones.length + 1;
    final urutan = n <= _urutan.length ? _urutan[n - 1] : '$n';
    setState(() {
      _zones.add(PlantZone(
        name: 'Baris $urutan (Kran $n)',
        location: 'Jalur Baru',
        durationSec: 30,
      ));
    });
  }

  Future<void> _kustom(PlantZone zone) async {
    final controller = TextEditingController(text: '${zone.durationSec}');
    final hasil = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Durasi Kustom', style: AppText.jakarta(18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'detik', hintText: 'Contoh: 20'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (hasil != null && hasil > 0) setState(() => zone.durationSec = hasil);
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: StepProgress(
            step: 2,
            label: 'Langkah 2 dari 3 • Atur Waktu Siram',
            maxBarWidth: 120,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x99BDECB7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.yard_outlined, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text('Pengaturan Irigasi Cerdas',
                  style: AppText.jakarta(11,
                      weight: FontWeight.w700, color: AppColors.secondaryText, spacing: 0.44)),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        Text('Tanaman Apa Saja yang Ditanam?',
            style: AppText.jakarta(26, height: 34, spacing: -0.52)),
        const SizedBox(height: 4),
        Text(
          'Beri tanda agar jadwal siram otomatis menyesuaikan kebutuhan air tanaman Anda secara optimal.',
          style: AppText.inter(14, height: 22),
        ),
        const SizedBox(height: 20),
        for (final zone in _zones) ...[
          _ZoneCard(
            zone: zone,
            presets: _presets,
            onToggle: () => setState(() => zone.enabled = !zone.enabled),
            onPick: (d) => setState(() => zone.durationSec = d),
            onCustom: () => _kustom(zone),
          ),
          const SizedBox(height: 16),
        ],
        Material(
          color: AppColors.container,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _tambahJalur,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('+ Tambah Baris / Jalur Baru',
                      style: AppText.jakarta(16,
                          color: AppColors.primary, height: 22, spacing: -0.08)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const TipBox(
          color: Color(0x99E0EBDD),
          text: TextSpan(
            text: 'Jangan khawatir, nama dan jadwal ini bisa Anda ubah kapan saja '
                'di menu Beranda sesuai cuaca dan musim tanam.',
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Lanjut ke Uji Coba & Selesai',
          trailing: Icons.arrow_forward,
          onPressed: () {
            final aktif = _zones.where((z) => z.enabled).toList();
            if (aktif.isEmpty) {
              showSnack(context, 'Pilih minimal satu jalur tanaman.');
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TestFinishScreen(zones: aktif)),
            );
          },
        ),
      ],
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.presets,
    required this.onToggle,
    required this.onPick,
    required this.onCustom,
  });

  final PlantZone zone;
  final List<int> presets;
  final VoidCallback onToggle;
  final ValueChanged<int> onPick;
  final VoidCallback onCustom;

  static String _label(int s) => s % 60 == 0 ? '${s ~/ 60} Menit' : '$s Detik';

  @override
  Widget build(BuildContext context) {
    final isCustom = !presets.contains(zone.durationSec);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: zone.enabled ? 1 : 0.6,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              IconCircle(icon: Icons.water_drop, color: zone.iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(zone.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.jakarta(16, height: 22, spacing: -0.08)),
                      ),
                      if (zone.enabled) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                      ],
                    ]),
                    Text(zone.location, style: AppText.inter(12, height: 18, spacing: 0.12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: zone.enabled ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: zone.enabled
                          ? null
                          : Border.all(color: AppColors.onSurfaceVariant, width: 1.5),
                    ),
                    child: zone.enabled
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.container,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Durasi Siram Sekali Jalan',
                          style: AppText.jakarta(11, color: AppColors.primary, spacing: 0.44)),
                    ),
                    Text('Aktif: ${_label(zone.durationSec)}',
                        style: AppText.jakarta(11, color: AppColors.secondary, spacing: 0.44)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in presets)
                        _Chip(
                          label: _label(p),
                          selected: zone.durationSec == p,
                          onTap: () => onPick(p),
                        ),
                      _Chip(
                        label: isCustom ? 'Kustom (${zone.durationSec}d)' : 'Kustom',
                        icon: Icons.tune,
                        selected: isCustom,
                        onTap: onCustom,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Icons.info_outline,
                            size: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Kran menyala selama ${_label(zone.durationSec).toLowerCase()} setiap jadwal siram.',
                          style: AppText.inter(12, height: 18, spacing: 0.12),
                        ),
                      ),
                    ],
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : (icon != null ? AppColors.secondary : AppColors.onSurfaceVariant);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.containerHigh,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? AppShadows.soft : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 2),
          ],
          Text(label,
              style: AppText.jakarta(11,
                  weight: selected ? FontWeight.w600 : FontWeight.w700,
                  color: fg,
                  spacing: 0.44,
                  height: 14)),
        ]),
      ),
    );
  }
}
