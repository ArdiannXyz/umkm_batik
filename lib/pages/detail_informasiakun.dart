import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkm_batik/services/user_service.dart';
import 'package:umkm_batik/models/user_model.dart';
import 'editprofil.dart';
import 'dart:async';

class DetailInformasiAkun extends StatefulWidget {
  const DetailInformasiAkun({super.key});

  @override
  State<DetailInformasiAkun> createState() => _DetailInformasiAkunState();
}

class _DetailInformasiAkunState extends State<DetailInformasiAkun> {
  User? user;
  Timer? _refreshTimer;

@override
void initState() {
  super.initState();
  loadUserData();
  startAutoRefresh();
}
void startAutoRefresh() {
  _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    loadUserData();
  });
}

@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');

    if (id != null) {
      final fetchedUser = await UserService.fetchUser(id);
      setState(() {
        user = fetchedUser;
      });
    } else {
      print("User belum login");
    }
  }

          @override
          Widget build(BuildContext context) {
            return Scaffold(
              backgroundColor: const Color(0xFFEFF6FF), // Biru muda
              appBar: AppBar(
                    backgroundColor: const Color (0xFF0D6EFD), // Warna biru untuk kotak judul
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    centerTitle: true,
                    title: const Text(
                      'Detail Informasi Akun',
                      style: TextStyle(
                        color: Colors.white, // Teks putih di atas kotak biru
                      ),
                    ),
                  ),

      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 40),
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
                const SizedBox(height: 30),
                
                // Baris Informasi Profil dan Tombol Edit
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Informasi Profil",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilPage(user: user!), // kirim user!
                          ),
                        );

                        },
                        child: const Text(
                          "Edit Profil",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Card Informasi User
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user!.nama, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(maskEmail(user!.email),
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(user!.noHp, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Fungsi masking email
  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts[0].length <= 4) {
      return email; // biarin kalau nama pendek
    }
    return '${parts[0].substring(0, 4)}*****@${parts[1]}';
  }
}
