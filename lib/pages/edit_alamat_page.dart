import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkm_batik/pages/AlamatDropdown.dart';

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
  final String apiBaseUrl = 'http://192.168.231.254/umkm_batik/API';

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

    try {
      final userId = await _getUserId();

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID tidak ditemukan. Silakan login kembali.';
        });
        return;
      }

      // Fetch all addresses for the user
      final response = await http.get(
        Uri.parse('$apiBaseUrl/get_addresses.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final addresses = (responseData['data'] as List);

          // Find the address with matching ID
          final addressData = addresses.firstWhere(
            (address) => address['id'] == widget.addressId,
            orElse: () => null,
          );

          if (addressData != null) {
            // Populate form controllers
            _namaLengkapController.text = addressData['nama_lengkap'];
            _nomorHpController.text = addressData['nomor_hp'];
            _alamatLengkapController.text = addressData['alamat_lengkap'];

            // Set individual location fields (for AlamatDropdown)
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
              _errorMessage = 'Alamat tidak ditemukan';
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = responseData['message'] ?? 'Gagal memuat alamat';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan. Kode: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  // Update address
  Future<void> _updateAddress() async {
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final userId = await _getUserId();

      if (userId == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'User ID tidak ditemukan. Silakan login kembali.';
        });
        return;
      }

      // Prepare data to send
      final Map<String, dynamic> data = {
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

      // Make API request
      final response = await http.post(
        Uri.parse('$apiBaseUrl/edit_addresses.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(responseData['message'] ?? 'Alamat disimpan')),
            );
            Navigator.pop(
                context, true); // Return true to indicate refresh needed
          }
        } else {
          setState(() {
            _isSaving = false;
            _errorMessage =
                responseData['message'] ?? 'Gagal mengupdate alamat';
          });
        }
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Terjadi kesalahan. Kode: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  // Delete address
  Future<void> _deleteAddress() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Alamat'),
          content: const Text('Anda yakin ingin menghapus alamat ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

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

      // Prepare data to send
      final Map<String, dynamic> data = {
        'id': widget.addressId,
        'user_id': userId,
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$apiBaseUrl/delete_addresses.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(responseData['message'] ?? 'Alamat dihapus')),
            );
            Navigator.pop(
                context, true); // Return true to indicate refresh needed
          }
        } else {
          setState(() {
            _isDeleting = false;
            _errorMessage = responseData['message'] ?? 'Gagal menghapus alamat';
          });
        }
      } else {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Terjadi kesalahan. Kode: ${response.statusCode}';
        });
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
                                      : const Text("Hapus Alamat"),
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
