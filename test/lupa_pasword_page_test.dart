import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umkm_batik/pages/lupa_password.dart';

void main() {
  testWidgets('LupaPasswordPage renders email input and button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LupaPasswordPage(),
      ),
    );

    // Tombol
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Masukkan email anda'), findsOneWidget);
    
    // Cari tombol kirim
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Kirim Kode OTP'), findsOneWidget);

  });

  testWidgets('Submit with empty email shows snackbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LupaPasswordPage(),
      ),
    );

    // Tap tombol tanpa mengisi email
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // untuk menampilkan snackbar

    // Pastikan snackbar muncul
    expect(find.text('Silakan masukkan email Anda.'), findsOneWidget);
  });
}
