import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/panduan.dart';
import 'detail_informasiakun.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pesanan_page.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Biru pudar sebagai latar utama
        body: Column(
          children: [
            // Header dengan background SVG dan avatar
            Stack(
              children: [
                SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: SvgPicture.asset(
                    'assets/images/pattern_s.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/profil_orang.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),

            // Konten scrollable
            Expanded(
              child: SafeArea(
        top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                  child: Column(
                    children: [
                      // 🔹 Pesanan Saya
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PesananPage()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Pesanan saya",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _PesananItem(
                                    icon: Icons.inbox,
                                    label: "Dikemas",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PesananPage(
                                                    initialTabIndex: 1)),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 20),
                                  _PesananItem(
                                    icon: Icons.local_shipping,
                                    label: "Dikirim",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PesananPage(
                                                    initialTabIndex: 2)),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 20),
                                  _PesananItem(
                                    icon: Icons.assignment_turned_in,
                                    label: "Selesai",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PesananPage(
                                                    initialTabIndex: 3)),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 20),
                                  _PesananItem(
                                    icon: Icons.cancel,
                                    label: "Batal",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PesananPage(
                                                    initialTabIndex: 4)),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔹 Menu
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text("Detail Informasi Akun"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const DetailInformasiAkun()),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              leading: const Icon(Icons.help_outline),
                              title: const Text("Panduan"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PanduanChatbot()),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              leading: const Icon(Icons.lock_outline),
                              title: const Text("Lupa Password"),
                              onTap: () {
                                Navigator.pushNamed(context, '/lupa-password');
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔹 Logout
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("Logout",
                              style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
    );
  }
}

class _PesananItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PesananItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
