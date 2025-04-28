import 'package:flutter/material.dart';
import 'tambah_alamat_page.dart';
import 'edit_alamat_page.dart';

class PilihAlamatPage extends StatelessWidget {
  const PilihAlamatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text('Pilih Alamat'),
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Radio(
                        value: true,
                        groupValue: true,
                        onChanged: null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Ado Chann',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                                'Sukoreno gang 6 ketimur toko tingkat selatan jalan'),
                            Text('UMBULSARI, KAB Jember, JAWA TIMUR'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditAddressPage(),
                            ),
                          );
                        },
                        child: const Text('Ubah'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const TambahAlamatPage(), // ✅ Sudah diarahkan dengan benar
                  ),
                );
              },
              child: const Text('Tambah Alamat'),
            ),
          ),
        ],
      ),
    );
  }
}
