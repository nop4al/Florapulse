import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Header blur "Panduan Setup" dengan tombol kembali.
class SetupHeader extends StatelessWidget implements PreferredSizeWidget {
  const SetupHeader({super.key, this.title = 'Panduan Setup'});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64 + top,
          padding: EdgeInsets.only(top: top, left: 12, right: 20),
          decoration: const BoxDecoration(
            color: Color(0xCCF1FDEE),
            boxShadow: [
              BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.onSurface),
                  tooltip: 'Kembali',
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.jakarta(16, height: 22, spacing: -0.08),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar progres 3 langkah + label.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.label, this.maxBarWidth});

  final int step;
  final String label;
  final double? maxBarWidth;

  @override
  Widget build(BuildContext context) {
    final bars = Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < step ? AppColors.primarySoft : AppColors.track,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
    return Row(
      children: [
        Expanded(
          child: maxBarWidth == null
              ? bars
              : Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxBarWidth!),
                    child: bars,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Text(
          label.toUpperCase(),
          style: AppText.inter(11,
              weight: FontWeight.w600, color: AppColors.primarySoft, spacing: 0.55, height: 22),
        ),
      ],
    );
  }
}

/// Tombol utama bulat penuh.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.height = 48,
    this.color = AppColors.primary,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leading;
  final IconData? trailing;
  final double height;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: onPressed == null ? null : AppShadows.card,
      ),
      child: Material(
        color: onPressed == null ? color.withValues(alpha: 0.5) : color,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  Icon(leading, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: AppText.jakarta(fontSize,
                        color: Colors.white, height: 20, spacing: fontSize * 0.01)),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailing, color: Colors.white, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu putih standar.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
    this.shadow = AppShadows.soft,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// Lingkaran ikon berwarna.
class IconCircle extends StatelessWidget {
  const IconCircle({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
    this.color = AppColors.accent,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

/// Lingkaran kabur dekoratif.
class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key, required this.size, required this.color, this.blur = 20});

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Kotak tips hijau muda.
class TipBox extends StatelessWidget {
  const TipBox({
    super.key,
    required this.text,
    this.icon = Icons.tips_and_updates_outlined,
    this.color = AppColors.container,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
  });

  final InlineSpan text;
  final double radius;
  final IconData icon;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              text,
              style: AppText.inter(12, height: 18, spacing: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layout layar setup: header blur di atas konten yang bisa digulir.
class SetupScaffold extends StatelessWidget {
  const SetupScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SetupHeader(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 64 + MediaQuery.paddingOf(context).top, 20, 40 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
    ));
}
