import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:florapulse/main.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Layar sambutan tampil', (WidgetTester tester) async {
    await tester.pumpWidget(const FloraPulseApp());
    await tester.pump();

    expect(find.text('Mulai Pasang Alat Sekarang'), findsOneWidget);
    expect(find.text('Yang Perlu Disiapkan'), findsOneWidget);
  });
}
