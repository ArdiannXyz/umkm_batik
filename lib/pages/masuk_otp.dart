import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MasukOtpPage extends StatefulWidget {
  const MasukOtpPage({super.key});

  @override
  _MasukOtpPageState createState() => _MasukOtpPageState();
}

class _MasukOtpPageState extends State<MasukOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool isLoading = false;

  final String apiUrl = "http://localhost/umkm_batik/API/cek_otp.php"; 
  // Ganti kalau pakai domain: "https://namadomainmu.com/API/cek_otp.php"
  // atau emulator Android: "http://10.0.2.2/umkm_batik/API/cek_otp.php"

  Future<void> _submitOtp() async {
    String otp = _otpController.text.trim();

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    String email = args['email'];

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kode OTP harus 6 digit."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['error'] == false) {
        Navigator.pushNamed(
          context,
          '/ganti-password',
          arguments: {'email': email},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan, coba lagi."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Masukkan Kode OTP",
                    style: GoogleFonts.fredokaOne(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Image.asset(
                    'assets/images/griyabatik_hitam.png',
                    width: 72,
                    height: 72,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Kami telah mengirimkan kode ke email Anda.",
                style: GoogleFonts.fredokaOne(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Kode OTP"),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "Contoh: 123456",
                  filled: true,
                  fillColor: Colors.blue[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isLoading ? null : _submitOtp,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Lanjut",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Kembali",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
