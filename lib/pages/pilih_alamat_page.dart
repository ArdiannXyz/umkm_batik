import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tambah_alamat_page.dart';
import 'edit_alamat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model class for Address
class Address {
  final int id;
  final int userId;
  final String namaLengkap;
  final String nomorHp;
  final String provinsi;
  final String kota;
  final String kecamatan;
  final int kodePos;
  final String alamatLengkap;
  final String createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.namaLengkap,
    required this.nomorHp,
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
    required this.kodePos,
    required this.alamatLengkap,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userId: json['user_id'],
      namaLengkap: json['nama_lengkap'],
      nomorHp: json['nomor_hp'],
      provinsi: json['provinsi'],
      kota: json['kota'],
      kecamatan: json['kecamatan'],
      kodePos: json['kode_pos'],
      alamatLengkap: json['alamat_lengkap'],
      createdAt: json['created_at'],
    );
  }
}

class PilihAlamatPage extends StatefulWidget {
  const PilihAlamatPage({super.key});

  @override
  State<PilihAlamatPage> createState() => _PilihAlamatPageState();
}

class _PilihAlamatPageState extends State<PilihAlamatPage> {
  List<Address> addresses = [];
  bool isLoading = true;
  String errorMessage = '';
  int? selectedAddressId;

  // API base URL - ensure correct protocol
  final String apiBaseUrl = 'http://localhost/umkm_batik/API/get_addresses.php';

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  // Get user ID from SharedPreferences
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Fetch addresses from API
  Future<void> _fetchAddresses() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userId = await _getUserId();

      if (userId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User ID tidak ditemukan. Silakan login kembali.';
        });
        return;
      }

      // Fixed URL - added http:// protocol
      final response = await http.get(
        Uri.parse(
            'http://192.168.100.48/umkm_batik/API/get_addresses.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            setState(() {
              addresses = (responseData['data'] as List)
                  .map((item) => Address.fromJson(item))
                  .toList();

              // Select the first address by default if available
              if (addresses.isNotEmpty && selectedAddressId == null) {
                selectedAddressId = addresses.first.id;
              }

              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
              errorMessage = responseData['message'] ?? 'Gagal memuat alamat';
            });
          }
        } catch (e) {
          setState(() {
            isLoading = false;
            errorMessage = 'Gagal memproses data: Format JSON tidak valid';
          });
          print('JSON parse error: $e');
          print('Response body: ${response.body}');
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Terjadi kesalahan. Kode: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        title: const Text(
          'Pilih Alamat',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchAddresses,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : addresses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Belum ada alamat tersimpan',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TambahAlamatPage(),
                                      ),
                                    );
                                    if (result == true) {
                                      _fetchAddresses();
                                    }
                                  },
                                  child: const Text('Tambah Alamat Sekarang'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAddresses,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: addresses.length,
                              itemBuilder: (context, index) {
                                final address = addresses[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () {
                                      // Update selected address ID
                                      setState(() {
                                        selectedAddressId = address.id;
                                      });

                                      // Add a slight delay for visual feedback before returning to checkout
                                      Future.delayed(
                                          const Duration(milliseconds: 300),
                                          () {
                                        // Return the selected address to CheckoutPage
                                        Navigator.pop(context, address);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: selectedAddressId == address.id
                                            ? Border.all(
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                                width: 2)
                                            : Border.all(
                                                color: Colors.grey.shade200),
                                        boxShadow: [
                                          if (selectedAddressId == address.id)
                                            BoxShadow(
                                              color:
                                                  Colors.blue.withOpacity(0.2),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<int>(
                                            value: address.id,
                                            groupValue: selectedAddressId,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedAddressId = value;
                                              });

                                              // Return the selected address on radio change too
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 300), () {
                                                Navigator.pop(context, address);
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  address.namaLengkap,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                    '${address.kecamatan}, ${address.kota}, ${address.provinsi}'),
                                                Text(
                                                    'Kode Pos: ${address.kodePos}'),
                                                Text(
                                                    'No. HP: ${address.nomorHp}'),
                                                Text(address.alamatLengkap),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditAddressPage(
                                                    addressId: address.id,
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                _fetchAddresses();
                                              }
                                            },
                                            child: const Text('Ubah'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TambahAlamatPage()),
                );
                if (result == true) {
                  _fetchAddresses();
                }
              },
              child: const Text(
                'Tambah Alamat',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
