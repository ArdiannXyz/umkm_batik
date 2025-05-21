import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/lupa_password.dart';
import 'pages/masuk_otp.dart';
import 'pages/ganti_password.dart';
import 'pages/search_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Wajib kalau pakai async di main()
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
      textTheme: GoogleFonts.varelaRoundTextTheme(),
    ),
      debugShowCheckedModeBanner: false,
      title: "UMKM Batik",
      initialRoute: isLoggedIn ? '/dashboard' : '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => Register_page(),
        '/lupa-password': (context) => LupaPasswordPage(),
        '/dashboard': (context) => DashboardPage(),
        '/masuk-otp': (context) => MasukOtpPage(),
        '/ganti-password': (context) => GantiPasswordPage(),
        '/search': (context) =>  SearchPage(),
      },
    );
  }
}
