import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:umkm_batik/pages/pesanan_page.dart';
import 'payment_method.dart';
import 'panduan.dart';

class PaymentPage extends StatefulWidget {
  final PaymentMethod paymentMethod;
  final double totalPayment;
  final String orderId;

  const PaymentPage({
    Key? key,
    required this.paymentMethod,
    required this.totalPayment,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // Timer variables
  Timer? _timer; // 24 hours in seconds
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Function to cancel order via API
  Future<void> _cancelOrder(String reason) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract order ID (handle format like "UMKM-20250516-0024")
      String orderIdStr = widget.orderId;
      if (orderIdStr.contains('-')) {
        // If the order ID is something like "UMKM-20250516-0024", just pass it as is
        // The backend will need to handle this format
      } else {
        // If it's a numeric ID, ensure it's properly formatted
        try {
          int.parse(orderIdStr); // Just to validate it's a number
        } catch (e) {
          throw FormatException('Invalid order ID format: $orderIdStr');
        }
      }

      // Use your actual API endpoint
      final apiUrl = 'http://192.168.1.6/umkm_batik/API/cancel_order.php';

      // Ensure the API is called with proper POST method and headers
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add any authorization headers if needed
        },
        body: jsonEncode({
          'order_id': orderIdStr,
          'reason': reason,
        }),
      );

      // Parse response based on its format
      Map<String, dynamic> result;
      try {
        result = jsonDecode(response.body);
      } catch (e) {
        throw Exception('Invalid response format: ${response.body}');
      }

      if (result['success'] == true) {
        // Order canceled successfully
        _showSuccessDialog('Pesanan dibatalkan', result['message']);
      } else {
        // Error in cancelling order
        _showErrorDialog(
            'Gagal membatalkan pesanan', result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Terjadi kesalahan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToOrderDetail();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Batalkan Pesanan'),
          content:
              const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
          actions: [
            TextButton(
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ya, Batalkan'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelOrder('Cancelled by user');
              },
            ),
          ],
        );
      },
    );
  }

  // Function to navigate to order detail page
  void _navigateToOrderDetail() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PesananPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true,
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate to order detail page instead of just popping
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PesananPage()),
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      _buildOrderInfo(),
                      const SizedBox(height: 0),
                      _buildBankInfo(),
                      const SizedBox(height: 0),
                      _buildInstructions(),
                      const SizedBox(height: 0),
                      _buildHelpText(),
                    ],
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
    );
  }

  Widget _buildOrderInfo() {
    return _buildSection(
      child: Column(
        children: [
          _buildInfoRow(
            label: 'ID Pemesanan',
            value: widget.orderId,
            showCopy: true,
          ),
          const Divider(height: 10),
          _buildInfoRow(
            label: 'Total Pembayaran',
            value: 'Rp ${_formatCurrency(widget.totalPayment)}',
            valueColor: const Color(0xFF0D6EFD),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfo() {
    return _buildSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pembayaran via ${widget.paymentMethod.displayName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.paymentMethod.accountNumber,
                style: const TextStyle(
                  fontSize: 25,
                  color: Color(0xFF0D6EFD),
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.paymentMethod.accountNumber),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor rekening disalin'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan mengisi kolom catatan dengan ID pemesanan "${widget.orderId}" untuk mempermudah verifikasi.',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return _buildSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Petunjuk Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.paymentMethod.instructions.map(_buildInstructionItem),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return _buildSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jika terjadi kendala terhadap pembayaran anda bisa ke menu bantuan untuk informasi kontak dll',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PanduanChatbot()), // pastikan Panduan terimport
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.help_outline, color: Color.fromARGB(255, 0, 0, 0)),
                SizedBox(width: 8),
                Text(
                  'Bantuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _showCancelConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Batalkan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => PesananPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
    bool showCopy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black,
                  ),
                ),
                if (showCopy)
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID Pemesanan disalin'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
