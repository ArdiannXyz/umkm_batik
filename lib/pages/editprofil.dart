import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkm_batik/services/user_service.dart';
import 'package:umkm_batik/models/user_model.dart';

class EditProfilPage extends StatefulWidget {
final User user;
  
  const EditProfilPage({super.key, required this.user});
  

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

InputDecoration inputDecoration({required String hintText}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hintText,
    hintStyle: const TextStyle(color: Colors.grey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blue), // Pas klik biru dikit
    ),
  );
}


class _EditProfilPageState extends State<EditProfilPage> {
  // Controller untuk form input
  late TextEditingController namaController;
  late TextEditingController emailController;
  late TextEditingController noHpController;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.user.nama);
    emailController = TextEditingController(text: widget.user.email);
    noHpController = TextEditingController(text: widget.user.noHp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // warna biru muda
      appBar: AppBar(
        backgroundColor: const Color (0xFF0D6EFD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Edit profil',
          style: TextStyle(color: Colors.white),
        ),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form Nama
            const SizedBox(height: 20),
            TextField(
              controller: namaController,
              decoration: inputDecoration(hintText: ''),
            ),
            const SizedBox(height: 40),

            // Form Email
            TextField(
              controller: emailController,
              enabled: false, 
              decoration: inputDecoration(hintText: ''),
            ),
            const SizedBox(height: 40),

            // Form No HP
            TextField(
              controller: noHpController,
              
              decoration: inputDecoration(hintText: ''),

            ),
            const Spacer(),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF), // warna biru tombol
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                    // Ambil ID dari SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    final id = prefs.getInt('user_id');
                  if (id != null) {
                        bool success = await UserService.updateUser(
                          id,
                          namaController.text,
                          emailController.text,
                          noHpController.text,
                        );

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui')),
                          );
                          Navigator.pop(context); // kembali ke halaman sebelumnya
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal memperbarui profil')),
                          );
                        }
                      } else {
                        print('User ID tidak ditemukan di SharedPreferences');
                      }
                    },

                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
