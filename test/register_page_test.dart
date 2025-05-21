import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:umkm_batik/services/user_service.dart';
import 'package:umkm_batik/pages/register_page.dart';
import 'package:umkm_batik/pages/login_page.dart';

@GenerateNiceMocks([MockSpec<UserService>()])
import 'register_page_test.mocks.dart';

void main() {
  late MockUserService mockUserService;

  setUp(() {
    mockUserService = MockUserService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: RegisterPage(userService: mockUserService),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }

  testWidgets('Register page shows all necessary components',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify title text is present
    expect(find.text('Daftarkan akun'), findsOneWidget);
    expect(find.text('anda'), findsOneWidget);

    // Check form fields are present
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('No.hp'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);

    // Check button is present
    expect(find.text('Daftar'), findsOneWidget);

    // Check login link is present
    expect(find.text('Sudah punya akun?'), findsOneWidget);
    expect(find.text('Masuk sekarang!'), findsOneWidget);
  });

  // Perbaikan untuk test validasi form kosong
  testWidgets('Validate empty form submission shows error',
      (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap the register button without filling the form
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify error message appears
    expect(find.text('Semua kolom harus diisi!'), findsOneWidget);
  });

  testWidgets('Validate invalid email format shows error',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Fill the form with invalid email
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nama lengkap'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan email anda'), 'invalid-email');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nomor handphone anda'),
        '1234567890');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan password anda'),
        'password123');
    await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi password anda'), 'password123');

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan email yang valid!'), findsOneWidget);
  });

  testWidgets('Validate password too short shows error',
      (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(Register_page());

    // Fill the form with short password
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nama lengkap'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan email anda'),
        'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nomor handphone anda'),
        '1234567890');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan password anda'), '12345');
    await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi password anda'), '12345');

    // Tap the register button
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    // Verify error message appears
    expect(find.text('Password harus minimal 6 karakter!'), findsOneWidget);
  });

  testWidgets('Validate password mismatch shows error',
      (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(Register_page());

    // Fill the form with mismatched passwords
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nama lengkap'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan email anda'),
        'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nomor handphone anda'),
        '1234567890');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan password anda'),
        'password123');
    await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi password anda'), 'password456');

    // Tap the register button
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    // Verify error message appears
    expect(find.text('Password dan konfirmasi password tidak cocok!'),
        findsOneWidget);
  });

  testWidgets('Successful registration shows success dialog',
      (WidgetTester tester) async {
    when(mockUserService.registerUser(
      nama: anyNamed('nama'),
      email: anyNamed('email'),
      noHp: anyNamed('noHp'),
      password: anyNamed('password'),
    )).thenAnswer(
        (_) async => {'error': false, 'message': 'Registration successful'});

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nama lengkap'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan email anda'),
        'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nomor handphone anda'),
        '1234567890');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan password anda'),
        'password123');
    await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi password anda'), 'password123');

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Registrasi Berhasil!'), findsOneWidget);
    expect(find.text('Akun Anda telah berhasil dibuat. Silakan login.'),
        findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('Failed registration shows error message',
      (WidgetTester tester) async {
    when(mockUserService.registerUser(
      nama: anyNamed('nama'),
      email: anyNamed('email'),
      noHp: anyNamed('noHp'),
      password: anyNamed('password'),
    )).thenAnswer(
        (_) async => {'error': true, 'message': 'Email already exists'});

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nama lengkap'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan email anda'),
        'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan nomor handphone anda'),
        '1234567890');
    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan password anda'),
        'password123');
    await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi password anda'), 'password123');

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Registrasi gagal: Email already exists'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final passwordField =
        find.widgetWithText(TextField, 'Masukkan password anda');
    final confirmPasswordField =
        find.widgetWithText(TextField, 'Ulangi password anda');

    TextField passwordWidget = tester.widget(passwordField);
    expect(passwordWidget.obscureText, true);

    TextField confirmPasswordWidget = tester.widget(confirmPasswordField);
    expect(confirmPasswordWidget.obscureText, true);

    final passwordVisibilityIcon = find.byIcon(Icons.visibility_off).first;
    final confirmPasswordVisibilityIcon =
        find.byIcon(Icons.visibility_off).last;

    await tester.tap(passwordVisibilityIcon);
    await tester.pump();

    passwordWidget = tester.widget(passwordField);
    expect(passwordWidget.obscureText, false);

    await tester.tap(confirmPasswordVisibilityIcon);
    await tester.pump();

    confirmPasswordWidget = tester.widget(confirmPasswordField);
    expect(confirmPasswordWidget.obscureText, false);
  });

  testWidgets('Login link navigates to login page',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Masuk sekarang!'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsNothing);
  });
}
