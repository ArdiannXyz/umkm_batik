import 'dart:async';
import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/login_page.dart';
 // Halaman utama yang akan dituju

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay 3 detik lalu pindah ke halaman utama
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/splashscreen.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
     ),
);
}
}