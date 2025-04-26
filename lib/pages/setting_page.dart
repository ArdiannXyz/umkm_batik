import 'package:flutter/material.dart';
import 'login_page.dart'; // Import halaman login

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    const SizedBox(height: 30),
                    CircleAvatar(
                      
                    radius: 50,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/profil_orang.png', // Ganti dengan path gambar kamu
                        width: 250, // Ukuran sedikit lebih kecil dari diameter CircleAvatar
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                    const SizedBox(height: 40),

                    // Pengaturan Akun
                    Container (
                       margin: EdgeInsets.symmetric(horizontal: 10),
                       
                    child: Card(
                    color: Colors.white,

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 10,),
                          ListTile(
                            title: Text("Detail Informasi Akun"),
                            onTap: () {},
                          ),
                          Divider(height: 15,),
                          ListTile(
                            title: Text("Pesanan saya"),
                            onTap: () {},
                          ),
                          Divider(height: 15,),
                          ListTile(
                            title: Text("Panduan"),
                            onTap: () {},
                          ),
                          Divider(height: 15,),
                          ListTile(
                            
                            title: Text("Lupa Password"),
                            onTap: () {},
                          ),
                          SizedBox(height: 10,),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Keluar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(360, 40),
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 50),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: const Text("Keluar",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
