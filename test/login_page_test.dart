import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umkm_batik/pages/login_page.dart'; // ganti sesuai struktur proyekmu

void main() {
  testWidgets('LoginPage renders and accepts input', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(),
      ),
    );

    // Cek apakah teks "Selamat Datang" ada
    expect(find.text('Selamat Datang'), findsOneWidget);

    // Cari TextField dan masukkan teks
    final emailField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);

    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, '123456');

    // Tekan tombol login
    final loginButton = find.widgetWithText(ElevatedButton, 'Masuk');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);

    // pump agar animasi/jalur async bisa dijalankan
    await tester.pump();

  });
}
