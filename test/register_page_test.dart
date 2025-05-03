import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umkm_batik/pages/register_page.dart';

void main() {
  testWidgets('RegisterPage menampilkan semua input field dan tombol', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SignupScreen())));

    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('No.hp'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });

  testWidgets('Validasi: semua field wajib diisi', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SignupScreen())));

    await tester.tap(find.text('Daftar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Semua kolom harus diisi!'), findsOneWidget);
  });

  testWidgets('Validasi: email tidak valid', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SignupScreen())));

    await tester.enterText(find.byType(TextField).at(0), 'Nama');
    await tester.enterText(find.byType(TextField).at(1), 'invalidemail');
    await tester.enterText(find.byType(TextField).at(2), '08123456789');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.enterText(find.byType(TextField).at(4), 'password123');

    await tester.tap(find.text('Daftar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Masukkan email yang valid!'), findsOneWidget);
  });

  testWidgets('Validasi: password < 6 karakter', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SignupScreen())));

    await tester.enterText(find.byType(TextField).at(0), 'Nama');
    await tester.enterText(find.byType(TextField).at(1), 'email@example.com');
    await tester.enterText(find.byType(TextField).at(2), '08123456789');
    await tester.enterText(find.byType(TextField).at(3), '123');
    await tester.enterText(find.byType(TextField).at(4), '123');

    await tester.tap(find.text('Daftar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Password harus minimal 6 karakter!'), findsOneWidget);
  });

  testWidgets('Validasi: password dan konfirmasi tidak cocok', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SignupScreen())));

    await tester.enterText(find.byType(TextField).at(0), 'Nama');
    await tester.enterText(find.byType(TextField).at(1), 'email@example.com');
    await tester.enterText(find.byType(TextField).at(2), '08123456789');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.enterText(find.byType(TextField).at(4), 'bedaPassword');

    await tester.tap(find.text('Daftar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Password dan konfirmasi password tidak cocok!'), findsOneWidget);
  });
}
