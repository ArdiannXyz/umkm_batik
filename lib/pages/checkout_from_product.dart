
import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/payment_method.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';
import 'pilih_alamat_page.dart';
import '../models/rajaongkir.dart';
import '../models/checkout_model.dart';
import '../services/rajaongkir_service.dart';
import '../models/Address.dart';
import '../models/ShippinCost.dart';
import '../services/payment_service.dart';

class CheckoutPage extends StatefulWidget {
  final ProductItem product;
  
  const CheckoutPage({super.key, required this.product});
  @override
  
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Address? selectedAddress;
  PaymentMethod? selectedPaymentMethod;
  bool isLoading = false;
  int? userId;
  double shippingCost = 0;
  List<ShippingCost> availableShippingOptions = [];
  ShippingCost? selectedShippingOption;
  bool isLoadingShipping = false;
  RajaOngkirCity? destinationCity;
  String? destinationProvince;
  final String originProvince = "Jawa Timur";
  final String originCity = "Bondowoso";
  final double baseServiceFee = 4000;
  final Set<String> javaProvinces = {'jawa tengah', 'jawa timur', 'jawa barat', 'dki jakarta', 'di yogyakarta', 'yogyakarta', 'banten'};

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  double get serviceFee {
    int totalWeight = widget.product.weight * widget.product.quantity;
    return totalWeight > 1000 ? baseServiceFee * 2 : baseServiceFee;
  }

  String get serviceFeeDescription {
    int totalWeight = widget.product.weight * widget.product.quantity;
    return totalWeight > 1000 ? "Biaya layanan (berat > 1kg: 2x lipat)" : "Biaya layanan";
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getInt('user_id');
      });
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi login tidak ditemukan. Silakan login kembali.'))
        );
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  bool _isWithinSameProvince(String destinationProvince) => 
      destinationProvince.toLowerCase().trim() == originProvince.toLowerCase().trim();
  
  bool _isWithinSameCity(String destinationCity, String destinationProvince) => 
      _isWithinSameProvince(destinationProvince) && 
      destinationCity.toLowerCase().trim() == originCity.toLowerCase().trim();
  
  bool _isWithinSameIsland(String destinationProvince) {
    final destProvinceLower = destinationProvince.toLowerCase().trim();
    final originProvinceLower = originProvince.toLowerCase().trim();
    return javaProvinces.contains(destProvinceLower) && javaProvinces.contains(originProvinceLower);
  }
  
  bool _isInterIslandDelivery(String destinationProvince) {
    final destProvinceLower = destinationProvince.toLowerCase().trim();
    final originProvinceLower = originProvince.toLowerCase().trim();
    return javaProvinces.contains(originProvinceLower) && !javaProvinces.contains(destProvinceLower);
  }

  List<ShippingCost> _getStandardShippingOptions(String destinationCity, String destinationProvince) {
    List<ShippingCost> standardOptions = [];
    
    if (_isWithinSameCity(destinationCity, destinationProvince)) {
      standardOptions.add(ShippingCost(
        service: 'Lokal', 
        description: 'Pengiriman Lokal', 
        cost: 8000, 
        etd: '1', 
        courier: '', 
        isStandardOption: true
      ));
    } else if (_isWithinSameProvince(destinationProvince)) {
      standardOptions.add(ShippingCost(
        service: 'Provinsi', 
        description: 'Pengiriman Dalam Provinsi', 
        cost: 12000, 
        etd: '2-3', 
        courier: '', 
        isStandardOption: true
      ));
    } else if (_isInterIslandDelivery(destinationProvince)) {
      standardOptions.addAll([
        ShippingCost(
          service: 'Ekonomi', 
          description: 'Pengiriman Luar Pulau', 
          cost: 25000, 
          etd: '7-10', 
          courier: '', 
          isStandardOption: true
        ),
        ShippingCost(
          service: 'Reguler', 
          description: 'Pengiriman Luar Pulau', 
          cost: 35000, 
          etd: '5-7', 
          courier: '', 
          isStandardOption: true
        ),
        ShippingCost(
          service: 'Express', 
          description: 'Pengiriman Luar Pulau', 
          cost: 50000, 
          etd: '3-5', 
          courier: '', 
          isStandardOption: true
        ),
      ]);
    } else if (_isWithinSameIsland(destinationProvince)) {
      standardOptions.add(ShippingCost(
        service: 'Provinsi', 
        description: 'Pengiriman Antar Provinsi', 
        cost: 18000, 
        etd: '3-5', 
        courier: '', 
        isStandardOption: true
      ));
    }
    
    return standardOptions;
  }

  List<ShippingCost> _filterShippingOptionsByLocation(
    List<ShippingCost> allOptions, 
    String destinationCity, 
    String destinationProvince
  ) {
    List<ShippingCost> filteredOptions = [];
    
    if (_isWithinSameCity(destinationCity, destinationProvince)) {
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
    } else if (_isWithinSameProvince(destinationProvince)) {
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
    } else if (_isInterIslandDelivery(destinationProvince)) {
      filteredOptions = allOptions.where((option) {
        String serviceLower = option.service.toLowerCase();
        String courierLower = option.courier.toLowerCase();
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
    } else if (_isWithinSameIsland(destinationProvince)) {
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
    } else {
      filteredOptions = allOptions;
    }
    
    filteredOptions.sort((a, b) => a.cost.compareTo(b.cost));
    return filteredOptions;
  }
  void _showOrderSuccessAlert(String orderId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.blue,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan Berhasil Dibuat!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Order ID: $orderId',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Total: Rp ${formatPrice(totalPayment)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Silakan lanjutkan ke pembayaran',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to payment page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(
                      paymentMethod: selectedPaymentMethod!,
                      totalPayment: totalPayment,
                      orderId: orderId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lanjut ke Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    },
  );
}
  Future<void> _calculateShippingCosts(Address address) async {
    setState(() {
      isLoadingShipping = true;
      availableShippingOptions.clear();
      selectedShippingOption = null;
      shippingCost = 0;
      destinationProvince = address.provinsi;
      destinationCity = null;
    });

    try {
      final totalWeight = widget.product.weight * widget.product.quantity;
      
      final shippingResult = await RajaOngkirService.getShippingCostsByAddress(
        cityName: address.kota,
        provinceName: address.provinsi,
        weight: totalWeight,
        preferredCouriers: ['jne', 'pos', 'tiki', 'jnt', 'sicepat', 'anteraja'],
      );

      List<ShippingCost> allOptions = [];
      
      if (shippingResult['success'] == true) {
        destinationCity = shippingResult['selectedCity'];
        final apiOptions = List<ShippingCost>.from(shippingResult['shippingOptions']);
        allOptions.addAll(apiOptions);
        
        print('Got ${apiOptions.length} options from RajaOngkir API');
      } else {
        print('Failed to get API data: ${shippingResult['message']}');
      }

      final standardOptions = _getStandardShippingOptions(address.kota, address.provinsi);
      allOptions.addAll(standardOptions);

      final filteredOptions = _filterShippingOptionsByLocation(allOptions, address.kota, address.provinsi);
      
      if (filteredOptions.isEmpty) {
        final fallbackOptions = _getStandardShippingOptions(address.kota, address.provinsi);
        filteredOptions.addAll(fallbackOptions);
      }
      
      setState(() {
        availableShippingOptions = filteredOptions;
        if (filteredOptions.isNotEmpty) {
          selectedShippingOption = filteredOptions.first;
          shippingCost = selectedShippingOption!.cost.toDouble();
        }
        isLoadingShipping = false;
      });

      String locationMessage;
      if (_isWithinSameCity(address.kota, address.provinsi)) {
        locationMessage = 'Pengiriman dalam kota ${address.kota}';
      } else if (_isWithinSameProvince(address.provinsi)) {
        locationMessage = 'Pengiriman dalam provinsi ${address.provinsi}';
      } else if (_isInterIslandDelivery(address.provinsi)) {
        locationMessage = 'Pengiriman luar pulau ke ${address.provinsi}';
      } else if (_isWithinSameIsland(address.provinsi)) {
        locationMessage = 'Pengiriman antar provinsi dalam pulau ke ${address.provinsi}';
      } else {
        locationMessage = 'Pengiriman ke ${address.provinsi}';
      }

            bool hasApiResults = filteredOptions.any((option) => !option.isStandardOption);
      bool hasStandardOptions = filteredOptions.any((option) => option.isStandardOption);
      
      String message;
      Color messageColor;
      
      if (shippingResult['success'] == true && hasApiResults) {
        if (hasStandardOptions) {
          message = '$locationMessage: ${filteredOptions.length} pilihan (API + Standar)';
          messageColor = Colors.green;
        } else {
          message = '$locationMessage: ${filteredOptions.length} pilihan dari RajaOngkir';
          messageColor = Colors.green;
        }
      } else {
        message = '$locationMessage: Menggunakan tarif standar';
        messageColor = Colors.blue;
      }

      if (_isInterIslandDelivery(address.provinsi)) {
        messageColor = Colors.orange;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: messageColor,
          duration: const Duration(seconds: 3),
        ));
      }

    } catch (e) {
      setState(() {
        isLoadingShipping = false;
        
        final fallbackOptions = _getStandardShippingOptions(address.kota, address.provinsi);
        
        availableShippingOptions = fallbackOptions;
        if (availableShippingOptions.isNotEmpty) {
          selectedShippingOption = availableShippingOptions.first;
          shippingCost = selectedShippingOption!.cost.toDouble();
        } else {
          shippingCost = 15000;
        }
      });

      print('Error calculating shipping: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error menghitung ongkos kirim, menggunakan tarif standar'), 
            backgroundColor: Colors.red
          )
        );
      }
    }
  }


  double get totalPayment => (widget.product.price * widget.product.quantity) + shippingCost + serviceFee;
  
  String formatPrice(double price) => 
      price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
        (Match m) => '${m[1]}.'
      );

  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
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
        const SnackBar(content: Text('Pilih alamat terlebih dahulu untuk melihat opsi pengiriman.'))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Metode Pengiriman', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              if (selectedAddress != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tujuan: ${selectedAddress!.kota}, ${selectedAddress!.provinsi}', 
                  style: const TextStyle(fontSize: 14, color: Colors.grey)
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi) 
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
                        _isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi) 
                            ? Icons.location_city
                            : _isWithinSameProvince(selectedAddress!.provinsi) 
                                ? Icons.map
                                : _isInterIslandDelivery(selectedAddress!.provinsi) 
                                    ? Icons.flight 
                                    : Icons.public,
                        size: 16,
                        color: _isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi) 
                            ? Colors.green
                            : _isWithinSameProvince(selectedAddress!.provinsi) 
                                ? Colors.blue
                                : _isInterIslandDelivery(selectedAddress!.provinsi) 
                                    ? Colors.orange 
                                    : Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi) 
                            ? 'Pengiriman dalam kota'
                            : _isWithinSameProvince(selectedAddress!.provinsi) 
                                ? 'Pengiriman dalam provinsi'
                                : _isInterIslandDelivery(selectedAddress!.provinsi) 
                                    ? 'Pengiriman luar pulau' 
                                    : 'Pengiriman antar provinsi',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi) 
                              ? Colors.green.shade700
                              : _isWithinSameProvince(selectedAddress!.provinsi) 
                                  ? Colors.blue.shade700
                                  : _isInterIslandDelivery(selectedAddress!.provinsi) 
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
                  style: TextStyle(
                    fontSize: 8, 
                    color: widget.product.weight * widget.product.quantity > 1000 
                        ? Colors.orange.shade700 
                        : Colors.grey,
                    fontWeight: widget.product.weight * widget.product.quantity > 1000 
                        ? FontWeight.bold 
                        : FontWeight.normal
                  )
                ),
                if (widget.product.weight * widget.product.quantity > 1000) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50, 
                      borderRadius: BorderRadius.circular(4), 
                      border: Border.all(color: Colors.orange.shade200)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Berat > 1kg: Biaya layanan 2x lipat', 
                          style: TextStyle(
                            fontSize: 8, 
                            color: Colors.orange.shade700, 
                            fontWeight: FontWeight.w500
                          )
                        ),
                      ],
                    ),
                  ),
                ],
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
                          color: isSelected ? Colors.blue : Colors.grey.shade300, 
                          width: isSelected ? 2 : 1
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          option.isStandardOption 
                              ? Icons.local_shipping_outlined 
                              : _isInterIslandDelivery(selectedAddress?.provinsi ?? '') 
                                  ? Icons.flight_outlined 
                                  : Icons.local_shipping,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Row(
                          children: [
                            Text(
                              option.displayName, 
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              )
                            ),
                            if (option.isStandardOption) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isInterIslandDelivery(selectedAddress?.provinsi ?? '') 
                                      ? Colors.orange.shade100 
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isInterIslandDelivery(selectedAddress?.provinsi ?? '') 
                                      ? 'LUAR PULAU' 
                                      : 'STANDAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _isInterIslandDelivery(selectedAddress?.provinsi ?? '') 
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
                            color: isSelected ? Colors.blue : Colors.black
                          )
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
            ],
          ),
        );
      },
    );
  }

  Future<void> _createOrder() async {
  if (selectedAddress == null || selectedPaymentMethod == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silakan pilih alamat dan metode pembayaran terlebih dahulu.')),
    );
    return;
  }

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesi login tidak ditemukan. Silakan login kembali.')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  final result = await PaymentService.createOrder(
    context: context,
    userId: userId.toString(),
    totalPayment: totalPayment.toInt(),
    selectedAddress: selectedAddress!,
    selectedPaymentMethod: selectedPaymentMethod!,
    selectedShippingOption: selectedShippingOption,
    shippingCost: shippingCost.toInt(),
    destinationCity: destinationCity,
    serviceFee: serviceFee.toInt(),
    product: widget.product,
    isWithinSameCity: _isWithinSameCity,
    isWithinSameProvince: _isWithinSameProvince,
    isInterIslandDelivery: _isInterIslandDelivery,
    isWithinSameIsland: _isWithinSameIsland,
  );

  setState(() {
    isLoading = false;
  });

  if (result['statusCode'] == 200 && result['body']?['success'] == true) {
    final orderId = result['body']['data']['order_id']?.toString() ?? "0000000001";
    _showOrderSuccessAlert(orderId);
    Future.delayed(const Duration(milliseconds: 5000), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            paymentMethod: selectedPaymentMethod!,
            totalPayment: totalPayment,
            orderId: orderId,
          ),
        ),
      );
    });
  } else {
    final errorMessage = result['body']?['message'] ?? result['error'] ?? "Terjadi kesalahan.";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $errorMessage")));
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PilihAlamatPage()));
                        if (result != null && result is Address) {
                          setState(() {
                            selectedAddress = result;
                          });
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
                                  Text(selectedAddress?.namaLengkap ?? "Pilih Alamat", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                                                ? Icons.local_shipping
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
                                                      fontSize: 8,
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
                                  fontSize: 12,
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
                                : "Metode Pengiriman"),
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
                                                        'EKONOMI')
                                                ? 'LUAR PULAU'
                                                : 'STANDAR',
                                            style: TextStyle(
                                              fontSize: 8,
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
                                      fontSize: 8,
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
                                  ? Icons.local_shipping
                                  : Icons.local_shipping,
                              color: _isInterIslandDelivery(
                                      selectedAddress?.provinsi ?? '')
                                  ? Colors.blue
                                  : Colors.blue,
                            ),
                          ),
                          if (availableShippingOptions.length > 1) ...[
                            Row(
                              children: [
                                Text(
                                  "${availableShippingOptions.length} opsi pengiriman tersedia",
                                  style: TextStyle(
                                    fontSize: 10,
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
                                        fontSize: 8,
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
                  const SizedBox(height: 0),
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
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isInterIslandDelivery(selectedAddress?.provinsi ?? ''))
                  Text(
                    "Termasuk tarif luar pulau",
                    style: TextStyle(
                      fontSize: 10,
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
