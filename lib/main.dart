import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/lupa_password.dart';
import 'pages/masuk_otp.dart';
import 'pages/ganti_password.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "UMKM Batik",
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => Register_page(),
        '/forgot-password': (context) => ForgotPasswordPage(),
        '/dashboard': (context) => DashboardPage(),
        '/masuk-otp': (context) => MasukOtpPage(),
        '/ganti-password': (context) => GantiPasswordPage(),
      },
    );
  }
}
