import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/payment_method.dart';
import 'dart:typed_data';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // Add this dependency to pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'payment_page.dart';
import 'pilih_alamat_page.dart';

// Model class for product data
class ProductItem {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final Uint8List? image;
  final String imageBase64;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    required this.imageBase64,
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
  // Variable to store selected address
  Address? selectedAddress;
  PaymentMethod? selectedPaymentMethod;
  bool isLoading = false;
  int? userId; // Added to store current user ID

  // Shipping cost
  final double shippingCost = 15000;

  // Service fee
  final double serviceFee = 4000;

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load user ID when page initializes
  }

  // Method to load user ID from SharedPreferences
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
        // You might want to navigate back to login page here
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  // Calculate total payment
  double get totalPayment {
    return (widget.product.price * widget.product.quantity) +
        shippingCost +
        serviceFee;
  }

  // Format price to Indonesian Rupiah format
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

  // Function to create order via API
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

    // Check if userId is available
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
      // Prepare order data according to API requirements
      final orderData = {
        'user_id': userId, // Use the logged-in user's ID
        'total_harga': totalPayment,
        'alamat_pemesanan':
            '${selectedAddress!.alamatLengkap}, ${selectedAddress!.kecamatan}, '
                '${selectedAddress!.kota}, ${selectedAddress!.provinsi}, ${selectedAddress!.kodePos}',
        'metode_pengiriman': 'JNE', // Currently hardcoded in UI
        'metode_pembayaran': selectedPaymentMethod!.name.toLowerCase(),
        'items': [
          {
            'product_id': widget.product.id,
            'kuantitas': widget.product.quantity,
            'harga': widget.product.price,
          }
        ],
      };

      // Make API call
      final response = await http.post(
        Uri.parse(
            'http://localhost/umkm_batik/API/create_transaction.php'), // Replace with actual endpoint
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
          // Transaction successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pesanan berhasil dibuat!")),
          );

          // Navigate to payment page
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
          // Error occurred
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${responseData['message']}")),
          );
        }
      } else {
        // HTTP error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: HTTP ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Exception occurred
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF), // Light blue background
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
                  _buildSection(
                    child: Row(
                      children: [
                        // Product image
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
                  _buildSection(
                    child: const ListTile(
                      title: Text("Informasi Pengiriman"),
                      trailing: Text("Rp 15.000"),
                      leading: Radio(
                        value: true,
                        groupValue: true,
                        onChanged: null,
                      ),
                      subtitle: Text("JNE"),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        _RowText(
                            "Biaya layanan", "Rp ${formatPrice(serviceFee)}"),
                        const Divider(),
                        _RowText("Total Pembayaran",
                            "Rp ${formatPrice(totalPayment)}"),
                      ],
                    ),
                  ),
                  const SizedBox(
                      height: 100), // Space so the button doesn't cover content
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
            Text(
              "Total : Rp ${formatPrice(totalPayment)}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
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
