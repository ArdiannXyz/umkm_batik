import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umkm_batik/pages/register_page.dart';

void main() {
  testWidgets('RegisterPage menampilkan semua input field dan tombol',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    expect(find.text('Daftarkan akun\nanda'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5)); // nama, email, hp, password, konfirmasi
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Sudah punya akun? '), findsOneWidget);
    expect(find.text('Masuk sekarang!'), findsOneWidget);
  });

  testWidgets('Validasi: semua field wajib diisi',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    await tester.tap(find.text('Daftar'));
    await tester.pump(); // tunggu snackbar

    expect(find.text('Semua kolom harus diisi!'), findsOneWidget);
  });

  testWidgets('Validasi: email tidak valid', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'Nama User');
    await tester.enterText(find.byType(TextField).at(1), 'emailInvalid');
    await tester.enterText(find.byType(TextField).at(2), '08123456789');
    await tester.enterText(find.byType(TextField).at(3), '123456');
    await tester.enterText(find.byType(TextField).at(4), '123456');

    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Masukkan email yang valid!'), findsOneWidget);
  });

  testWidgets('Validasi: password < 6 karakter',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'Nama User');
    await tester.enterText(find.byType(TextField).at(1), 'email@email.com');
    await tester.enterText(find.byType(TextField).at(2), '08123456789');
    await tester.enterText(find.byType(TextField).at(3), '123');
    await tester.enterText(find.byType(TextField).at(4), '123');

    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Password harus minimal 6 karakter!'), findsOneWidget);
  });

  testWidgets('Validasi: password dan konfirmasi tidak cocok',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'Nama User');
    await tester.enterText(find.byType(TextField).at(1), 'email@email.com');
    await tester.enterText(find.byType(TextField).at(2), '08123456789');
    await tester.enterText(find.byType(TextField).at(3), '123456');
    await tester.enterText(find.byType(TextField).at(4), '654321');

    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Password dan konfirmasi password tidak cocok!'), findsOneWidget);
  });
}
