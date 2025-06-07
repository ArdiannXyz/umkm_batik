import 'package:flutter/material.dart';
import 'AlamatDropdown.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alamat_service.dart';

class TambahAlamatPage extends StatefulWidget {
  final int? userId; // Parameter opsional user ID

  const TambahAlamatPage({super.key, this.userId});

  @override
  State<TambahAlamatPage> createState() => _TambahAlamatPageState();
}

class _TambahAlamatPageState extends State<TambahAlamatPage> {
  final _namaController = TextEditingController();
  final _hpController = TextEditingController();
  final _provinsiController = TextEditingController();
  final _kotaController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _kodePosController = TextEditingController();
  final _alamatLengkapController = TextEditingController();

  bool _isLoading = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  // Mendapatkan user_id dari constructor atau shared preferences
  Future<void> _getUserId() async {
    if (widget.userId != null) {
      setState(() {
        _userId = widget.userId;
      });
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        setState(() {
          _userId = userId;
        });
      } catch (e) {
        debugPrint('Error getting user_id: $e');
        // Jika error, tampilkan pesan kesalahan
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendapatkan ID pengguna')),
          );
        }
      }
    }
  }

Future<void> submitAlamat() async {
  if (_userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID pengguna tidak tersedia. Silahkan login kembali.')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final Map<String, dynamic> data = {
      'user_id': _userId,
      'nama_lengkap': _namaController.text,
      'nomor_hp': _hpController.text,
      'provinsi': _provinsiController.text,
      'kota': _kotaController.text,
      'kecamatan': _kecamatanController.text,
      'kode_pos': _kodePosController.text,
      'alamat_lengkap': _alamatLengkapController.text,
    };

    final result = await AlamatService.submitAlamat(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Alamat berhasil disimpan')),
    );

    if (result['success'] == true) {
      Navigator.pop(context);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  // Validasi form sebelum submit
  bool _validateForm() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('ID pengguna tidak tersedia. Silahkan login kembali.')),
      );
      return false;
    }

    if (_namaController.text.isEmpty ||
        _hpController.text.isEmpty ||
        _provinsiController.text.isEmpty ||
        _kotaController.text.isEmpty ||
        _kecamatanController.text.isEmpty ||
        _kodePosController.text.isEmpty ||
        _alamatLengkapController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return false;
    }

    // Debug: lihat isi semua controller
    debugPrint('UserId: $_userId');
    debugPrint('Nama: ${_namaController.text}');
    debugPrint('HP: ${_hpController.text}');
    debugPrint('Provinsi: ${_provinsiController.text}');
    debugPrint('Kota: ${_kotaController.text}');
    debugPrint('Kecamatan: ${_kecamatanController.text}');
    debugPrint('Kode Pos: ${_kodePosController.text}');
    debugPrint('Alamat Lengkap: ${_alamatLengkapController.text}');

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        title: const Text(
          'Tambah Alamat',
          style: TextStyle(color: Colors.white), // Ubah warna teks di sini
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                  "Isi data alamat",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _InputField(label: "Nama Lengkap", controller: _namaController),
                const SizedBox(height: 16),
                _InputField(
                  label: "No. Telepon",
                  controller: _hpController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                AlamatDropdown(
                  provinsiController: _provinsiController,
                  kotaController: _kotaController,
                  kecamatanController: _kecamatanController,
                ),
                const SizedBox(height: 16),
                _InputField(
                  label: "Kode Pos",
                  controller: _kodePosController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _InputField(
                  label: "Detail lengkap alamat",
                  controller: _alamatLengkapController,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_validateForm()) {
                                  submitAlamat();
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ))
                            : const Text("Simpan"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(
                                    context); // Kembali tanpa menyimpan
                              },
                        child: const Text("Batal"),
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

  @override
  void dispose() {
    _namaController.dispose();
    _hpController.dispose();
    _provinsiController.dispose();
    _kotaController.dispose();
    _kecamatanController.dispose();
    _kodePosController.dispose();
    _alamatLengkapController.dispose();
    super.dispose();
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _InputField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
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
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            border: UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
