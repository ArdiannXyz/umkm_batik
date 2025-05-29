import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:umkm_batik/pages/cart_page.dart';
import 'semua_ulasan_page.dart';
import 'berikan_ulasan_page.dart';
import 'checkout_from_product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkm_batik/services/user_service.dart';
import '../models/checkout_model.dart';

class DetailProdukPage extends StatefulWidget {
  final int productId;
  final bool isFavorite;
  final Function()? onFavoriteToggle;

  const DetailProdukPage({
    super.key,
    required this.productId,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage> {
  Map<String, dynamic>? product;
  List<dynamic> ulasanList = [];
  List<dynamic> displayedUlasan = []; // For limited display
  bool isLoading = true;
  bool isLoadingReviews = true;
  int currentImageIndex = 0;
  Set<int> favoriteProductIds = {};
  int? userId;
  final PageController _pageController = PageController();
  bool showAllReviews = false;
  final int maxDisplayedReviews = 3; // Maximum reviews to show initially

  @override
  void initState() {
    super.initState();
    fetchProduct();
    fetchUlasan();
    loadUserAndFavorites();
  }

  Future<void> loadUserAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId != null) {
      final favorites = await UserService.getFavorites(userId!);
      setState(() {
        favoriteProductIds = favorites;
      });
    }
  }

  void handleFavoriteToggle(int productId) async {
    if (userId != null) {
      await UserService.toggleFavorite(userId!, productId);

      setState(() {
        if (favoriteProductIds.contains(productId)) {
          favoriteProductIds.remove(productId);
        } else {
          favoriteProductIds.add(productId);
        }
      });
    }
  }

  Future<void> fetchProduct() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://192.168.1.6/umkm_batik/API/get_detail_produk.php?id=${widget.productId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data['id'] != null) {
          setState(() {
            product = data;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produk tidak ditemukan.")),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat data produk.")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  Future<void> fetchUlasan() async {
    setState(() {
      isLoadingReviews = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'http://192.168.1.6/umkm_batik/API/get_reviews.php?product_id=${widget.productId}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            ulasanList = data;
            // Show only first few reviews initially
            displayedUlasan = ulasanList.take(maxDisplayedReviews).toList();
            isLoadingReviews = false;
          });
        } else {
          setState(() {
            ulasanList = [];
            displayedUlasan = [];
            isLoadingReviews = false;
          });
        }
      } else {
        setState(() {
          ulasanList = [];
          displayedUlasan = [];
          isLoadingReviews = false;
        });
      }
    } catch (e) {
      setState(() {
        ulasanList = [];
        displayedUlasan = [];
        isLoadingReviews = false;
      });
      print('Error fetching reviews: $e');
    }
  }

  void toggleShowAllReviews() {
    setState(() {
      showAllReviews = !showAllReviews;
      if (showAllReviews) {
        displayedUlasan = ulasanList;
      } else {
        displayedUlasan = ulasanList.take(maxDisplayedReviews).toList();
      }
    });
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      base64String = base64String.replaceAll(RegExp(r'\s'), '');
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Decode error: $e');
      return Uint8List(0);
    }
  }

  // Create ProductItem from product data
  ProductItem _createProductItem(int quantity) {
    String imageBase64 = '';
    Uint8List? imageBytes;

    if (product?['images'] != null &&
        product!['images'].isNotEmpty &&
        product!['images'][0]['image_base64'] != null) {
      imageBase64 = product!['images'][0]['image_base64'];
      imageBytes = _base64ToImage(imageBase64);
    }

return ProductItem(
  id: int.parse(product?['id'].toString() ?? '0'),
  name: product?['nama'] ?? 'Batik',
  price: double.parse(product?['harga']?.toString() ?? '0'),
  quantity: quantity,
  image: imageBytes,
  imageBase64: imageBase64,
  weight: product?['berat'] != null 
    ? int.parse(product!['berat'].toString()) 
    : 200, // Default 200g jika null
    );
  }

  // Function to add product to cart
  Future<void> addToCart(int quantity) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.6/umkm_batik/API/add_to_cart.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'product_id': widget.productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Produk berhasil ditambahkan ke keranjang"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Gagal menambahkan ke keranjang")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menambahkan ke keranjang")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  // Function to navigate to cart page
  void _navigateToCart() {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(userId: userId!),
      ),
    );
  }

  Widget _buildProductImageGallery() {
    // Check if we have images to display
    if (product?['images'] != null &&
        product!['images'].isNotEmpty &&
        product!['images'][0]['image_base64'] != null) {
      // Create a PageView for swiping through multiple images if available
      return Stack(
        children: [
          // Main image container with border styling
          Container(
            height: 450,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: product!['images'].length > 1
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: product!['images'].length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! > 0) {
                            // Swipe right
                            if (currentImageIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else if (details.primaryVelocity! < 0) {
                            // Swipe left
                            if (currentImageIndex <
                                product!['images'].length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Image.memory(
                            _base64ToImage(
                                product!['images'][index]['image_base64']),
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Image.memory(
                      _base64ToImage(product!['images'][0]['image_base64']),
                      fit: BoxFit.contain,
                    ),
                  ),
          ),

          // Image counter indicator (like in Shopee)
          if (product!['images'].length > 1)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentImageIndex + 1}/${product!['images'].length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      // Fallback if no images are available
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "Tidak ada gambar produk",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildThumbnailInBottomSheet() {
    if (product?['images'] != null && product!['images'].isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.memory(
            _base64ToImage(product!['images'][0]['image_base64']),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
  }

  void _showQuantityBottomSheet({required bool isForCart}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        int jumlah = 1;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildThumbnailInBottomSheet(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp.${double.parse(product?['harga'] ?? '0').toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text("Stok : ${product?['quantity'] ?? 0}",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Jumlah", style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (jumlah > 1) {
                              setModalState(() => jumlah--);
                            }
                          },
                          icon: const Icon(Icons.arrow_left),
                        ),
                        Text(jumlah.toString(),
                            style: const TextStyle(fontSize: 16)),
                        IconButton(
                          onPressed: () {
                            int stok = int.tryParse(
                                    product?['quantity'].toString() ?? '0') ??
                                0;
                            if (jumlah < stok) {
                              setModalState(() => jumlah++);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Jumlah melebihi stok tersedia")),
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_right),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isForCart ? Colors.orange : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      if (isForCart) {
                        // Add to cart
                        addToCart(jumlah);
                        Navigator.pop(context);
                      } else {
                        // Create ProductItem with selected quantity
                        final productItem = _createProductItem(jumlah);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutPage(
                              product: productItem,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                        isForCart ? "Tambah ke Keranjang" : "Bayar Sekarang",
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ulasan Produk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${product?['rating'] ?? 0.0}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' (${ulasanList.length} ulasan)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Loading indicator for reviews
          if (isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (ulasanList.isEmpty)
            // No reviews message
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada ulasan untuk produk ini',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Reviews list
            Column(
              children: [
                ...displayedUlasan.map((ulasan) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            radius: 20,
                            child: Text(
                              (ulasan['nama'] ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ulasan['nama'] ?? 'Pengguna',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (index) => Icon(
                                        index < (int.tryParse(ulasan['rating'].toString()) ?? 0)
                                            ? Icons.star
                                            : Icons.star_outline,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (ulasan['created_at'] != null)
                                      Text(
                                        ulasan['created_at'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ulasan['komentar'] ?? 'Tidak ada komentar',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (ulasan != displayedUlasan.last)
                        Divider(color: Colors.grey.shade200),
                      if (ulasan != displayedUlasan.last)
                        const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
                
                // Show more/less button if there are more reviews
                if (ulasanList.length > maxDisplayedReviews)
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: toggleShowAllReviews,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showAllReviews
                                    ? 'Tampilkan Lebih Sedikit'
                                    : 'Lihat ${ulasanList.length - maxDisplayedReviews} Ulasan Lainnya',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                showAllReviews
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // View all reviews button (navigates to separate page)
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SemuaUlasanPage(
                    productId: widget.productId,
                  ),
                ),
              ),
              child: const Text(
                'Lihat Semua Ulasan',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get stock value as integer
    int stockQuantity =
        int.tryParse(product?['quantity']?.toString() ?? '0') ?? 0;
    bool isOutOfStock = stockQuantity <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            const Text("Detail Produk", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              favoriteProductIds.contains(widget.productId)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: favoriteProductIds.contains(widget.productId)
                  ? Colors.red
                  : Colors.grey,
            ),
            onPressed: () => handleFavoriteToggle(widget.productId),
          ),
          // Fixed cart navigation with proper userId parameter
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: _navigateToCart,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  _buildProductImageGallery(),
                  const SizedBox(height: 8),
                  // Replace the product information container section in your build method with this:

                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ]),
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product?['nama'] ?? 'Batik',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rp.${double.parse(product?['harga'] ?? '0').toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              "Stok: ",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "$stockQuantity",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock ? Colors.red : Colors.blue,
                              ),
                            ),
                            if (isOutOfStock)
                              const Text(
                                " (Habis)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8), // Space between stock and weight
                        Row(
                          children: [
                            const Text(
                              "Berat: ",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${product?['berat'] ?? 0} gram",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product?['deskripsi'] ?? 'Deskripsi tidak tersedia.',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2), spreadRadius: 2),
                    ]),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Beri rating produk ini',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TulisUlasanPage(
                                      productId: product!['id'],
                                    ),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Icon(Icons.star_border,
                                    color: Colors.amber, size: 35),
                              ),
                            );
                          }),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TulisUlasanPage(productId: product!['id']),
                              ),
                            ),
                            child: const Text(
                              'Tulis Ulasan',
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReviewsSection(),
                  const SizedBox(height: 0), // Space for bottom buttons
                ],
              ),
            ),
      bottomNavigationBar: isOutOfStock 
          ? Container(
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.grey,
              ),
              child: const Center(
                child: Text(
                  'Stok Habis',
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Add to Cart Button
                  Expanded(
                    child: InkWell(
                      onTap: () => _showQuantityBottomSheet(isForCart: true),
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Keranjang',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Buy Now Button
                  Expanded(
                    child: InkWell(
                      onTap: () => _showQuantityBottomSheet(isForCart: false),
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                        ),
                        child: const Center(
                          child: Text(
                            'Beli Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}