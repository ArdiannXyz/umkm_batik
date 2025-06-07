import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tambah_alamat_page.dart';
import 'edit_alamat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/Address.dart';
import '../services/alamat_service.dart';

// Model class for Address

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
  Timer? _refreshTimer;

  // API base URL - ensure correct protocol

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    _startAutoRefresh();
  }
    @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel timer saat dispose
    super.dispose();
  }
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchAddresses();
      }
    });
  }
  // Get user ID from SharedPreferences
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Fetch addresses from API// sesuaikan path jika perlu

Future<void> _fetchAddresses() async {
  setState(() {
    isLoading = true;
    errorMessage = '';
  });

  try {
    final rawUserId = await _getUserId(); // <- Ambil userId dari SharedPreferences

    if (rawUserId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'User ID tidak ditemukan. Silakan login kembali.';
      });
      return;
    }

    final userId = rawUserId.toString(); // <- Konversi ke String

    final fetchedAddresses = await AlamatService.fetchAddresses(userId);

    setState(() {
      addresses = fetchedAddresses;
      if (addresses.isNotEmpty && selectedAddressId == null) {
        selectedAddressId = addresses.first.id;
      }
      isLoading = false;
    });
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
