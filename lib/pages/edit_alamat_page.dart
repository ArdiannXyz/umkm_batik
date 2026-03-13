import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkm_batik/pages/AlamatDropdown.dart';
import 'package:umkm_batik/services/alamat_service.dart';
import '../models/Address.dart';


class EditAddressPage extends StatefulWidget {
  final int addressId;

  const EditAddressPage({
    Key? key,
    required this.addressId,
  }) : super(key: key);

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final alamatService = AlamatService();
  // Form controllers
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();
  final TextEditingController _alamatLengkapController =
      TextEditingController();

  // Controllers for location fields (added for AlamatDropdown)
  final TextEditingController _provinsiController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final TextEditingController _kodePosController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String _errorMessage = '';

  // API base URL

  @override
  void initState() {
    super.initState();
    _fetchAddressDetails();
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _nomorHpController.dispose();
    _alamatLengkapController.dispose();
    _provinsiController.dispose();
    _kotaController.dispose();
    _kecamatanController.dispose();
    _kodePosController.dispose();
    super.dispose();
  }

  // Get user ID from SharedPreferences
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Fetch address details
  Future<void> _fetchAddressDetails() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  final userId = await _getUserId();
  if (userId == null) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'User ID tidak ditemukan. Silakan login kembali.';
    });
    return;
  }

  final id = widget.addressId.toString();
    final uid = userId.toString();
  final result = await alamatService.fetchAddressDetails(uid, id);

  if (result['success']) {
    final addressData = result['data'];
    _namaLengkapController.text = addressData['nama_lengkap'];
    _nomorHpController.text = addressData['nomor_hp'];
    _alamatLengkapController.text = addressData['alamat_lengkap'];
    _provinsiController.text = addressData['provinsi'];
    _kotaController.text = addressData['kota'];
    _kecamatanController.text = addressData['kecamatan'];
    _kodePosController.text = addressData['kode_pos'].toString();

    setState(() {
      _isLoading = false;
    });
  } else {
    setState(() {
      _isLoading = false;
      _errorMessage = result['message'];
    });
  }
}


  // Update address
  Future<void> _updateAddress() async {
  setState(() {
    _isSaving = true;
    _errorMessage = '';
  });

  final userId = await _getUserId();
  if (userId == null) {
    setState(() {
      _isSaving = false;
      _errorMessage = 'User ID tidak ditemukan. Silakan login kembali.';
    });
    return;
  }

  final data = {
    'id': widget.addressId,
    'user_id': userId,
    'nama_lengkap': _namaLengkapController.text,
    'nomor_hp': _nomorHpController.text,
    'provinsi': _provinsiController.text,
    'kota': _kotaController.text,
    'kecamatan': _kecamatanController.text,
    'kode_pos': _kodePosController.text,
    'alamat_lengkap': _alamatLengkapController.text,
  };

  final result = await alamatService.updateAddress(data);

  if (result['success']) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Alamat disimpan')),
      );
      Navigator.pop(context, true);
    }
  } else {
    setState(() {
      _isSaving = false;
      _errorMessage = result['message'];
    });
  }
}

  // Delete address
  Future<void> _deleteAddress() async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Mencegah dismiss dengan tap di luar
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Alamat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apakah Anda yakin ingin menghapus alamat ini?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Ya, Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  if (confirm != true) return;

  setState(() {
    _isDeleting = true;
    _errorMessage = '';
  });

  try {
    final userId = await _getUserId();

    if (userId == null) {
      setState(() {
        _isDeleting = false;
        _errorMessage = 'User ID tidak ditemukan. Silakan login kembali.';
      });
      return;
    }

    final id = widget.addressId.toString();
    final uid = userId.toString();
    await AlamatService.deleteAddress(uid, id);



    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil dihapus')),
      );
      Navigator.pop(context, true);
    }
  } catch (e) {
    setState(() {
      _isDeleting = false;
      _errorMessage = 'Terjadi kesalahan: $e';
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        title: const Text(
          'Edit Alamat',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAddressDetails,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Center(
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
                          _InputField(
                            label: "Nama Lengkap",
                            controller: _namaLengkapController,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            label: "No. Telepon",
                            controller: _nomorHpController,
                          ),
                          const SizedBox(height: 16),

                          // Replace the location text field with AlamatDropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lokasi",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AlamatDropdown(
                                provinsiController: _provinsiController,
                                kotaController: _kotaController,
                                kecamatanController: _kecamatanController,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _InputField(
                            label: "Kode Pos",
                            controller: _kodePosController,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            label: "Detail lengkap alamat",
                            controller: _alamatLengkapController,
                            maxLines: 2,
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
                                  ),
                                  onPressed: _isSaving ? null : _updateAddress,
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0,
                                          ),
                                        )
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
                                  ),
                                  onPressed:
                                      _isDeleting ? null : _deleteAddress,
                                  child: _isDeleting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0,
                                          ),
                                        )
                                      : const Text("Hapus"),
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
  final TextEditingController controller;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.controller,
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
          controller: controller,
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
