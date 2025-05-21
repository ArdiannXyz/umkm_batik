import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:umkm_batik/services/user_service.dart';
import 'package:umkm_batik/lib/pages/masuk_otp.dart'; // Sesuaikan dengan struktur proyek Anda

@GenerateNiceMocks([MockSpec<UserService>()])
import 'masuk_otp_page_test.mocks.dart';

void main() {
  late MockUserService mockUserService;

  setUp(() {
    mockUserService = MockUserService();
  });

  testWidgets('MasukOtpPage menampilkan semua komponen yang diperlukan', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(
      MaterialApp(
        home: MasukOtpPage(),
        routes: {
          '/ganti-password': (context) => Scaffold(body: Text('Ganti Password Page')),
        },
      ),
    );

    // Verifikasi judul halaman
    expect(find.text('Masukkan Kode OTP'), findsOneWidget);
    
    // Verifikasi instruksi
    expect(find.text('Kami telah mengirimkan kode ke email Anda.'), findsOneWidget);
    
    // Verifikasi field OTP
    expect(find.text('Kode OTP'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    
    // Verifikasi tombol
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
  });

  testWidgets('Validasi OTP kurang dari 6 digit menampilkan pesan error', (WidgetTester tester) async {
    // Simpan implementasi asli
    final originalCekOtp = UserService.cekOtp;
    
    // Ganti dengan mock
    UserService.cekOtp = mockUserService.cekOtp;
    
    // Build app dengan argumen email yang diperlukan
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Builder(
                builder: (context) {
                  // Simulasi navigasi dengan argumen
                  ModalRoute.of(context)?.settings.arguments = {'email': 'test@example.com'};
                  return MasukOtpPage();
                },
              ),
            );
          },
        ),
        routes: {
          '/ganti-password': (context) => Scaffold(body: Text('Ganti Password Page')),
        },
      ),
    );

    // Masukkan OTP yang tidak valid (kurang dari 6 digit)
    await tester.enterText(find.byType(TextField), '12345');
    
    // Klik tombol Lanjut
    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    
    // Verifikasi pesan error muncul
    expect(find.text('Kode OTP harus 6 digit.'), findsOneWidget);
    
    // Kembalikan implementasi asli
    UserService.cekOtp = originalCekOtp;
  });

  testWidgets('Validasi OTP hanya boleh berisi angka menampilkan pesan error', (WidgetTester tester) async {
    // Simpan implementasi asli
    final originalCekOtp = UserService.cekOtp;
    
    // Ganti dengan mock
    UserService.cekOtp = mockUserService.cekOtp;
    
    // Build app dengan argumen email yang diperlukan
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Builder(
                builder: (context) {
                  // Simulasi navigasi dengan argumen
                  ModalRoute.of(context)?.settings.arguments = {'email': 'test@example.com'};
                  return MasukOtpPage();
                },
              ),
            );
          },
        ),
        routes: {
          '/ganti-password': (context) => Scaffold(body: Text('Ganti Password Page')),
        },
      ),
    );

    // Masukkan OTP yang tidak valid (mengandung huruf)
    await tester.enterText(find.byType(TextField), '12a456');
    
    // Klik tombol Lanjut
    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    
    // Verifikasi pesan error muncul
    expect(find.text('Kode OTP hanya boleh berisi angka.'), findsOneWidget);
    
    // Kembalikan implementasi asli
    UserService.cekOtp = originalCekOtp;
  });

  testWidgets('OTP valid dan berhasil diverifikasi, navigasi ke halaman ganti password', (WidgetTester tester) async {
    // Simpan implementasi asli
    final originalCekOtp = UserService.cekOtp;
    
    // Ganti dengan mock
    UserService.cekOtp = mockUserService.cekOtp;
    
    // Set mock response untuk OTP yang valid
    when(mockUserService.cekOtp('test@example.com', '123456'))
        .thenAnswer((_) async => {'error': false, 'message': 'OTP valid'});
    
    // Build app dengan argumen email yang diperlukan
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Builder(
                builder: (context) {
                  // Simulasi navigasi dengan argumen
                  ModalRoute.of(context)?.settings.arguments = {'email': 'test@example.com'};
                  return MasukOtpPage();
                },
              ),
            );
          },
        ),
        routes: {
          '/ganti-password': (context) => Scaffold(body: Text('Ganti Password Page')),
        },
      ),
    );

    // Masukkan OTP yang valid
    await tester.enterText(find.byType(TextField), '123456');
    
    // Klik tombol Lanjut
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    
    // Verifikasi navigasi ke halaman ganti password
    expect(find.text('Ganti Password Page'), findsOneWidget);
    
    // Kembalikan implementasi asli
    UserService.cekOtp = originalCekOtp;
  });

  testWidgets('OTP valid tapi gagal diverifikasi, menampilkan pesan error', (WidgetTester tester) async {
    // Simpan implementasi asli
    final originalCekOtp = UserService.cekOtp;
    
    // Ganti dengan mock
    UserService.cekOtp = mockUserService.cekOtp;
    
    // Set mock response untuk OTP yang tidak valid
    when(mockUserService.cekOtp('test@example.com', '123456'))
        .thenAnswer((_) async => {'error': true, 'message': 'OTP tidak valid atau sudah kadaluarsa'});
    
    // Build app dengan argumen email yang diperlukan
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Builder(
                builder: (context) {
                  // Simulasi navigasi dengan argumen
                  ModalRoute.of(context)?.settings.arguments = {'email': 'test@example.com'};
                  return MasukOtpPage();
                },
              ),
            );
          },
        ),
        routes: {
          '/ganti-password': (context) => Scaffold(body: Text('Ganti Password Page')),
        },
      ),
    );

    // Masukkan OTP
    await tester.enterText(find.byType(TextField), '123456');
    
    // Klik tombol Lanjut
    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    
    // Verifikasi pesan error muncul
    expect(find.text('OTP tidak valid atau sudah kadaluarsa'), findsOneWidget);
    
    // Verifikasi tidak navigasi ke halaman ganti password
    expect(find.text('Ganti Password Page'), findsNothing);
    
    // Kembalikan implementasi asli
    UserService.cekOtp = originalCekOtp;
  });

  testWidgets('Tombol Kembali berfungsi', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          pages: [
            MaterialPage(
              child: Scaffold(body: Text('Halaman Sebelumnya')),
              key: ValueKey('prev_page'),
            ),
            MaterialPage(
              child: MasukOtpPage(),
              key: ValueKey('otp_page'),
            ),
          ],
          onPopPage: (route, result) => route.didPop(result),
        ),
      ),
    );

    // Klik tombol Kembali
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    
    // Verifikasi kembali ke halaman sebelumnya
    expect(find.text('Halaman Sebelumnya'), findsOneWidget);
  });

  testWidgets('Loading indicator ditampilkan selama verifikasi OTP', (WidgetTester tester) async {
    // Simpan implementasi asli
    final originalCekOtp = UserService.cekOtp;
    
    // Ganti dengan mock
    UserService.cekOtp = mockUserService.cekOtp;
    
    // Setup mock yang akan delay sebelum mengembalikan hasil
    when(mockUserService.cekOtp('test@example.com', '123456'))
        .thenAnswer((_) async {
          // Delay simulasi network
          await Future.delayed(Duration(milliseconds: 500));
          return {'error': false, 'message': 'OTP valid'};
        });
    
    // Build app dengan argumen email yang diperlukan
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Builder(
                builder: (context) {
                  // Simulasi navigasi dengan argumen
                  ModalRoute.of(context)?.settings.arguments = {'email': 'test@example.com'};
                  return MasukOtpPage();
                },
              ),
            );
          },
        ),
        routes: {
          '/ganti-password': (context) => Scaffold(body: Text('Ganti Password Page')),
        },
      ),
    );

    // Masukkan OTP yang valid
    await tester.enterText(find.byType(TextField), '123456');
    
    // Klik tombol Lanjut
    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    
    // Verifikasi loading indicator muncul
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Lanjut'), findsNothing);
    
    // Selesaikan proses
    await tester.pumpAndSettle();
    
    // Verifikasi navigasi ke halaman ganti password
    expect(find.text('Ganti Password Page'), findsOneWidget);
    
    // Kembalikan implementasi asli
    UserService.cekOtp = originalCekOtp;
  });
}