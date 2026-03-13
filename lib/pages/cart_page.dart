import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:umkm_batik/services/cart_service.dart';
import 'dart:convert';
import 'checkout_from_cart.dart';
import '../models/cartitem.dart';
import 'dart:math' as math;

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
    final result = await CartService.fetchCart(widget.userId.toString());

    if (result['success'] == true) {
      final responseData = result['data'];

      if (responseData != null) {
        setState(() {
          cartItems = (responseData['cart_items'] as List)
              .map((item) => CartItem.fromJson(item))
              .toList();

          selectedItems.clear();
          for (var item in cartItems) {
            selectedItems[item.id] = true;
          }

          cartSummary = responseData['summary'] != null
              ? CartSummary.fromJson(responseData['summary'])
              : null;

          isLoading = false;
        });
      } else {
        setState(() {
          cartItems = [];
          cartSummary = null;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Failed to load cart';
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



  // Fungsi untuk update quantity item - disesuaikan dengan backend
  // Perbaikan untuk _updateQuantity method
Future<void> _updateQuantity(int cartId, int newQuantity) async {
  if (newQuantity <= 0) {
    await _removeItem(cartId);
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final result = await CartService.updateQuantity(
      cartId: cartId,
      newQuantity: newQuantity,
      userId: widget.userId.toString(),
    );

    Navigator.of(context).pop();

    if (result['success'] == true) {
      await _loadCartItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update quantity'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
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
    final result = await CartService.removeItem(
      cartId: cartId,
      userId: widget.userId.toString(),
    );

    if (result['success'] == true) {
      await _loadCartItems();
      String productName = result['data']?['product_name'] ?? 'Item';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$productName berhasil dihapus dari keranjang'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menghapus item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
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
    int successCount = await CartService.deleteMultipleItems(
      items: itemsToDelete,
      userId: widget.userId.toString(),
    );

    await _loadCartItems();

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
            return _buildCartItemCard(item, '');
          },
        ),
      ),
      _buildCheckoutSection(),
    ],
  );
}


 Widget _buildCartItemCard(CartItem item,String imageUrl) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
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
              margin: const EdgeInsets.only(right: 2),
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

              SizedBox(width: 3,),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.nama,
                      style: GoogleFonts.varelaRound(
                        fontSize: 12,
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
                        fontSize: 12,
                        color: item.isAvailable ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                    "Total Berat: ${item.totalWeight} gram",
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isAvailable ? Colors.grey[700] : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                    const SizedBox(height: 4),
                    Text(
                      "Subtotal: Rp ${_formatPrice(item.subtotal)}",
                      style: TextStyle(
                        fontSize: 12,
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
                            fontSize: 10,
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
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(2),
                          color: item.isAvailable ? Colors.white : Colors.grey[100],
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: TextStyle(
                            fontSize: 12,
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
                        size: 15,
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
  // Extract ID dari productImage (baik dari URL maupun string ID)
  final imageId = _extractImageId(item.productImage);
  
  if (imageId == null) {
    print('Cannot extract image ID from: ${item.productImage}');
    return _defaultImage();
  }

  print('Loading base64 image for ID: $imageId');

  return FutureBuilder<String?>(
    future: CartService.getBase64Image(imageId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _loadingPlaceholder();
      }
      
      if (snapshot.hasError) {
        print('Error fetching base64 image for ID $imageId: ${snapshot.error}');
        return _errorImage();
      }
      
      final base64Data = snapshot.data;
      if (base64Data == null || base64Data.isEmpty) {
        print('Empty base64 data for image ID: $imageId');
        return _defaultImage();
      }
      
      print('Successfully loaded base64 image for ID: $imageId');
      return _buildBase64Image(base64Data);
    },
  );
}

  // Jika data berupa ID gambar (angka)
int? _extractImageId(String imageData) {
  try {
    // Jika sudah berupa angka (ID)
    if (RegExp(r'^\d+$').hasMatch(imageData)) {
      return int.parse(imageData);
    }
    
    // Jika berupa URL, extract ID dari path terakhir
    if (imageData.startsWith('http')) {
      final uri = Uri.parse(imageData);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        return int.tryParse(lastSegment);
      }
    }
    
    // Jika ada format lain, tambahkan di sini
    
  } catch (e) {
    print('Error extracting image ID from: $imageData, Error: $e');
  }
  
  return null;
}

Widget _buildBase64Image(String base64Data) {
  try {
    // Handle different base64 formats
    String cleanBase64;
    
    if (base64Data.contains('data:image')) {
      // Format: data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...
      cleanBase64 = base64Data.split(',').last;
    } else if (base64Data.contains(',')) {
      // Format dengan koma tapi bukan data URL
      cleanBase64 = base64Data.split(',').last;
    } else {
      // Pure base64 string
      cleanBase64 = base64Data;
    }
    
    // Remove any whitespace
    cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
    
    // Validate base64 format
    if (cleanBase64.isEmpty || cleanBase64.length % 4 != 0) {
      print('Invalid base64 format: length=${cleanBase64.length}');
      return _errorImage();
    }
    
    final bytes = base64Decode(cleanBase64);
    
    if (bytes.isEmpty) {
      print('Empty bytes after base64 decode');
      return _errorImage();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          print('Error displaying base64 image: $error');
          return _errorImage();
        },
      ),
    );
  } catch (e) {
    print('Error in _buildBase64Image: $e');
    print('Base64 data length: ${base64Data.length}');
    print('Base64 data preview: ${base64Data.substring(0, math.min(50, base64Data.length))}...');
    return _errorImage();
  }
}



Widget _defaultImage() => Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[400]!, width: 1),
  ),
  child: const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
      Text(
        'No Image', 
        style: TextStyle(fontSize: 8, color: Colors.grey), 
        textAlign: TextAlign.center,
      ),
    ],
  ),
);

Widget _loadingPlaceholder() => Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!, width: 1),
  ),
  child: const Center(
    child: SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    ),
  ),
);

Widget _errorImage() => Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    color: Colors.red[50],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.red[300]!, width: 1),
  ),
  child: const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline, color: Colors.red, size: 18),
      Text(
        'Error', 
        style: TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.w500), 
        textAlign: TextAlign.center,
      ),
    ],
  ),
);


  
  

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