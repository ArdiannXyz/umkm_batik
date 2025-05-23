import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/payment_method.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';
import 'pilih_alamat_page.dart';

// Import RajaOngkirService yang sudah dibuat
import '../services/rajaongkir_service.dart';

// Model class for product data
class ProductItem {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final Uint8List? image;
  final String imageBase64;
  final int weight; // Berat produk dalam gram

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    required this.imageBase64,
    this.weight = 1000, // Default 1kg jika tidak disebutkan
  });
}

class CheckoutPage extends StatefulWidget {
  final ProductItem product;

  const CheckoutPage({
    super.key,
    required this.product,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Address? selectedAddress;
  PaymentMethod? selectedPaymentMethod;
  bool isLoading = false;
  int? userId;

  // Shipping variables dengan RajaOngkir
  double shippingCost = 0;
  List<ShippingCost> availableShippingOptions = [];
  ShippingCost? selectedShippingOption;
  bool isLoadingShipping = false;
  String? destinationCityId;
  RajaOngkirCity? destinationCity;
  String? destinationProvince;

  // Tambahan untuk lokasi toko/asal pengiriman
  final String originProvince =
      "Jawa Timur"; // Sesuaikan dengan lokasi toko Anda
  final String originCity = "Bondowoso"; // Sesuaikan dengan kota toko Anda

  final double serviceFee = 4000;

  // Daftar provinsi di Pulau Jawa
  final Set<String> javaProvinces = {
    'jawa tengah',
    'jawa timur',
    'jawa barat',
    'dki jakarta',
    'di yogyakarta',
    'yogyakarta',
    'banten'
  };

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getInt('user_id');
      });

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login tidak ditemukan. Silakan login kembali.'),
          ),
        );
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  // Fungsi untuk menentukan apakah pengiriman dalam provinsi yang sama
  bool _isWithinSameProvince(String destinationProvince) {
    return destinationProvince.toLowerCase().trim() ==
        originProvince.toLowerCase().trim();
  }

  // Fungsi untuk menentukan apakah pengiriman dalam kota yang sama
  bool _isWithinSameCity(String destinationCity, String destinationProvince) {
    return _isWithinSameProvince(destinationProvince) &&
        destinationCity.toLowerCase().trim() == originCity.toLowerCase().trim();
  }

  // Fungsi untuk menentukan apakah pengiriman dalam pulau yang sama (Jawa)
  bool _isWithinSameIsland(String destinationProvince) {
    final destProvinceLower = destinationProvince.toLowerCase().trim();
    final originProvinceLower = originProvince.toLowerCase().trim();

    return javaProvinces.contains(destProvinceLower) &&
        javaProvinces.contains(originProvinceLower);
  }

  // Fungsi untuk menentukan apakah pengiriman ke luar pulau
  bool _isInterIslandDelivery(String destinationProvince) {
    final destProvinceLower = destinationProvince.toLowerCase().trim();
    final originProvinceLower = originProvince.toLowerCase().trim();

    // Jika asal dari Jawa dan tujuan bukan Jawa, maka luar pulau
    return javaProvinces.contains(originProvinceLower) &&
        !javaProvinces.contains(destProvinceLower);
  }

  // Fungsi untuk filter opsi pengiriman berdasarkan lokasi
  List<ShippingCost> _filterShippingOptionsByLocation(
      List<ShippingCost> allOptions,
      String destinationCity,
      String destinationProvince) {
    List<ShippingCost> filteredOptions = [];

    if (_isWithinSameCity(destinationCity, destinationProvince)) {
      // Dalam kota yang sama - hanya courier lokal dan same day delivery
      filteredOptions = allOptions.where((option) {
        String serviceLower = option.service.toLowerCase();
        String courierLower = option.courier.toLowerCase();

        return serviceLower.contains('same day') ||
            serviceLower.contains('instant') ||
            serviceLower.contains('motor') ||
            courierLower.contains('gosend') ||
            courierLower.contains('grab') ||
            (option.isStandardOption && option.etd.contains('1'));
      }).toList();

      // Jika tidak ada opsi khusus, tambahkan opsi standar lokal
      if (filteredOptions.isEmpty) {
        filteredOptions.add(ShippingCost(
          service: 'LOKAL',
          description: 'Pengiriman Lokal',
          cost: 8000,
          etd: '1',
          courier: 'LOKAL',
          isStandardOption: true,
        ));
      }
    } else if (_isWithinSameProvince(destinationProvince)) {
      // Dalam provinsi yang sama - exclude pengiriman antar pulau dan internasional
      filteredOptions = allOptions.where((option) {
        String serviceLower = option.service.toLowerCase();
        String courierLower = option.courier.toLowerCase();

        return !serviceLower.contains('oke') &&
            !serviceLower.contains('yes') &&
            !courierLower.contains('lion') &&
            !courierLower.contains('sap') &&
            !courierLower.contains('cargo') &&
            !serviceLower.contains('ekonomi super hemat') &&
            !(option.isStandardOption && option.etd.contains('7-14'));
      }).toList();

      // Jika tidak ada opsi, tambahkan opsi standar provinsi
      if (filteredOptions.isEmpty) {
        filteredOptions.add(ShippingCost(
          service: 'PROVINSI',
          description: 'Pengiriman Dalam Provinsi',
          cost: 12000,
          etd: '2-3',
          courier: 'PROVINSI',
          isStandardOption: true,
        ));
      }
    } else if (_isInterIslandDelivery(destinationProvince)) {
      // Pengiriman luar pulau - hanya opsi luar pulau
      filteredOptions = allOptions.where((option) {
        String serviceLower = option.service.toLowerCase();
        String courierLower = option.courier.toLowerCase();

        // Filter untuk layanan luar pulau/antar pulau
        return serviceLower.contains('cargo') ||
            serviceLower.contains('ekonomi') ||
            serviceLower.contains('laut') ||
            serviceLower.contains('darat') ||
            courierLower.contains('lion') ||
            courierLower.contains('sap') ||
            courierLower.contains('wahana') ||
            courierLower.contains('dakota') ||
            courierLower.contains('first') ||
            serviceLower.contains('oke') ||
            serviceLower.contains('yes') ||
            (option.isStandardOption && option.etd.contains('7-14')) ||
            (option.isStandardOption && serviceLower.contains('luar'));
      }).toList();

      // Jika tidak ada opsi luar pulau dari API, tambahkan opsi standar luar pulau
      if (filteredOptions.isEmpty) {
        filteredOptions.addAll([
          ShippingCost(
            service: 'LUAR_PULAU_EKONOMI',
            description: 'Pengiriman Luar Pulau - Ekonomi',
            cost: 25000,
            etd: '7-10',
            courier: 'LUAR_PULAU',
            isStandardOption: true,
          ),
          ShippingCost(
            service: 'LUAR_PULAU_REGULER',
            description: 'Pengiriman Luar Pulau - Reguler',
            cost: 35000,
            etd: '5-7',
            courier: 'LUAR_PULAU',
            isStandardOption: true,
          ),
          ShippingCost(
            service: 'LUAR_PULAU_EXPRESS',
            description: 'Pengiriman Luar Pulau - Express',
            cost: 50000,
            etd: '3-5',
            courier: 'LUAR_PULAU',
            isStandardOption: true,
          ),
        ]);
      }
    } else if (_isWithinSameIsland(destinationProvince)) {
      // Dalam pulau yang sama tapi beda provinsi - exclude luar pulau
      filteredOptions = allOptions.where((option) {
        String serviceLower = option.service.toLowerCase();
        String courierLower = option.courier.toLowerCase();

        return !serviceLower.contains('cargo') &&
            !serviceLower.contains('laut') &&
            !courierLower.contains('lion') &&
            !courierLower.contains('sap') &&
            !serviceLower.contains('ekonomi super hemat') &&
            !(serviceLower.contains('oke') && option.etd.contains('7-14')) &&
            !(serviceLower.contains('yes') && option.etd.contains('7-14'));
      }).toList();

      // Jika tidak ada opsi, tambahkan opsi standar antar provinsi dalam pulau
      if (filteredOptions.isEmpty) {
        filteredOptions.add(ShippingCost(
          service: 'ANTAR_PROVINSI',
          description: 'Pengiriman Antar Provinsi',
          cost: 18000,
          etd: '3-5',
          courier: 'ANTAR_PROVINSI',
          isStandardOption: true,
        ));
      }
    } else {
      // Default - semua opsi tersedia
      filteredOptions = allOptions;
    }

    // Urutkan berdasarkan harga (termurah dulu)
    filteredOptions.sort((a, b) => a.cost.compareTo(b.cost));

    return filteredOptions;
  }

  // Fungsi untuk menghitung ongkos kirim dengan filter lokasi
  Future<void> _calculateShippingCosts(Address address) async {
    setState(() {
      isLoadingShipping = true;
      availableShippingOptions.clear();
      selectedShippingOption = null;
      shippingCost = 0;
      destinationProvince = address.provinsi;
    });

    try {
      // Hitung total berat
      final totalWeight = widget.product.weight * widget.product.quantity;

      // Gunakan metode baru dengan fallback lengkap
      final allShippingOptions =
          await RajaOngkirService.getShippingOptionsWithFallback(
        destinationCityName: address.kota,
        destinationProvince: address.provinsi,
        weight: totalWeight,
      );

      // Filter opsi berdasarkan lokasi
      final filteredOptions = _filterShippingOptionsByLocation(
        allShippingOptions,
        address.kota,
        address.provinsi,
      );

      setState(() {
        availableShippingOptions = filteredOptions;
        if (filteredOptions.isNotEmpty) {
          // Pilih opsi termurah sebagai default
          selectedShippingOption = filteredOptions.first;
          shippingCost = selectedShippingOption!.cost.toDouble();
        }
        isLoadingShipping = false;
      });

      // Tentukan pesan berdasarkan lokasi
      String locationMessage;
      if (_isWithinSameCity(address.kota, address.provinsi)) {
        locationMessage = 'Pengiriman dalam kota ${address.kota}';
      } else if (_isWithinSameProvince(address.provinsi)) {
        locationMessage = 'Pengiriman dalam provinsi ${address.provinsi}';
      } else if (_isInterIslandDelivery(address.provinsi)) {
        locationMessage = 'Pengiriman luar pulau ke ${address.provinsi}';
      } else if (_isWithinSameIsland(address.provinsi)) {
        locationMessage =
            'Pengiriman antar provinsi dalam pulau ke ${address.provinsi}';
      } else {
        locationMessage = 'Pengiriman ke ${address.provinsi}';
      }

      // Cek apakah menggunakan RajaOngkir API atau opsi standar
      bool hasApiResults =
          filteredOptions.any((option) => !option.isStandardOption);
      bool hasStandardOptions =
          filteredOptions.any((option) => option.isStandardOption);

      String message;
      if (hasApiResults && hasStandardOptions) {
        message =
            '$locationMessage: ${filteredOptions.length} pilihan (API + Standar)';
      } else if (hasApiResults) {
        message =
            '$locationMessage: ${filteredOptions.length} pilihan dari RajaOngkir';
      } else {
        message = '$locationMessage: Menggunakan tarif standar';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: _isInterIslandDelivery(address.provinsi)
                ? Colors.orange
                : hasApiResults
                    ? Colors.green
                    : Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingShipping = false;
        // Fallback ke opsi standar berdasarkan lokasi
        List<ShippingCost> fallbackOptions = [];

        if (_isWithinSameCity(address.kota, address.provinsi)) {
          fallbackOptions.add(ShippingCost(
            service: 'LOKAL',
            description: 'Pengiriman Lokal',
            cost: 8000,
            etd: '1',
            courier: 'LOKAL',
            isStandardOption: true,
          ));
        } else if (_isWithinSameProvince(address.provinsi)) {
          fallbackOptions.add(ShippingCost(
            service: 'PROVINSI',
            description: 'Pengiriman Dalam Provinsi',
            cost: 12000,
            etd: '2-3',
            courier: 'PROVINSI',
            isStandardOption: true,
          ));
        } else if (_isInterIslandDelivery(address.provinsi)) {
          fallbackOptions.addAll([
            ShippingCost(
              service: 'LUAR_PULAU_EKONOMI',
              description: 'Pengiriman Luar Pulau - Ekonomi',
              cost: 25000,
              etd: '7-10',
              courier: 'LUAR_PULAU',
              isStandardOption: true,
            ),
            ShippingCost(
              service: 'LUAR_PULAU_REGULER',
              description: 'Pengiriman Luar Pulau - Reguler',
              cost: 35000,
              etd: '5-7',
              courier: 'LUAR_PULAU',
              isStandardOption: true,
            ),
          ]);
        } else {
          fallbackOptions = RajaOngkirService.getStandardShippingOptions(
            destinationProvince: address.provinsi,
            weight: widget.product.weight * widget.product.quantity,
          );
        }

        availableShippingOptions = fallbackOptions;
        if (availableShippingOptions.isNotEmpty) {
          selectedShippingOption = availableShippingOptions.first;
          shippingCost = selectedShippingOption!.cost.toDouble();
        } else {
          shippingCost = 15000; // Fallback terakhir
        }
      });

      print('Error calculating shipping: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error menghitung ongkos kirim, menggunakan tarif standar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get totalPayment {
    return (widget.product.price * widget.product.quantity) +
        shippingCost +
        serviceFee;
  }

  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: PaymentMethod.values.map((method) {
            return ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(method.displayName),
              onTap: () {
                setState(() {
                  selectedPaymentMethod = method;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showShippingSelector() {
    if (availableShippingOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pilih alamat terlebih dahulu untuk melihat opsi pengiriman.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Metode Pengiriman',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedAddress != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tujuan: ${selectedAddress!.kota}, ${selectedAddress!.provinsi}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                // Tampilkan info lokasi pengiriman dengan kategori yang lebih detail
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isWithinSameCity(
                            selectedAddress!.kota, selectedAddress!.provinsi)
                        ? Colors.green.shade50
                        : _isWithinSameProvince(selectedAddress!.provinsi)
                            ? Colors.blue.shade50
                            : _isInterIslandDelivery(selectedAddress!.provinsi)
                                ? Colors.orange.shade50
                                : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isWithinSameCity(selectedAddress!.kota,
                                selectedAddress!.provinsi)
                            ? Icons.location_city
                            : _isWithinSameProvince(selectedAddress!.provinsi)
                                ? Icons.map
                                : _isInterIslandDelivery(
                                        selectedAddress!.provinsi)
                                    ? Icons.flight
                                    : Icons.public,
                        size: 16,
                        color: _isWithinSameCity(selectedAddress!.kota,
                                selectedAddress!.provinsi)
                            ? Colors.green
                            : _isWithinSameProvince(selectedAddress!.provinsi)
                                ? Colors.blue
                                : _isInterIslandDelivery(
                                        selectedAddress!.provinsi)
                                    ? Colors.orange
                                    : Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isWithinSameCity(selectedAddress!.kota,
                                selectedAddress!.provinsi)
                            ? 'Pengiriman dalam kota'
                            : _isWithinSameProvince(selectedAddress!.provinsi)
                                ? 'Pengiriman dalam provinsi'
                                : _isInterIslandDelivery(
                                        selectedAddress!.provinsi)
                                    ? 'Pengiriman luar pulau'
                                    : 'Pengiriman antar provinsi',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isWithinSameCity(selectedAddress!.kota,
                                  selectedAddress!.provinsi)
                              ? Colors.green.shade700
                              : _isWithinSameProvince(selectedAddress!.provinsi)
                                  ? Colors.blue.shade700
                                  : _isInterIslandDelivery(
                                          selectedAddress!.provinsi)
                                      ? Colors.orange.shade700
                                      : Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Berat Total: ${widget.product.weight * widget.product.quantity}g',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableShippingOptions.length,
                  itemBuilder: (context, index) {
                    final option = availableShippingOptions[index];
                    final isSelected = selectedShippingOption == option;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          option.isStandardOption
                              ? Icons.local_shipping_outlined
                              : _isInterIslandDelivery(
                                      selectedAddress?.provinsi ?? '')
                                  ? Icons.flight_outlined
                                  : Icons.local_shipping,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Row(
                          children: [
                            Text(
                              option.displayName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (option.isStandardOption) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _isInterIslandDelivery(
                                          selectedAddress?.provinsi ?? '')
                                      ? Colors.orange.shade100
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isInterIslandDelivery(
                                          selectedAddress?.provinsi ?? '')
                                      ? 'LUAR PULAU'
                                      : 'STANDAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _isInterIslandDelivery(
                                            selectedAddress?.provinsi ?? '')
                                        ? Colors.orange.shade700
                                        : Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(option.fullDescription),
                        trailing: Text(
                          'Rp ${formatPrice(option.cost.toDouble())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedShippingOption = option;
                            shippingCost = option.cost.toDouble();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Info section dengan informasi luar pulau
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isInterIslandDelivery(selectedAddress?.provinsi ?? '')
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keterangan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Opsi pengiriman disesuaikan dengan lokasi tujuan',
                      style: TextStyle(fontSize: 11),
                    ),
                    const Text(
                      '• Pengiriman dalam kota: lebih cepat dan murah',
                      style: TextStyle(fontSize: 11),
                    ),
                    const Text(
                      '• Pengiriman dalam provinsi: opsi regional',
                      style: TextStyle(fontSize: 11),
                    ),
                    if (_isInterIslandDelivery(
                        selectedAddress?.provinsi ?? '')) ...[
                      const Text(
                        '• Pengiriman luar pulau: estimasi lebih lama',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                      const Text(
                        '• Tarif luar pulau berlaku untuk pengiriman antar pulau',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ] else ...[
                      const Text(
                        '• Pengiriman antar provinsi: semua opsi tersedia',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createOrder() async {
    if (selectedAddress == null || selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Silakan pilih alamat dan metode pembayaran terlebih dahulu.'),
        ),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login tidak ditemukan. Silakan login kembali.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Tentukan kategori pengiriman dengan kategori luar pulau
      String shippingCategory;
      if (_isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi)) {
        shippingCategory = 'lokal';
      } else if (_isWithinSameProvince(selectedAddress!.provinsi)) {
        shippingCategory = 'provinsi';
      } else if (_isInterIslandDelivery(selectedAddress!.provinsi)) {
        shippingCategory = 'luar_pulau';
      } else {
        shippingCategory = 'antar_provinsi';
      }

      // Buat data order dengan informasi pengiriman yang sudah diperbarui
      final orderData = {
        'user_id': userId,
        'total_harga': totalPayment,
        'alamat_pemesanan':
            '${selectedAddress!.alamatLengkap}, ${selectedAddress!.kecamatan}, '
                '${selectedAddress!.kota}, ${selectedAddress!.provinsi}, ${selectedAddress!.kodePos}',
        'metode_pengiriman': selectedShippingOption?.displayName ?? 'Standar',
        'metode_pembayaran': selectedPaymentMethod!.name.toLowerCase(),
        'ongkos_kirim': shippingCost,
        'kota_tujuan': selectedAddress!.kota,
        'provinsi_tujuan': selectedAddress!.provinsi,
        'kota_tujuan_id':
            destinationCityId, // Bisa null jika menggunakan opsi standar
        'estimasi_pengiriman': selectedShippingOption?.etd ?? '3-7',
        'berat_total': widget.product.weight * widget.product.quantity,
        'is_standard_shipping':
            selectedShippingOption?.isStandardOption ?? true,
        'courier_name': selectedShippingOption?.courier ?? 'STANDAR',
        'service_name': selectedShippingOption?.service ?? 'REGULER',
        'shipping_category':
            shippingCategory, // Tambahan info kategori pengiriman
        'is_same_city':
            _isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi),
        'is_same_province': _isWithinSameProvince(selectedAddress!.provinsi),
        'is_inter_island': _isInterIslandDelivery(selectedAddress!.provinsi),
        'is_same_island': _isWithinSameIsland(selectedAddress!.provinsi),
        'items': [
          {
            'product_id': widget.product.id,
            'kuantitas': widget.product.quantity,
            'harga': widget.product.price,
          }
        ],
      };

      final response = await http.post(
        Uri.parse('http://localhost/umkm_batik/API/create_transaction.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pesanan berhasil dibuat!")),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  paymentMethod: selectedPaymentMethod!,
                  totalPayment: totalPayment,
                  orderId: responseData['data']['order_id'] ?? "0000000001",
                ),
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${responseData['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: HTTP ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Alamat Section
                  _buildSection(
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PilihAlamatPage()),
                        );
                        if (result != null && result is Address) {
                          setState(() {
                            selectedAddress = result;
                          });
                          // Hitung ongkos kirim berdasarkan alamat lengkap
                          await _calculateShippingCosts(result);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedAddress?.namaLengkap ??
                                        "Pilih Alamat",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  selectedAddress != null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                selectedAddress!.alamatLengkap),
                                            Text(
                                              "${selectedAddress!.kecamatan}, ${selectedAddress!.kota}, ${selectedAddress!.provinsi}",
                                            ),
                                            Text(
                                                "Kode Pos: ${selectedAddress!.kodePos}"),
                                            Text(
                                                "No. HP: ${selectedAddress!.nomorHp}"),
                                            // Tampilkan info kategori pengiriman dengan kategori luar pulau
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _isWithinSameCity(
                                                        selectedAddress!.kota,
                                                        selectedAddress!
                                                            .provinsi)
                                                    ? Colors.green.shade100
                                                    : _isWithinSameProvince(
                                                            selectedAddress!
                                                                .provinsi)
                                                        ? Colors.blue.shade100
                                                        : _isInterIslandDelivery(
                                                                selectedAddress!
                                                                    .provinsi)
                                                            ? Colors
                                                                .orange.shade100
                                                            : Colors.purple
                                                                .shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _isWithinSameCity(
                                                            selectedAddress!
                                                                .kota,
                                                            selectedAddress!
                                                                .provinsi)
                                                        ? Icons.location_city
                                                        : _isWithinSameProvince(
                                                                selectedAddress!
                                                                    .provinsi)
                                                            ? Icons.map
                                                            : _isInterIslandDelivery(
                                                                    selectedAddress!
                                                                        .provinsi)
                                                                ? Icons.flight
                                                                : Icons.public,
                                                    size: 14,
                                                    color: _isWithinSameCity(
                                                            selectedAddress!
                                                                .kota,
                                                            selectedAddress!
                                                                .provinsi)
                                                        ? Colors.green.shade700
                                                        : _isWithinSameProvince(
                                                                selectedAddress!
                                                                    .provinsi)
                                                            ? Colors
                                                                .blue.shade700
                                                            : _isInterIslandDelivery(
                                                                    selectedAddress!
                                                                        .provinsi)
                                                                ? Colors.orange
                                                                    .shade700
                                                                : Colors.purple
                                                                    .shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _isWithinSameCity(
                                                            selectedAddress!
                                                                .kota,
                                                            selectedAddress!
                                                                .provinsi)
                                                        ? 'Pengiriman Lokal'
                                                        : _isWithinSameProvince(
                                                                selectedAddress!
                                                                    .provinsi)
                                                            ? 'Dalam Provinsi'
                                                            : _isInterIslandDelivery(
                                                                    selectedAddress!
                                                                        .provinsi)
                                                                ? 'Luar Pulau'
                                                                : 'Antar Provinsi',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: _isWithinSameCity(
                                                              selectedAddress!
                                                                  .kota,
                                                              selectedAddress!
                                                                  .provinsi)
                                                          ? Colors
                                                              .green.shade700
                                                          : _isWithinSameProvince(
                                                                  selectedAddress!
                                                                      .provinsi)
                                                              ? Colors
                                                                  .blue.shade700
                                                              : _isInterIslandDelivery(
                                                                      selectedAddress!
                                                                          .provinsi)
                                                                  ? Colors
                                                                      .orange
                                                                      .shade700
                                                                  : Colors
                                                                      .purple
                                                                      .shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Tap untuk memilih alamat pengiriman",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product Section
                  _buildSection(
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: widget.product.image != null &&
                                  widget.product.image!.isNotEmpty
                              ? Image.memory(
                                  widget.product.image!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text("${widget.product.quantity}x"),
                              Text(
                                  "Berat: ${widget.product.weight * widget.product.quantity}g"),
                              Text(
                                "Rp ${formatPrice(widget.product.price)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Shipping Section dengan sistem terbaru dan info luar pulau
                  _buildSection(
                    child: InkWell(
                      onTap: _showShippingSelector,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(isLoadingShipping
                                ? "Menghitung ongkos kirim..."
                                : "Informasi Pengiriman"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedShippingOption != null) ...[
                                  Row(
                                    children: [
                                      Text(selectedShippingOption!.displayName),
                                      if (selectedShippingOption!
                                          .isStandardOption) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _isInterIslandDelivery(
                                                    selectedAddress?.provinsi ??
                                                        '')
                                                ? Colors.orange.shade100
                                                : Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            _isInterIslandDelivery(
                                                    selectedAddress?.provinsi ??
                                                        '')
                                                ? 'LUAR PULAU'
                                                : 'STANDAR',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: _isInterIslandDelivery(
                                                      selectedAddress
                                                              ?.provinsi ??
                                                          '')
                                                  ? Colors.orange.shade700
                                                  : Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(selectedShippingOption!.fullDescription),
                                  if (_isInterIslandDelivery(
                                      selectedAddress?.provinsi ?? '')) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 14,
                                            color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pengiriman luar pulau membutuhkan waktu lebih lama',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ] else if (!isLoadingShipping &&
                                    selectedAddress != null) ...[
                                  const Text(
                                      "Tap untuk memilih metode pengiriman"),
                                ] else if (!isLoadingShipping) ...[
                                  const Text(
                                      "Pilih alamat untuk melihat opsi pengiriman"),
                                ],
                                if (selectedAddress != null &&
                                    !isLoadingShipping) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tujuan: ${selectedAddress!.kota}, ${selectedAddress!.provinsi}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isInterIslandDelivery(
                                              selectedAddress!.provinsi)
                                          ? Colors.orange
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isLoadingShipping
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text("Rp ${formatPrice(shippingCost)}"),
                            leading: Icon(
                              _isInterIslandDelivery(
                                      selectedAddress?.provinsi ?? '')
                                  ? Icons.flight
                                  : Icons.local_shipping,
                              color: _isInterIslandDelivery(
                                      selectedAddress?.provinsi ?? '')
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                          ),
                          if (availableShippingOptions.length > 1) ...[
                            Row(
                              children: [
                                Text(
                                  "${availableShippingOptions.length} opsi pengiriman tersedia",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isInterIslandDelivery(
                                            selectedAddress?.provinsi ?? '')
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                if (availableShippingOptions
                                        .any((opt) => opt.isStandardOption) &&
                                    availableShippingOptions.any(
                                        (opt) => !opt.isStandardOption)) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isInterIslandDelivery(
                                              selectedAddress?.provinsi ?? '')
                                          ? Colors.orange.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _isInterIslandDelivery(
                                              selectedAddress?.provinsi ?? '')
                                          ? 'LUAR PULAU + API'
                                          : 'API + STANDAR',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: _isInterIslandDelivery(
                                                selectedAddress?.provinsi ?? '')
                                            ? Colors.orange.shade700
                                            : Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Method Section
                  _buildSection(
                    child: InkWell(
                      onTap: () => _showPaymentMethodSelector(),
                      child: ListTile(
                        title: const Text("Metode Pembayaran"),
                        leading: const Icon(Icons.payment, color: Colors.blue),
                        subtitle: Text(
                          selectedPaymentMethod?.displayName ??
                              "Pilih metode pembayaran",
                          style: TextStyle(
                            color: selectedPaymentMethod != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Summary Section
                  _buildSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Rincian Pembayaran",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                        const SizedBox(height: 8),
                        _RowText("Subtotal untuk produk",
                            "Rp ${formatPrice(widget.product.price * widget.product.quantity)}"),
                        _RowText("Subtotal untuk pengiriman",
                            "Rp ${formatPrice(shippingCost)}"),
                        if (selectedShippingOption != null)
                          _RowText("Estimasi pengiriman",
                              "${selectedShippingOption!.etd} hari"),
                        if (selectedShippingOption?.isStandardOption == true)
                          _RowText(
                              "Jenis tarif",
                              _isInterIslandDelivery(
                                      selectedAddress?.provinsi ?? '')
                                  ? "Standar Luar Pulau"
                                  : "Standar Internal"),
                        if (_isInterIslandDelivery(
                            selectedAddress?.provinsi ?? ''))
                          _RowText("Kategori", "Pengiriman Luar Pulau"),
                        _RowText(
                            "Biaya layanan", "Rp ${formatPrice(serviceFee)}"),
                        const Divider(),
                        _RowText("Total Pembayaran",
                            "Rp ${formatPrice(totalPayment)}"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total : Rp ${formatPrice(totalPayment)}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isInterIslandDelivery(selectedAddress?.provinsi ?? ''))
                  Text(
                    "Termasuk tarif luar pulau",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: isLoading ||
                      isLoadingShipping ||
                      userId == null ||
                      (selectedAddress == null || selectedPaymentMethod == null)
                  ? null
                  : _createOrder,
              child: const Text(
                "Buat Pesanan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _RowText extends StatelessWidget {
  final String left;
  final String right;

  const _RowText(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left), Text(right)],
      ),
    );
  }
}
