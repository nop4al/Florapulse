import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'plant_zones_screen.dart';

/// Beranda Kebun: kontrol pompa via MQTT (logika dari versi awal app),
/// dengan gaya visual desain FloraPulse.
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

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: _mqtt,
        builder: (context, _) {
          final connected = _mqtt.isConnected;
          final on = _mqtt.isPompaOn;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16 + pad.top, 20, 24 + pad.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Beranda Kebun',
                        style: AppText.jakarta(26, weight: FontWeight.w700, spacing: -0.65)),
                  ),
                  _statusPill(connected),
                ]),
                const SizedBox(height: 4),
                Text(
                    _mqtt.selected == null
                        ? 'Belum ada kotak alat dipilih'
                        : '${_mqtt.selected!.id} • ${_mqtt.selected!.name}',
                    style: AppText.inter(14, height: 22)),
                const SizedBox(height: 24),
                AppCard(
                  shadow: AppShadows.card,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(children: [
                    GestureDetector(
                      onTap: connected ? () => _mqtt.kirimPerintah(!on) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? AppColors.primary : AppColors.containerHighest,
                          boxShadow: AppShadows.card,
                          border: Border.all(
                            color: on ? AppColors.accent : AppColors.white,
                            width: 8,
                          ),
                        ),
                        child: Icon(
                          Icons.power_settings_new,
                          size: 72,
                          color: on ? Colors.white : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(on ? 'POMPA MENYALA' : 'POMPA MATI',
                        style: AppText.jakarta(22,
                            weight: FontWeight.w700,
                            color: on ? AppColors.primary : AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      connected
                          ? 'Ketuk tombol untuk ${on ? 'mematikan' : 'menyalakan'} pompa air.'
                          : 'Menunggu koneksi ke server...',
                      textAlign: TextAlign.center,
                      style: AppText.inter(13, height: 20),
                    ),
                  ]),
                ),
                if (widget.zones.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Jalur Tanaman',
                      style: AppText.jakarta(18, spacing: -0.18)),
                  const SizedBox(height: 8),
                  for (final z in widget.zones) ...[
                    AppCard(
                      radius: 8,
                      child: Row(children: [
                        IconCircle(icon: Icons.water_drop, color: z.iconColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(z.name, style: AppText.jakarta(16, height: 22)),
                              Text(z.location,
                                  style: AppText.inter(12, height: 18, spacing: 0.12)),
                            ],
                          ),
                        ),
                        Text(
                          z.durationSec % 60 == 0
                              ? '${z.durationSec ~/ 60} Menit'
                              : '${z.durationSec} Detik',
                          style: AppText.jakarta(12, color: AppColors.secondary),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                if (!connected && !_mqtt.isConnecting) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Hubungkan Ulang',
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

  Widget _statusPill(bool connected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: connected ? AppColors.containerHighest : const Color(0xFFFBE4E1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(connected ? Icons.cloud_done : Icons.cloud_off,
            size: 14, color: connected ? AppColors.primary : const Color(0xFFB3261E)),
        const SizedBox(width: 6),
        Text(
          _mqtt.isConnecting ? 'Menghubungkan' : (connected ? 'Terhubung' : 'Terputus'),
          style: AppText.jakarta(11,
              color: connected ? AppColors.primary : const Color(0xFFB3261E), spacing: 0.3),
        ),
      ]),
    );
  }
}
