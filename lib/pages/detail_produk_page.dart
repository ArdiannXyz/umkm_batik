import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'semua_ulasan_page.dart';
import 'berikan_ulasan_page.dart';
import 'checkout_page.dart';

class DetailProdukPage extends StatefulWidget {
  final int productId;

  const DetailProdukPage({super.key, required this.productId});

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage> {
  Map<String, dynamic>? product;
  List<dynamic> ulasanList = [];
  bool isLoading = true;
  int currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchProduct();
    fetchUlasan();
  }

  Future<void> fetchProduct() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://192.168.231.254/umkm_batik/API/get_detail_produk.php?id=${widget.productId}"),
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
    final response = await http.get(Uri.parse(
        'http://192.168.231.254/umkm_batik/API/get_reviews.php?product_id=${widget.productId}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        setState(() {
          ulasanList = data;
        });
      }
    }
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

          // Pagination dots for multiple images
          if (product!['images'].length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  product!['images'].length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentImageIndex == index
                          ? Colors.blue
                          : Colors.grey.withOpacity(0.0),
                    ),
                  ),
                ),
              ),
            ),

          // Left and right navigation arrows for multiple images
          if (product!['images'].length > 1) ...[
            // Left arrow
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  if (currentImageIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Right arrow
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  if (currentImageIndex < product!['images'].length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  // Using our enhanced product image gallery
                  _buildProductImageGallery(),

                  // Adding spacing between image and title/price container
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 0,
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
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.star_border,
                                    color: Colors.amber, size: 40),
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
                  Container(
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2), spreadRadius: 2),
                    ]),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ulasan Produk',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text('${product?['rating'] ?? 0.0}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: ulasanList.map((ulasan) {
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.blueGrey,
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ulasan['nama'] ?? 'Pengguna',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: List.generate(
                                              int.tryParse(ulasan['rating']
                                                      .toString()) ??
                                                  0,
                                              (index) => const Icon(Icons.star,
                                                  size: 14,
                                                  color: Colors.amber),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ulasan['komentar'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SemuaUlasanPage(
                                    productId: widget.productId),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Text('Lihat Semua Ulasan Produk',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(color: Colors.blue),
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24)),
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
                                    bottom: MediaQuery.of(context)
                                            .viewInsets
                                            .bottom +
                                        16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Use our enhanced thumbnail method
                                          _buildThumbnailInBottomSheet(),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Rp.${double.parse(product?['harga'] ?? '0').toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                    "Stok : ${product?['stok_id'] ?? 0}",
                                                    style: const TextStyle(
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Jumlah",
                                              style: TextStyle(fontSize: 16)),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  if (jumlah > 1) {
                                                    setModalState(
                                                        () => jumlah--);
                                                  }
                                                },
                                                icon: const Icon(
                                                    Icons.arrow_left),
                                              ),
                                              Text(jumlah.toString(),
                                                  style: const TextStyle(
                                                      fontSize: 16)),
                                              IconButton(
                                                onPressed: () {
                                                  int stok = int.tryParse(
                                                          product?['stok_id']
                                                                  .toString() ??
                                                              '0') ??
                                                      0;
                                                  if (jumlah < stok) {
                                                    setModalState(
                                                        () => jumlah++);
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              "Jumlah melebihi stok tersedia")),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(
                                                    Icons.arrow_right),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CheckoutPage()),
                                            );
                                          },
                                          child: const Text("Bayar Sekarang",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Center(
                          child: Text('Pesan Sekarang',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
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
