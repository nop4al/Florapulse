import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'connect_device_screen.dart';

/// Figma: "FloraPulse - Sambutan & Persiapan Alat"
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16 + pad.top, 20, 24 + pad.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandHeader(),
            const SizedBox(height: 24),
            const _HeroCard(),
            const SizedBox(height: 24),
            const _ChecklistSection(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.container,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const IconCircle(
                    icon: Icons.lightbulb_outline,
                    size: 32,
                    iconSize: 18,
                    color: AppColors.containerDim,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Tips Petani:',
                            style: AppText.inter(12, weight: FontWeight.w600),
                          ),
                          const TextSpan(
                            text: ' Lampu indikator hijau pada mesin akan berkedip pelan saat siap dihubungkan.',
                          ),
                        ],
                      ),
                      style: AppText.inter(12, height: 16.5, spacing: 0.12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Mulai Pasang Alat Sekarang',
              color: AppColors.primarySoft,
              trailing: Icons.arrow_forward,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectDeviceScreen()),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  showSnack(context, 'Menghubungi penyuluh lewat WhatsApp...'),
              icon: const Icon(
                Icons.support_agent,
                size: 16,
                color: AppColors.secondary,
              ),
              label: Text(
                'Butuh Bantuan Penyuluh Kebun? Hubungi WhatsApp',
                style: AppText.jakarta(
                  12,
                  color: AppColors.secondary,
                  spacing: 0.24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo + nama app di atas layar sambutan.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FloraLogo(size: 44),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FloraPulse',
              style: AppText.jakarta(
                20,
                weight: FontWeight.w700,
                color: AppColors.primary,
                height: 24,
                spacing: -0.4,
              ),
            ),
            Text(
              'Kebun Pintar, Siram Otomatis',
              style: AppText.inter(
                11,
                color: AppColors.secondary,
                height: 14,
                spacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 224,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/hero_welcome.jpg',
                  fit: BoxFit.cover,
                  cacheWidth: 1024,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xCC293329),
                        Color(0x33293329),
                        Color(0x00293329),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      // Flexible: di layar sempit pill mengecil, tidak tumpah keluar kartu.
                      Flexible(
                        child: _GlassPill(
                          icon: Icons.eco,
                          text: 'Hemat Air hingga 40%',
                          color: AppColors.accentLight,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: _GlassPill(
                          icon: Icons.wifi_tethering,
                          text: 'Otomatis Terhubung',
                          color: AppColors.background,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang di FloraPulse Kebun Pintar!',
                  style: AppText.jakarta(
                    26,
                    weight: FontWeight.w700,
                    height: 34,
                    spacing: -0.65,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Mari siapkan alat penyiram otomatis Anda dalam 3 langkah mudah. '
                  'Tidak perlu repot utak-atik kabel rumit atau jaringan susah.',
                  style: AppText.inter(14, height: 22.75),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.fontSize,
  });

  final IconData icon;
  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // Latar gelap pekat, tanpa blur (blur berat di HP kelas bawah).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xB3293329),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.jakarta(fontSize, color: color, spacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection();

  static const _items = [
    (
      Icons.battery_charging_full,
      '1. Daya Baterai / Aki',
      'Kotak mesin FloraPulse ditenagai baterai/aki terisi penuh dan tombol daya sudah dinyalakan.',
      Icons.battery_charging_full_outlined,
    ),
    (
      Icons.water_drop,
      '2. Sambungan Air',
      'Selang pipa air sudah tersambung rapat ke kran utama kebun atau pipa tandon penampungan air.',
      Icons.check_circle_outline,
    ),
    (
      Icons.near_me,
      '3. Jarak HP Dekat',
      'Pastikan Anda berdiri dekat dengan kotak mesin (dalam jarak aman 5 meter) untuk deteksi Bluetooth.',
      Icons.check_circle_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.checklist, size: 20, color: AppColors.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yang Perlu Disiapkan',
                  style: AppText.jakarta(
                    18,
                    weight: FontWeight.w600,
                    spacing: -0.18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.containerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Langkah 1 dari 3',
                  style: AppText.jakarta(
                    12,
                    color: AppColors.onSurfaceVariant,
                    spacing: 0.24,
                    height: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final (icon, title, desc, trailing) in _items) ...[
          AppCard(
            radius: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: IconCircle(icon: icon),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppText.jakarta(
                                16,
                                height: 22,
                                spacing: -0.08,
                              ),
                            ),
                          ),
                          Icon(trailing, size: 18, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: AppText.inter(12, height: 18, spacing: 0.12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
