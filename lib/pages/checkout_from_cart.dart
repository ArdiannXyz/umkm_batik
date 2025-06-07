import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/payment_method.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'payment_page.dart';
import 'pilih_alamat_page.dart';
import '../models/rajaongkir.dart';
import '../services/rajaongkir_service.dart';
import '../models/cartitem.dart';
import '../models/Address.dart';
import '../models/ShippinCost.dart';

class CheckoutCart extends StatefulWidget {
  final List<CartItem> cartItems;
  final int userId;
  
  const CheckoutCart({super.key, required this.cartItems, required this.userId});
  
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutCart> {
  Address? selectedAddress;
  PaymentMethod? selectedPaymentMethod;
  bool isLoading = false;
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
  }


  int get totalWeight {
    return widget.cartItems.fold(0, (sum, item) => sum + (item.weight * item.quantity));
  }

  double get totalItemsPrice {
    return widget.cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get serviceFee {
    return totalWeight > 1000 ? baseServiceFee * 2 : baseServiceFee;
  }

  String get serviceFeeDescription {
    return totalWeight > 1000 ? "Biaya layanan (berat > 1kg: 2x lipat)" : "Biaya layanan";
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
Widget _buildProductImage(CartItem item) {
  final imageUrl = item.productImage;
  
  if (imageUrl.isEmpty) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
  
  String fullImageUrl = imageUrl;
  if (!imageUrl.startsWith('http')) {

    fullImageUrl = 'http://192.168.1.5/umkm_batik/API/get_main_product_images.php?id=${item.product.images.isNotEmpty ? item.product.images.first.id : 0}';
  }
  
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      fullImageUrl,
      fit: BoxFit.cover,
      width: 60,
      height: 60,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $fullImageUrl');
        print('Error details: $error');
        
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
              Text(
                'No Image',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    ),
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

      // Add standard options
      final standardOptions = _getStandardShippingOptions(address.kota, address.provinsi);
      allOptions.addAll(standardOptions);

      // Filter by location
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

      // Show informative message
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

  double get totalPayment => totalItemsPrice + shippingCost + serviceFee;
  
  String formatPrice(double price) => 
      price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
        (Match m) => '${m[1]}.'
      );
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
                          fontSize: 12,
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
                  'Berat Total: ${totalWeight}g',
                  style: TextStyle(
                    fontSize: 12, 
                    color: totalWeight > 1000 
                        ? Colors.orange.shade700 
                        : Colors.grey,
                    fontWeight: totalWeight > 1000 
                        ? FontWeight.bold 
                        : FontWeight.normal
                  )
                ),
                if (totalWeight > 1000) ...[
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
                            fontSize: 10, 
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
      const SnackBar(content: Text('Silakan pilih alamat dan metode pembayaran terlebih dahulu.'))
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

    try {
      String shippingCategory;
      if (_isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi)) {
        shippingCategory = 'lokal';
      } else if (_isWithinSameProvince(selectedAddress!.provinsi)) {
        shippingCategory = 'provinsi';
      } else if (_isInterIslandDelivery(selectedAddress!.provinsi)) {
        shippingCategory = 'luar pulau';
      } else {
        shippingCategory = 'antar provinsi';
      }

    final items = widget.cartItems.map((item) => {
      'product_id': item.productId,
      'kuantitas': item.quantity,
      'harga': item.price.toDouble(), // Ensure double
      'nama_produk': item.nama, // Ensure not null
      'berat': item.weight > 0 ? item.weight : 100, // Fix zero weight issue
    }).toList();
    

      final orderData = {
        'user_id': widget.userId,
        'total_harga': totalPayment,
        'alamat_pemesanan': '${selectedAddress!.alamatLengkap}, ${selectedAddress!.kecamatan}, ${selectedAddress!.kota}, ${selectedAddress!.provinsi}, ${selectedAddress!.kodePos}',
        'metode_pengiriman': selectedShippingOption?.displayName ?? 'Standar',
        'metode_pembayaran': selectedPaymentMethod!.name.toLowerCase(),
        'ongkos_kirim': shippingCost,
        'kota_tujuan': selectedAddress!.kota,
        'provinsi_tujuan': selectedAddress!.provinsi,
        'kota_tujuan_id': destinationCity?.cityId,
        'estimasi_pengiriman': selectedShippingOption?.etd ?? '3-7',
        'berat_total': totalWeight,
        'is_standard_shipping': selectedShippingOption?.isStandardOption ?? true,
        'courier_name': selectedShippingOption?.courier ?? 'STANDAR',
        'service_name': selectedShippingOption?.service ?? 'REGULER',
        'shipping_category': shippingCategory,
        'is_same_city': _isWithinSameCity(selectedAddress!.kota, selectedAddress!.provinsi),
        'is_same_province': _isWithinSameProvince(selectedAddress!.provinsi),
        'is_inter_island': _isInterIslandDelivery(selectedAddress!.provinsi),
        'is_same_island': _isWithinSameIsland(selectedAddress!.provinsi),
        'biaya_layanan': serviceFee,
        'subtotal_items': totalItemsPrice,
        'jumlah_items': widget.cartItems.length,
        'items': items,
      };

      final response = await http.post(
        Uri.parse('http://192.168.1.5/umkm_batik/API/create_transaction.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final orderId = responseData['data']['order_id']?.toString() ?? "0000000001";
          _showOrderSuccessAlert(orderId);

  
          Future.delayed(const Duration(milliseconds: 5000), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  paymentMethod: selectedPaymentMethod!,
                  totalPayment: totalPayment,
                  orderId: responseData['data']['order_id']?.toString() ?? "0000000001",
                ),
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${responseData['message'] ?? 'Unknown error'}"),
              backgroundColor: Colors.red,
            )
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: HTTP ${response.statusCode}"),
            backgroundColor: Colors.red,
          )
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Exception in _createOrder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        )
      );
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
                  // Address Section
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(selectedAddress!.alamatLengkap),
                                            Text('${selectedAddress!.kecamatan}, ${selectedAddress!.kota}'),
                                            Text('${selectedAddress!.provinsi}, ${selectedAddress!.kodePos}'),
                                            Text(selectedAddress!.nomorHp),
                                          ],
                                        )
                                      : const Text("Pilih alamat pengiriman", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  _buildSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesanan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...widget.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: _buildProductImage(item),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nama,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item.quantity} x Rp ${formatPrice(item.price)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      'Berat: ${item.totalWeight}g',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${formatPrice(item.price * item.quantity)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Shipping Section
                  _buildSection(
                    child: InkWell(
                      onTap: _showShippingSelector,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Colors.blue),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Metode Pengiriman',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isLoadingShipping)
                                    const Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Menghitung ongkos kirim...', style: TextStyle(color: Colors.grey)),
                                      ],
                                    )
                                  else if (selectedShippingOption != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(selectedShippingOption!.displayName),
                                        Text(
                                          selectedShippingOption!.fullDescription,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                        Text(
                                          'Rp ${formatPrice(selectedShippingOption!.cost.toDouble())}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                      ],
                                    )
                                  else
                                    const Text(
                                      'Pilih alamat terlebih dahulu',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment Method Section
                  _buildSection(
                    child: InkWell(
                      onTap: _showPaymentMethodSelector,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.payment, color: Colors.blue),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Metode Pembayaran',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedPaymentMethod?.displayName ?? "Pilih metode pembayaran",
                                    style: TextStyle(
                                      color: selectedPaymentMethod != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary Section
                  _buildSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Pembayaran',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Subtotal (${widget.cartItems.length} item)', 'Rp ${formatPrice(totalItemsPrice)}'),
                        _buildSummaryRow('Ongkos Kirim', 'Rp ${formatPrice(shippingCost)}'),
                        _buildSummaryRow(serviceFeeDescription, 'Rp ${formatPrice(serviceFee)}'),
                        const Divider(),
                        _buildSummaryRow(
                          'Total Pembayaran',
                          'Rp ${formatPrice(totalPayment)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 0), // Space for bottom checkout button
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      
      // Bottom Checkout Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${formatPrice(totalPayment)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (selectedAddress != null && selectedPaymentMethod != null && !isLoading)
                    ? _createOrder
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isLoading ? 'Memproses...' : 'Buat Pesanan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}