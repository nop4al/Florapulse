import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Font sudah ada di assets/google_fonts, jangan download dari internet.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const FloraPulseApp());
}

class FloraPulseApp extends StatelessWidget {
  const FloraPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florapulse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
