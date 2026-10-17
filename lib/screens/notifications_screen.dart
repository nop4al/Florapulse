import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Daftar notifikasi dari kejadian asli alat & server.
/// Notifikasi belum dibaca disorot, lalu ditandai dibaca saat halaman ditutup.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _mqtt = MqttService.instance;

  @override
  void dispose() {
    // Ditandai setelah halaman ditutup supaya sorotan "baru" sempat terlihat.
    if (_mqtt.unreadCount > 0) _mqtt.markAllRead();
    super.dispose();
  }

  static String _waktu(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inHours < 1) return '${d.inMinutes} mnt lalu';
    if (d.inDays < 1) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  static (IconData, Color, Color) _style(NotifKind k) => switch (k) {
        NotifKind.success => (Icons.check_circle_outline, AppColors.primary, AppColors.accent),
        NotifKind.info => (Icons.water_drop_outlined, Color(0xFF0277BD), Color(0xFFD7EEFB)),
        NotifKind.warning => (Icons.warning_amber_rounded, Color(0xFF8A5A00), Color(0xFFFFE9B8)),
        NotifKind.danger => (Icons.error_outline, Color(0xFFB3261E), Color(0xFFFFDAD6)),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Notifikasi', style: AppText.jakarta(18, spacing: -0.2)),
        actions: [
          ListenableBuilder(
            listenable: _mqtt,
            builder: (context, _) => _mqtt.notifications.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: _mqtt.clearNotifications,
                    child: Text('Hapus semua',
                        style: AppText.jakarta(13, color: AppColors.secondary)),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _mqtt,
        builder: (context, _) {
          final items = _mqtt.notifications;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const IconCircle(
                    icon: Icons.notifications_none,
                    size: 64,
                    iconSize: 30,
                    color: AppColors.container,
                  ),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi', style: AppText.jakarta(16)),
                  const SizedBox(height: 4),
                  Text(
                    'Kabar alat online/offline, kran dibuka/ditutup, dan baterai lemah akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: AppText.inter(13, height: 20),
                  ),
                ]),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final n = items[i];
              final (icon, fg, bg) = _style(n.kind);
              return Container(
                color: n.read ? null : const Color(0x80EBF7E8),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconCircle(icon: icon, color: bg, iconColor: fg, size: 40, iconSize: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(n.title,
                                  style: AppText.jakarta(14,
                                      weight: n.read ? FontWeight.w600 : FontWeight.w700,
                                      height: 20)),
                            ),
                            Text(_waktu(n.time),
                                style: AppText.inter(11, color: AppColors.secondary)),
                          ]),
                          const SizedBox(height: 2),
                          Text(n.body, style: AppText.inter(12, height: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
