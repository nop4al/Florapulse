import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:florapulse/screens/splash_screen.dart';
import 'package:florapulse/screens/welcome_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('App dibuka dengan layar loading', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen(connectServer: false)));
    await tester.pump();

    expect(find.text('FloraPulse'), findsOneWidget);
    expect(find.text('Menyiapkan tampilan...'), findsOneWidget);

    // Lepas splash dan habiskan timer minimal tampilnya.
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('Layar sambutan tampil', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.pump();

    expect(find.text('Mulai Pasang Alat Sekarang'), findsOneWidget);
    expect(find.text('Yang Perlu Disiapkan'), findsOneWidget);
  });
}
