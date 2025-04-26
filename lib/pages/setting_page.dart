import 'package:flutter/material.dart';
// Import halaman lupa password

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 50,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/profil_orang.png', // Path gambar kamu
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        ListTile(
                          title: const Text("Detail Informasi Akun"),
                          onTap: () {},
                        ),
                        const Divider(height: 15),
                        ListTile(
                          title: const Text("Pesanan saya"),
                          onTap: () {},
                        ),
                        const Divider(height: 15),
                        ListTile(
                          title: const Text("Panduan"),
                          onTap: () {},
                        ),
                        const Divider(height: 15),
                        ListTile(
                          title: const Text("Lupa Password"),
                          onTap: () {
                            Navigator.pushNamed(context, '/lupa-password'); // Navigasi pakai Named Routes
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(360, 40),
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/'); // Navigasi ke login pakai Named Routes
                  },
                  child: const Text(
                    "Keluar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
