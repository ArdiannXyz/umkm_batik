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
  WidgetsFlutterBinding.ensureInitialized(); 
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

   const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.varelaRoundTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      title: "UMKM Batik",
      home: isLoggedIn ? DashboardPage() : LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const Register_page(),
        '/lupa-password': (context) => const LupaPasswordPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/masuk-otp': (context) => const MasukOtpPage(),
        '/ganti-password': (context) => const GantiPasswordPage(),
        '/search': (context) => const SearchPage(),
      },
    );
  }
}
