import 'package:flutter/material.dart';

class EditAddressPage extends StatelessWidget {
  const EditAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        title: const Text("Ubah Alamat"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Alamat",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const _InputField(label: "Nama Lengkap", value: "Ado Chann"),
                const SizedBox(height: 16),
                const _InputField(label: "No. Telepon", value: "08172937333"),
                const SizedBox(height: 16),
                const _InputField(
                  label: "Provinsi, Kota, Kecamatan, Kode pos",
                  value: "JAWA TIMUR\nKAB. JEMBER\nUMBULSARI\n89975",
                ),
                const SizedBox(height: 16),
                const _InputField(
                  label: "Detail lengkap alamat",
                  value: "Sukoreno gang 6 ketimur toko tingkat selatan jalan",
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white, // Teks berwarna putih
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Aksi simpan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Alamat disimpan")),
                          );
                        },
                        child: const Text("Simpan"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white, // Teks berwarna putih
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Aksi hapus alamat
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Alamat dihapus")),
                          );
                        },
                        child: const Text("Hapus Alamat"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          maxLines: maxLines,
          decoration: const InputDecoration(
            isDense: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
