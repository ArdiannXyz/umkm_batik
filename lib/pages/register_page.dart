import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:umkm_batik/Services/UserService.dart';

void main() {
  runApp(Register_page());
}

class Register_page extends StatelessWidget {
  const Register_page({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignupScreen(),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    // Validasi input sebelum mengirim ke server
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua kolom harus diisi!")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Validasi format email
    if (!RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
        .hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Masukkan email yang valid!")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Validasi panjang password
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password harus minimal 6 karakter!")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Validasi password dan konfirmasi password
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Password dan konfirmasi password tidak cocok!")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

     try {
    final data = await UserService.registerUser(
      nama: nameController.text,
      email: emailController.text,
      noHp: phoneController.text,
      password: passwordController.text,
    );

    if (data['error'] == false) {
      showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registrasi gagal: ${data['message']}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Terjadi kesalahan. Coba lagi nanti.")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Registrasi Berhasil!"),
          content: Text("Akun Anda telah berhasil dibuat. Silakan login."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      "Buat akun\nanda",
                      style: GoogleFonts.fredokaOne(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/griyabatik_hitam.png',
                    width: 64,
                    height: 64,
                  ),
                ],
              ),

              SizedBox(height: 20),
              // Nama Lengkap
              const Text("Nama Lengkap"),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: nameController,
                decoration: buildInputDecoration("Masukkan nama lengkap"),
              ),
              SizedBox(height: 15),

              // Email
              const Text("Email"),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: emailController,
                decoration: buildInputDecoration("Masukkan email anda"),
              ),
              SizedBox(height: 15),

              // No HP
              const Text("No.hp"),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: phoneController,
                decoration:
                    buildInputDecoration("Masukkan nomor handphone anda"),
              ),
              SizedBox(height: 15),

              // Password
              const Text("Password"),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: buildPasswordInputDecoration(
                  "Masukkan password anda",
                  obscurePassword,
                  () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
              SizedBox(height: 15),

              // Konfirmasi Password
              const Text("Konfirmasi Password"),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: buildPasswordInputDecoration(
                  "Ulangi password anda",
                  obscureConfirmPassword,
                  () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                ),
              ),
              SizedBox(height: 20),

              // Tombol Daftar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading ? null : registerUser,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Daftar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Sudah punya akun?
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sudah punya akun? ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        "Masuk sekarang!",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.blue.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration buildPasswordInputDecoration(
      String hintText, bool isObscure, VoidCallback toggleObscure) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.blue.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      suffixIcon: IconButton(
        icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey),
        onPressed: toggleObscure,
      ),
    );
  }
}
