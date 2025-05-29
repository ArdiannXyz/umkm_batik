import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart'; // Import the payment page
import 'payment_method.dart'; // Import the payment method enum

class DetailPesananPage extends StatefulWidget {
  final String? orderId;

  const DetailPesananPage({super.key, this.orderId});

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  bool isLoading = true;
  Map<String, dynamic>? orderDetail;
  String? userId;
  final String baseUrl = 'http://192.168.1.6/umkm_batik/API';

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userIdString;

      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userIdString = userIdInt.toString();
        }
      } catch (_) {}

      if (userIdString == null) {
        userIdString = prefs.getString('user_id');
      }

      if (userIdString == null) {
        try {
          double? userIdDouble = prefs.getDouble('user_id');
          if (userIdDouble != null) {
            userIdString = userIdDouble.toInt().toString();
          }
        } catch (_) {}
      }

      setState(() {
        userId = userIdString;
      });

      if (userId != null && widget.orderId != null) {
        await _fetchOrderDetail();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error _getUserId: $e');
    }
  }

  String _getFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return '';

    if (relativeUrl.startsWith('http')) return relativeUrl;

    // Handle both get_product_images.php and get_main_product_images.php
    if (relativeUrl.contains('get_product_images.php') ||
        relativeUrl.contains('get_main_product_images.php')) {
      final uri = Uri.tryParse(relativeUrl);
      if (uri != null && uri.queryParameters.containsKey('id')) {
        final productId = uri.queryParameters['id'];
        // Always use get_main_product_images.php since that's our working endpoint
        return '$baseUrl/get_main_product_images.php?id=$productId';
      }
      // Extract ID from URL pattern like /get_product_images.php?id=4
      final match = RegExp(r'id=(\d+)').firstMatch(relativeUrl);
      if (match != null) {
        final productId = match.group(1);
        return '$baseUrl/get_main_product_images.php?id=$productId';
      }
      return '$baseUrl/get_main_product_images.php?id=$relativeUrl';
    }

    final cleanPath =
        relativeUrl.startsWith('/') ? relativeUrl.substring(1) : relativeUrl;
    return '$baseUrl/$cleanPath';
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/orders.php?order_id=${widget.orderId}&user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            orderDetail = data['data'];
            isLoading = false;
          });
          print('Order detail fetched: $orderDetail');
        } else {
          setState(() {
            orderDetail = null;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          orderDetail = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        orderDetail = null;
        isLoading = false;
      });
      print('Error fetching order detail: $e');
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    try {
      double numPrice = double.parse(price.toString());
      return 'Rp ${numPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    } catch (_) {
      return 'Rp 0';
    }
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}-${dateTime.month}-${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeString;
    }
  }

  Future<void> _confirmOrderCompleted() async {
    if (widget.orderId == null || userId == null) return;

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pesanan'),
          content: const Text(
              'Apakah Anda yakin ingin menandai pesanan ini sebagai selesai?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Selesai'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Prepare request body
      final requestBody = {
        'order_id': int.parse(widget.orderId!),
        'status': 'completed',
        'user_id': int.parse(userId!),
      };

      print('Sending request to: $baseUrl/orders.php');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
        Uri.parse('$baseUrl/orders.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan telah dikonfirmasi sebagai selesai'),
                backgroundColor: Colors.green,
              ),
            );
            _fetchOrderDetail(); // Refresh the order details
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(data['message'] ?? 'Gagal mengupdate status pesanan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Gagal terhubung ke server. Status: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _confirmOrderCompleted: $e');
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan';
        if (e.toString().contains('timeout')) {
          errorMessage = 'Koneksi timeout, coba lagi';
        } else if (e.toString().contains('Failed to fetch') ||
            e.toString().contains('SocketException') ||
            e.toString().contains('Connection refused')) {
          errorMessage = 'Tidak ada koneksi internet';
        } else if (e.toString().contains('Connection failed')) {
          errorMessage = 'Server tidak dapat dijangkau';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to navigate to payment page
  void _navigateToPayment() {
    if (orderDetail == null || widget.orderId == null) return;

    // Get total price from order details
    double totalPrice = 0;
    try {
      totalPrice = double.parse(orderDetail!['total_harga'].toString());
    } catch (e) {
      print('Error parsing total_harga: $e');
    }

    // Navigate to payment page with default payment method (BCA)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          paymentMethod: PaymentMethod.bca,
          totalPayment: totalPrice,
          orderId: widget.orderId!,
        ),
      ),
    );
  }

  bool _canMarkAsCompleted() {
    if (orderDetail == null) return false;

    final orderStatus = orderDetail!['status']?.toString().toLowerCase();
    final statusDisplay =
        orderDetail!['status_display']?.toString().toLowerCase();
    final payment = orderDetail!['payment'];

    // Don't show button if order is already completed or cancelled
    if (orderStatus == 'completed' ||
        orderStatus == 'selesai' ||
        orderStatus == 'cancelled' ||
        orderStatus == 'batal') {
      return false;
    }

    // Check if payment exists and is paid
    bool isPaid = false;
    if (payment != null) {
      final paymentStatus =
          payment['status_pembayaran']?.toString().toLowerCase();
      isPaid = paymentStatus == 'paid' ||
          paymentStatus == 'dibayar' ||
          paymentStatus == 'completed' ||
          paymentStatus == 'selesai';
    }

    // Check if order status is shipped/dikirim
    bool isShipped = orderStatus == 'shipped' ||
        orderStatus == 'dikirim' ||
        statusDisplay == 'dikirim';

    // Show button only if paid AND shipped status
    return isPaid && isShipped;
  }

  // Check if the order needs payment
  bool _needsPayment() {
    if (orderDetail == null) return false;

    final orderStatus = orderDetail!['status']?.toString().toLowerCase();
    final statusDisplay =
        orderDetail!['status_display']?.toString().toLowerCase();

    // Check if order is in pending/belum bayar status
    return orderStatus == 'pending' ||
        orderStatus == 'belum bayar' ||
        statusDisplay == 'pending' ||
        statusDisplay == 'belum bayar';
  }

  // FIXED: Check if the order has shipping information - now includes completed orders
  bool _hasShippingInfo() {
    if (orderDetail == null) return false;

    final orderStatus = orderDetail!['status']?.toString().toLowerCase();
    final statusDisplay =
        orderDetail!['status_display']?.toString().toLowerCase();
    final shipping = orderDetail!['shipping'];

    // Show shipping info if:
    // 1. Shipping data exists, OR
    // 2. Order status is shipped/dikirim, OR
    // 3. Order status is completed/selesai (to show shipping history)
    return shipping != null ||
        orderStatus == 'shipped' ||
        orderStatus == 'dikirim' ||
        statusDisplay == 'dikirim' ||
        orderStatus == 'completed' ||
        orderStatus == 'selesai' ||
        statusDisplay == 'selesai';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 5,
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, String? productName) {
    if (imageUrl.isEmpty) {
      return _buildFallbackImage(productName);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
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
          return _buildFallbackImage(productName);
        },
      ),
    );
  }

  Widget _buildFallbackImage(String? productName) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          productName?.isNotEmpty == true
              ? productName!.substring(0, 1).toUpperCase()
              : "?",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        title:
            const Text('Detail Pesanan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D6EFD),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetail == null
              ? const Center(child: Text('Data pesanan tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderInfoCard(),
                      const SizedBox(height: 5),
                      _buildOrderItemsList(),
                      const SizedBox(height: 5),
                      _buildShippingInfoCard(),
                      if (_hasShippingInfo()) ...[
                        const SizedBox(height: 5),
                        _buildShippingStatusCard(),
                      ],
                      const SizedBox(height: 5),
                      _buildPaymentInfoCard(),
                      const SizedBox(height: 10),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Informasi Pesanan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(orderDetail!['status_display'] ??
                        orderDetail!['status']),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusDisplay(orderDetail!['status_display'] ??
                        orderDetail!['status']),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('No. Pesanan', '#${orderDetail!['id']}'),
            _buildInfoRow(
                'Tanggal Pesan', _formatDate(orderDetail!['waktu_order'])),
            _buildInfoRow(
                'Total Harga', _formatPrice(orderDetail!['total_harga'])),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsList() {
    final items = List<Map<String, dynamic>>.from(orderDetail!['items'] ?? []);
    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produk yang Dibeli',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                // Get the image URL - prioritize image_url field
                String imageUrl = '';

                if (item['image_url'] != null) {
                  imageUrl = _getFullImageUrl(item['image_url'].toString());
                } else if (item['gambar'] != null) {
                  imageUrl = _getFullImageUrl(item['gambar'].toString());
                } else if (item['product_image'] != null) {
                  imageUrl = _getFullImageUrl(item['product_image'].toString());
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      _buildProductImage(imageUrl, item['nama']?.toString()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${item['kuantitas']}x @ ${_formatPrice(item['harga'])}'),
                          ],
                        ),
                      ),
                      Text(_formatPrice(item['subtotal']),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_formatPrice(orderDetail!['total_harga']),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Pengiriman',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow(
                'Metode Pengiriman', orderDetail!['metode_pengiriman'] ?? '-'),
            _buildInfoRow(
                'Alamat Pengiriman', orderDetail!['alamat_pemesanan'] ?? '-'),
            if ((orderDetail!['notes'] ?? '').toString().isNotEmpty)
              _buildInfoRow('Catatan', orderDetail!['notes']),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Better shipping status display with fallback information
  Widget _buildShippingStatusCard() {
    final shipping = orderDetail!['shipping'];
    final orderStatus = orderDetail!['status']?.toString().toLowerCase();
    final statusDisplay =
        orderDetail!['status_display']?.toString().toLowerCase();

    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Pengiriman',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),

            // If shipping data exists, show detailed info
            if (shipping != null) ...[
              _buildInfoRow(
                  'Jasa Kurir', shipping['jasa_kurir'] ?? 'Tidak tersedia'),
              _buildInfoRow(
                  'Nomor Resi', shipping['nomor_resi'] ?? 'Tidak tersedia'),
              _buildInfoRow(
                  'Status',
                  shipping['status_display'] ??
                      shipping['status'] ??
                      'Tidak tersedia'),
              if (shipping['created_at'] != null)
                _buildInfoRow(
                    'Tanggal Pengiriman', _formatDate(shipping['created_at'])),
            ]
            // If no shipping data but order is shipped/completed, show basic status
            else if (orderStatus == 'shipped' ||
                orderStatus == 'dikirim' ||
                statusDisplay == 'dikirim' ||
                orderStatus == 'completed' ||
                orderStatus == 'selesai' ||
                statusDisplay == 'selesai') ...[
              _buildInfoRow(
                  'Status',
                  orderStatus == 'completed' ||
                          orderStatus == 'selesai' ||
                          statusDisplay == 'selesai'
                      ? 'Pengiriman Selesai'
                      : 'Sedang Dikirim'),
              _buildInfoRow(
                  'Keterangan',
                  orderStatus == 'completed' ||
                          orderStatus == 'selesai' ||
                          statusDisplay == 'selesai'
                      ? 'Paket telah diterima'
                      : 'Paket sedang dalam perjalanan'),
            ]
            // Fallback if no shipping info available
            else ...[
              const Text('Informasi pengiriman belum tersedia'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final payment = orderDetail!['payment'];
    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            if (payment != null) ...[
              _buildInfoRow(
                  'Metode Pembayaran', payment['metode_pembayaran'] ?? '-'),
              _buildInfoRow(
                  'Status Pembayaran',
                  _getPaymentStatusDisplay(
                      payment['status_pembayaran'] ?? '-')),
            ] else
              const Text('Belum ada informasi pembayaran'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Payment Button (only if order needs payment)
        if (_needsPayment())
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: const Text('Bayar Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

        // Add a space if both buttons are visible
        if (_needsPayment() && _canMarkAsCompleted())
          const SizedBox(height: 12),

        // Complete Order Button (only if payment is done and status allows)
        if (_canMarkAsCompleted())
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmOrderCompleted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: const Text('Pesanan Selesai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

        const SizedBox(height: 12),

        // Back Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0D6EFD)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            label: const Text('Kembali',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D6EFD))),
          ),
        ),
      ],
    );
  }

  String _getStatusDisplay(String? status) {
    if (status == null) return 'Unknown';

    switch (status.toLowerCase()) {
      case 'pending':
      case 'belum bayar':
        return 'Belum Bayar';
      case 'paid':
      case 'dibayar':
        return 'Dibayar';
      case 'shipped':
      case 'dikirim':
        return 'Dikirim';
      case 'completed':
      case 'selesai':
        return 'Selesai';
      case 'cancelled':
      case 'dibatalkan':
      case 'batal':
        return 'Batal';
      default:
        return status;
    }
  }

  String _getPaymentStatusDisplay(String? status) {
    if (status == null) return 'Belum Bayar';

    switch (status.toLowerCase()) {
      case 'pending':
      case 'belum bayar':
        return 'Belum Bayar';
      case 'paid':
      case 'dibayar':
        return 'Sudah Bayar';
      case 'completed':
      case 'selesai':
        return 'Selesai';
      case 'failed':
      case 'gagal':
        return 'Gagal';
      case 'refunded':
      case 'dikembalikan':
        return 'Dikembalikan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'belum bayar':
        return Colors.red;
      case 'paid':
      case 'dibayar':
        return Colors.orange;
      case 'shipped':
      case 'dikirim':
        return Colors.blue;
      case 'completed':
      case 'selesai':
        return Colors.green;
      case 'cancelled':
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
