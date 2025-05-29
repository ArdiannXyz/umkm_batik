import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'checkout_from_cart.dart';
import '../models/cartitem.dart';

class CartPage extends StatefulWidget {
  final int userId;

  const CartPage({
    super.key, 
    required this.userId,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];
  CartSummary? cartSummary;
  bool isLoading = true;
  String? errorMessage;
  Map<int, bool> selectedItems = {};

  // Base URL API - sesuaikan dengan URL server Anda
  static const String baseUrl = 'http://localhost/umkm_batik/API';

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  // Fungsi untuk memuat data keranjang dari API
  Future<void> _loadCartItems() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
    
  });

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/get_cart.php?user_id=${widget.userId}'),
      headers: {'Content-Type': 'application/json'},
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Parsed data: $data');
      
      if (data['success'] == true) {
        final responseData = data['data'];
        
        if (responseData != null) {
          setState(() {
            // Parse cart items dengan struktur baru
            if (responseData['cart_items'] != null) {
              cartItems = (responseData['cart_items'] as List)
                  .map((item) => CartItem.fromJson(item))
                  .toList();
            } else {
              cartItems = [];
            }
            selectedItems.clear();
            for (var item in cartItems) {
              selectedItems[item.id] = true; // Default semua item selected
            }
            
            // Parse summary dengan struktur baru
            if (responseData['summary'] != null) {
              cartSummary = CartSummary.fromJson(responseData['summary']);
            } else {
              cartSummary = null;
            }
            
            isLoading = false;
          });
          
          print('Loaded ${cartItems.length} cart items');
          if (cartItems.isNotEmpty) {
            print('First item: ${cartItems.first.productName}');
            print('First item image: ${cartItems.first.productImage}');
          }
        } else {
          setState(() {
            cartItems = [];
            cartSummary = null;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Failed to load cart';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        errorMessage = 'Server error: ${response.statusCode}';
        isLoading = false;
      });
    }
  } catch (e) {
    print('Error loading cart: $e');
    setState(() {
      errorMessage = 'Network error: ${e.toString()}';
      isLoading = false;
    });
  }
}

void _toggleItemSelection(int cartId, bool? value) {
  setState(() {
    selectedItems[cartId] = value ?? false;
  });
}

void _toggleSelectAll() {
  bool shouldSelectAll = !_areAllItemsSelected();
  setState(() {
    for (var item in cartItems) {
      if (item.isAvailable) {
        selectedItems[item.id] = shouldSelectAll;
      }
    }
  });
}

bool _areAllItemsSelected() {
  return cartItems.where((item) => item.isAvailable)
      .every((item) => selectedItems[item.id] == true);
}

List<CartItem> _getSelectedItems() {
  return cartItems.where((item) => 
      selectedItems[item.id] == true && item.isAvailable).toList();
}

double _getSelectedItemsTotal() {
  return _getSelectedItems().fold(0.0, (sum, item) => sum + item.subtotal);
}

int _getSelectedItemsCount() {
  return _getSelectedItems().length;
}

int _getSelectedItemsQuantity() {
  return _getSelectedItems().fold(0, (sum, item) => sum + item.quantity);
}

String _buildImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  
  // Jika URL sudah lengkap (dimulai dengan http/https), gunakan langsung
  if (imageUrl.startsWith('http')) {
    return imageUrl;
  }
  
  // Jika URL relatif, gabungkan dengan base URL
  return '$baseUrl/$imageUrl';
}

  // Fungsi untuk update quantity item - disesuaikan dengan backend
  // Perbaikan untuk _updateQuantity method
Future<void> _updateQuantity(int cartId, int newQuantity) async {
  if (newQuantity <= 0) {
    _removeItem(cartId);
    return;
  }

  // Tampilkan loading state
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final response = await http.put(  // Ubah dari POST ke PUT
      Uri.parse('$baseUrl/update_cart.php'),  // Sesuaikan nama file
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'cart_id': cartId,
        'quantity': newQuantity,
        'user_id': widget.userId,
      }),
    );

    // Tutup loading dialog
    Navigator.of(context).pop();

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Reload cart untuk mendapatkan data terbaru
        await _loadCartItems();
        
        
          
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to update quantity'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    // Tutup loading dialog jika error
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Fungsi untuk menghapus item dari keranjang
 // Perbaikan untuk _removeItem function
Future<void> _removeItem(int cartId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_cart.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'cart_id': cartId,
        'quantity': 0, // Quantity 0 untuk menghapus item
        'user_id': widget.userId,
      }),
    );

    print('Delete response status: ${response.statusCode}');
    print('Delete response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Reload cart untuk mendapatkan data terbaru
        await _loadCartItems();
        
        // Tampilkan pesan success yang lebih spesifik
        String productName = data['data']?['product_name'] ?? 'Item';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName berhasil dihapus dari keranjang'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal menghapus item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error removing item: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showDeleteSelectedDialog() {
  List<CartItem> selectedItems = _getSelectedItems();
  
  if (selectedItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pilih item yang ingin dihapus"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Hapus Item Terpilih?",
          style: GoogleFonts.varelaRound(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Apakah kamu yakin ingin menghapus ${selectedItems.length} item yang dipilih dari keranjang?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Hapus"),
          ),
        ],
      );
    },
  );
}

void _showDeleteSingleItemDialog(int cartId, String productName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Hapus Item?",
          style: GoogleFonts.varelaRound(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Apakah kamu yakin ingin menghapus \"$productName\" dari keranjang?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem(cartId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Hapus"),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteSelectedItems() async {
  List<CartItem> itemsToDelete = _getSelectedItems();
  
  if (itemsToDelete.isEmpty) return;

  try {
    int successCount = 0;
    List<String> deletedItems = [];
    
    // Hapus item satu per satu dengan error handling yang lebih baik
    for (var item in itemsToDelete) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/delete_cart.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'cart_id': item.id,
            'quantity': 0,
            'user_id': widget.userId,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            successCount++;
            deletedItems.add(item.product.nama);
          }
        }
      } catch (e) {
        print('Error deleting item ${item.id}: $e');
        // Continue dengan item lainnya
      }
    }
    
    // Reload cart setelah semua operasi selesai
    await _loadCartItems();
    
    // Tampilkan hasil
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount item berhasil dihapus dari keranjang'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus item dari keranjang'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error in _deleteSelectedItems: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error menghapus item: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Keranjang Belanja",
          style: GoogleFonts.varelaRound(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
  if (cartItems.isNotEmpty) ...[
    TextButton(
      onPressed: _toggleSelectAll,
      child: Text(
        _areAllItemsSelected() ? "Unselect All" : "Select All",
        style: TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
            
          ],
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadCartItems,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return _buildCartWithItems();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              "Terjadi Kesalahan",
              style: GoogleFonts.varelaRound(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadCartItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Coba Lagi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Keranjang kamu masih kosong",
              style: GoogleFonts.varelaRound(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Yuk, mulai belanja batik favorit kamu!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Mulai Belanja",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _buildCartItemCard(item);
            },
          ),
        ),
        _buildCheckoutSection(),
      ],
    );
  }

 Widget _buildCartItemCard(CartItem item) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 5,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          // Stock warning jika tidak tersedia
          if (!item.isAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Stok tidak mencukupi (tersedia: ${item.product.stock.quantity})",
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
                  Row(
          children: [
            // Tambahkan Checkbox di sini
            Container(
              margin: const EdgeInsets.only(right: 5),
              child: Checkbox(
                value: selectedItems[item.id] ?? false,
                onChanged: item.isAvailable ? (value) => _toggleItemSelection(item.id, value) : null,
                activeColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            
            // Product Image (existing code)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProductImage(item),
            ),
              SizedBox(width: 10,),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.nama,
                      style: GoogleFonts.varelaRound(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable ? Colors.black87 : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                   
                    const SizedBox(height: 8),
                    Text(
                      "Rp ${_formatPrice(item.product.harga)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: item.isAvailable ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                    "Total Berat: ${item.totalWeight} gram",
                    style: TextStyle(
                      fontSize: 14,
                      color: item.isAvailable ? Colors.grey[700] : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                    const SizedBox(height: 4),
                    Text(
                      "Subtotal: Rp ${_formatPrice(item.subtotal)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: item.isAvailable ? Colors.grey[700] : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Stok: ${item.product.stock.quantity}",
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isAvailable ? Colors.green[600] : Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        
                      ],
                    ),
                  ],
                ),
              ),
            
            // Quantity Controls
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: item.isAvailable ? () => _updateQuantity(item.id, item.quantity - 1) : null,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(6),
                          color: item.isAvailable ? Colors.white : Colors.grey[100],
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: item.isAvailable ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: item.isAvailable && item.quantity < item.product.stock.quantity 
                            ? () => _updateQuantity(item.id, item.quantity + 1) 
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                      onPressed: () => _showDeleteSingleItemDialog(item.id, item.product.nama),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Hapus item',
                    )

                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildProductImage(CartItem item) {
  String? imageUrl = item.productImage;
  
  if (imageUrl == null || imageUrl.isEmpty) {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Icon(
        Icons.shopping_bag,
        color: Colors.grey[400],
        size: 40,
      ),
    );
  }

  String fullImageUrl = _buildImageUrl(imageUrl);
  
  return CachedNetworkImage(
    imageUrl: fullImageUrl,
    width: 80,
    height: 80,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
    errorWidget: (context, url, error) {
      print('Error loading image: $url, Error: $error');
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
          size: 40,
        ),
      );
    },
  );
}

  Widget _buildQuantityButton({
    required IconData icon, 
    required VoidCallback? onPressed
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onPressed != null ? Colors.blue[200]! : Colors.grey[300]!
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

Widget _buildCheckoutSection() {
  if (cartItems.isEmpty) return const SizedBox.shrink();

  int selectedCount = _getSelectedItemsCount();
  double selectedTotal = _getSelectedItemsTotal();
  int selectedQuantity = _getSelectedItemsQuantity();
  
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      children: [
        // Warning jika tidak ada item yang dipilih
        if (selectedCount == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Pilih item yang ingin di-checkout",
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total ($selectedCount item${selectedCount > 1 ? 's' : ''})",
              style: GoogleFonts.varelaRound(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Rp ${_formatPrice(selectedTotal)}",
              style: GoogleFonts.varelaRound(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total Quantity:",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              "$selectedQuantity pcs",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedCount > 0 ? _proceedToCheckout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedCount > 0 ? Colors.blue : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: Text(
              selectedCount > 0 
                  ? "Checkout ($selectedCount items)"
                  : "Select Items to Checkout",
              style: GoogleFonts.varelaRound(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

 void _proceedToCheckout() async {
  List<CartItem> selectedItems = _getSelectedItems();
  if (selectedItems.isEmpty) return;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CheckoutCart(
        cartItems: selectedItems,
        userId: widget.userId,
      ),
    ),
  );

  // Jika checkout berhasil, refresh cart
  if (result == true) {
    _loadCartItems();
  }
}

void _showCheckoutDialog() {
  List<CartItem> selectedItems = _getSelectedItems();
  if (selectedItems.isEmpty) return;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Checkout",
          style: GoogleFonts.varelaRound(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selected items: ${_getSelectedItemsCount()}"),
            Text("Total quantity: ${_getSelectedItemsQuantity()}"),
            Text("Total price: Rp ${_formatPrice(_getSelectedItemsTotal())}"),
            const SizedBox(height: 16),
            const Text("Lanjutkan ke pembayaran?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement checkout logic with selectedItems
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fitur checkout akan segera tersedia!"),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Bayar"),
          ),
        ],
      );
    },
  );
}

  // Helper functions
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}