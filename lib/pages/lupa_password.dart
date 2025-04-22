import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  void _submitReset() {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Silakan masukkan email Anda."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simulasi kirim email berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Kode OTP dikirim ke $email"),
        backgroundColor: Colors.green,
      ),
    );

    // Arahkan ke halaman OTP setelah 1 detik
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushNamed(
        context,
        '/masuk-otp',
        arguments: {'email': email}, // Jika ingin bawa data email
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lupa Password?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Image.asset(
                    'assets/images/griyabatik_hitam.png',
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
              const Text("Masukkan email yang terdaftar"),
              const SizedBox(height: 20),
              const Text("Email"),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Masukkan email anda",
                  filled: true,
                  fillColor: Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _submitReset,
                  child: const Text(
                    "Kirim Link Reset",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Kembali ke login
                },
                child: const Center(
                  child: Text("Kembali ke Login",
                      style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
