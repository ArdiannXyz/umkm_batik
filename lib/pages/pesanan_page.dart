import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';
import 'detail_pesanan_page.dart';
import 'dart:typed_data';

class PesananPage extends StatefulWidget {
  final int initialTabIndex;

  const PesananPage({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _PesananPageState createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 5, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(_handleTabChange);
    _getUserId();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (userId == null) return;

    setState(() {
      isLoading = true;
      orders = [];
    });
    _fetchOrders(_getStatusFromTabIndex(_tabController.index));
  }

  String _getStatusFromTabIndex(int index) {
    return ["Belum Bayar", "Dibayar", "Dikirim", "Selesai", "Batal"][index];
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case "Paid":
        return "Dibayar";
      case "Belum Bayar":
        return "Belum Bayar";
      case "Dikirim":
        return "Dikirim";
      case "Selesai":
        return "Selesai";
      case "Batal":
        return "Batal";
      default:
        return status;
    }
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.get('user_id');

    setState(() {
      userId = id?.toString();
    });

    if (userId != null) {
      _fetchOrders(_getStatusFromTabIndex(_tabController.index));
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

 Future<void> _fetchOrders(String status) async {
  print('_fetchOrders called with status: "$status"');
  if (userId == null || userId!.isEmpty) {
    print('Error: userId is null or empty');
    setState(() {
      orders = [];
      isLoading = false;
    });
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final result = await PaymentService.fetchOrders(
      userId: userId!,
      status: status.isNotEmpty ? status : null, // Handle empty status
    );

    setState(() {
      orders = result;
      isLoading = false;
    });

    print('Successfully fetched ${result.length} orders');
  } catch (e) {
    print('Error fetching orders: $e');
    
    // Optional: Show error message to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      orders = [];
      isLoading = false;
    });
  }
}

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    try {
      double numPrice = double.parse(price.toString());
      return 'Rp ${numPrice.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          )}';
    } catch (_) {
      return 'Rp 0';
    }
  }

  Widget _buildProductImage(String? imageBase64, String? productName) {
    // Check if imageBase64 is available and not empty
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        // Handle base64 string (remove data URL prefix if present)
        String base64String = imageBase64;
        if (base64String.contains(',')) {
          base64String = base64String.split(',')[1];
        }
        
        final imageBytes = base64Decode(base64String);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              print('Error displaying image: $error');
              return _buildFallbackImage(productName);
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64: $e');
        return _buildFallbackImage(productName);
      }
    }

    // Return fallback image if no base64 data
    return _buildFallbackImage(productName);
  }

  Widget _buildFallbackImage(String? productName) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          productName?.isNotEmpty == true
              ? productName!.substring(0, 1).toUpperCase()
              : "?",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
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
            const Text('Pesanan saya', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF0D6EFD),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Unpaid"),
            Tab(text: "Dibayar"),
            Tab(text: "Dikirim"),
            Tab(text: "Selesai"),
            Tab(text: "Batal"),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (index) {
          final status = _getStatusFromTabIndex(index);
          return _buildOrderList(status);
        }),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_basket_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada pesanan ${_getDisplayStatus(status)}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

return ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: orders.length,
  itemBuilder: (context, index) {
    final order = orders[index];
    final List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(order['items'] ?? []);
    final firstItem = items.isNotEmpty ? items.first : null;
    final itemCount = items.length;

    // Get base64 image directly from the item data
    final imageBase64 = firstItem?['image_base64']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          if (order['id'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DetailPesananPage(orderId: order['id'].toString()),
              ),
            ).then((_) {
              _fetchOrders(_getStatusFromTabIndex(_tabController.index));
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildProductImage(imageBase64, firstItem?['nama']?.toString()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem?['nama']?.toString() ?? 'Produk',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              firstItem != null &&
                                      firstItem['kuantitas'] != null
                                  ? "${firstItem['kuantitas']}x" +
                                      (itemCount > 1
                                          ? " dan ${itemCount - 1} produk lainnya"
                                          : "")
                                  : "0 item",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Order ID: #${order['id'] ?? ''}",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getDisplayStatus(
                                status), // <- hanya ambil dari tab yang aktif
                            style: TextStyle(
                              color: status == "Batal"
                                  ? Colors.red
                                  : const Color(0xFF0D6EFD),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == "Selesai"
                                  ? const Color(0xFF0D6EFD)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: status == "Selesai"
                                  ? null
                                  : Border.all(color: const Color(0xFF0D6EFD)),
                            ),
                            child: Text(
                              status == "Selesai"
                                  ? "Pesanan Selesai"
                                  : "Cek Detail",
                              style: TextStyle(
                                color: status == "Selesai"
                                    ? Colors.white
                                    : const Color(0xFF0D6EFD),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total harga:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _formatPrice(order['total_harga']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}