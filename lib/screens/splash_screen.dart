import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'welcome_screen.dart';

/// Layar loading saat app dibuka. Menyiapkan font, gambar, dan koneksi
/// server sambil menampilkan animasi, lalu pindah ke layar sambutan.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.connectServer = true});

  /// Matikan di widget test supaya tidak membuka koneksi jaringan asli.
  final bool connectServer;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  /// Splash tampil minimal selama ini supaya animasi sempat terlihat.
  static const _minDuration = Duration(milliseconds: 2200);

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  static const _steps = [
    'Menyiapkan tampilan...',
    'Memuat gambar kebun...',
    'Menghubungkan ke server...',
    'Siap!',
  ];
  int _step = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precacheImage butuh context, jadi mulai di sini (sekali saja).
    if (!_started) {
      _started = true;
      _boot();
    }
  }

  Future<void> _boot() async {
    final minWait = Future<void>.delayed(_minDuration);

    // 1. Font Plus Jakarta Sans & Inter.
    try {
      AppText.jakarta(14);
      AppText.inter(14);
      await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 4));
    } catch (_) {
      // Offline: pakai font bawaan, tidak masalah.
    }
    _next();

    // 2. Gambar di layar berikutnya, supaya tidak muncul telat.
    if (mounted) {
      await Future.wait([
        precacheImage(const AssetImage(FloraLogo.asset), context),
        precacheImage(const AssetImage('assets/images/hero_welcome.jpg'), context),
      ]);
    }
    _next();

    // 3. Koneksi server dibuka lebih awal. Gagal pun tetap lanjut:
    //    layar Hubungkan Alat akan mencoba lagi.
    if (widget.connectServer) {
      await MqttService.instance.connect().timeout(
            const Duration(seconds: 6),
            onTimeout: () => false,
          );
    }
    _next();

    await minWait;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, _, _) => const WelcomeScreen(),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
    ));
  }

  void _next() {
    if (mounted) setState(() => _step = math.min(_step + 1, _steps.length - 1));
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    final pop = CurvedAnimation(parent: _intro, curve: Curves.easeOutBack);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Cahaya lembut di sudut, seperti kartu di desain.
          Positioned(
            top: -80,
            right: -80,
            child: _Glow(size: 260, color: AppColors.primarySoft.withValues(alpha: 0.7)),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: _Glow(size: 300, color: AppColors.secondary.withValues(alpha: 0.45)),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: Tween(begin: 0.6, end: 1.0).animate(pop),
                  child: FadeTransition(opacity: fade, child: RepaintBoundary(child: _logo())),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(fade),
                    child: Column(children: [
                      Text('FloraPulse',
                          style: AppText.jakarta(34,
                              weight: FontWeight.w700, color: Colors.white, spacing: -0.8)),
                      const SizedBox(height: 6),
                      Text('Kebun Pintar, Siram Otomatis',
                          style: AppText.inter(14, color: AppColors.accentLight, spacing: 0.2)),
                    ]),
                  ),
                ),
                const Spacer(flex: 3),
                _progress(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Dua gelombang "pulse" bergantian.
              for (final offset in [0.0, 0.5])
                Builder(builder: (context) {
                  final t = (_pulse.value + offset) % 1.0;
                  return Transform.scale(
                    scale: 0.55 + 0.45 * t,
                    child: Opacity(
                      opacity: (1 - t) * 0.5,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  );
                }),
              const FloraLogo(size: 104, onDark: true, shadow: true),
            ],
          );
        },
      ),
    );
  }

  Widget _progress() {
    final value = (_step + 1) / _steps.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          // Teks lama hilang dulu, baru teks baru muncul (tidak tumpuk).
          switchInCurve: const Interval(0.5, 1),
          switchOutCurve: const Interval(0.5, 1),
          child: Text(
            _steps[_step],
            key: ValueKey(_step),
            style: AppText.inter(12, color: Colors.white.withValues(alpha: 0.75), spacing: 0.2),
          ),
        ),
      ]),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
