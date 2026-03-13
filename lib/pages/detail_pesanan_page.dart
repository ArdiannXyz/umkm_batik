import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart'; // Import the payment page
import 'payment_method.dart';
import '../services/payment_service.dart';
import 'dart:math' as math; // Import the payment method enum

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

  Future<void> _fetchOrderDetail() async {
    try {
      final detail = await PaymentService.fetchOrderDetail(
        orderId: widget.orderId!,
        userId: userId!,
      );

      setState(() {
        orderDetail = detail;
        isLoading = false;
      });

      print('Order detail fetched: $orderDetail');
    } catch (e) {
      print('Error fetching order detail: $e');
      setState(() {
        orderDetail = null;
        isLoading = false;
      });
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

  bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.blue,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Konfirmasi Pesanan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Apakah Anda yakin ingin menandai pesanan ini sebagai selesai?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tindakan ini tidak dapat dibatalkan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Ya, Selesai'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

    if (confirmed != true) return;

    try {
      final result = await PaymentService.confirmOrderCompleted(
        orderId: widget.orderId!,
        userId: userId!,
      );

      final statusCode = result['statusCode'];
      final data = result['data'];

      if (statusCode == 200 && data['status'] == 'success') {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Pesanan telah dikonfirmasi sebagai selesai')),
              ],
            ),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
          _fetchOrderDetail();
        }
      } else {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text(data['message'] ?? 'Gagal mengupdate status pesanan')),
              ],
            ),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
        }
      }
    } catch (e) {
      print('Error in _confirmOrderCompleted: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
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

  // Check if the order has shipping information - now includes completed orders
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

  // Simplified product image method - now uses base64 directly from orderDetail
 // Perbaikan method untuk menangani base64 image dengan prefix
Widget _buildProductImage(String? base64Image, String? productName) {
  if (base64Image == null || base64Image.isEmpty) {
    return _buildFallbackImage(productName);
  }

  try {
    // Bersihkan prefix data URL jika ada
    String cleanBase64 = base64Image;
    if (base64Image.startsWith('data:image')) {
      // Hapus prefix seperti "data:image/jpeg;base64," atau "data:image/png;base64,"
      final commaIndex = base64Image.indexOf(',');
      if (commaIndex != -1) {
        cleanBase64 = base64Image.substring(commaIndex + 1);
      }
    }

    // Hapus whitespace dan newline yang mungkin ada
    cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
    
    // Validasi apakah string base64 valid (harus kelipatan 4)
    while (cleanBase64.length % 4 != 0) {
      cleanBase64 += '=';
    }

    // Decode base64 yang sudah dibersihkan
    final bytes = base64Decode(cleanBase64);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image from memory: $error');
          return _buildFallbackImage(productName);
        },
      ),
    );
  } catch (e) {
    print('Error decoding base64 image: $e');
    print('Base64 string length: ${base64Image.length}');
    print('Base64 preview: ${base64Image.substring(0, math.min(100, base64Image.length))}...');
    return _buildFallbackImage(productName);
  }
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

                // Get base64 image directly from item data
                String? base64Image = item['image_base64']?.toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      _buildProductImage(base64Image, item['nama']?.toString()),
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
          ],
        ),
      ),
    );
  }


  // Better shipping status display with fallback information
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
                backgroundColor: Colors.blue,
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