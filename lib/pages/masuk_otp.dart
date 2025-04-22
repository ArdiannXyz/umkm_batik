import 'package:flutter/material.dart';

class MasukOtpPage extends StatefulWidget {
  const MasukOtpPage({super.key});

  @override
  _MasukOtpPageState createState() => _MasukOtpPageState();
}

class _MasukOtpPageState extends State<MasukOtpPage> {
  final TextEditingController _otpController = TextEditingController();

  void _submitOtp() {
    // Untuk sekarang kita langsung skip verifikasi OTP
    Navigator.pushNamed(context, '/ganti-password');
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
                    "Masukan Kode OTP",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Image.asset(
                    'assets/images/griyabatik_hitam.png',
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
              const Text("Kami telah mengirimkan kode ke email Anda"),
              const SizedBox(height: 20),
              const Text("Kode OTP"),
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
                  onPressed: _submitOtp,
                  child: const Text(
                    "Lanjut",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Balik ke lupa password
                },
                child: const Center(
                  child: Text("Kembali", style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
