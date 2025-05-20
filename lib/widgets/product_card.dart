import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../pages/detail_produk_page.dart';
import '../services/product_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final Function()? onFavoriteToggle;

  const ProductCard({
    Key? key,
    required this.product, 
    this.isFavorite = false,
    this.onFavoriteToggle,
  }) : super(key: key);

  // Fungsi untuk membangun tampilan fallback jika tidak ada gambar
  Widget _buildFallbackImage(String? productName) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          productName?.isNotEmpty == true 
              ? productName!.substring(0, productName.length > 1 ? 1 : productName.length)
              : '?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan URL gambar utama dari produk
    String imageUrl = '';
    
    if (product.images != null && product.images!.isNotEmpty) {
      final mainImage = product.images!.firstWhere(
        (img) => img.isMain,
        orElse: () => product.images!.first,
      );
      
      // Menggunakan fungsi dari ProductService untuk mendapatkan URL gambar
      imageUrl = ProductService.getImageUrl(mainImage.id);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical:1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      product.nama,
                      style: GoogleFonts.varelaRound(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: onFavoriteToggle,
                ),
              ],
            ),
          ),

          // Gambar produk dengan caching
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => _buildFallbackImage(product.nama),
                        // Menyimpan cache gambar
                        cacheKey: 'product_image_${product.id}_${imageUrl.hashCode}',
                        // Menggunakan memory cache terlebih dahulu
                        memCacheWidth: 400, // Membatasi ukuran cache memory
                      )
                    : _buildFallbackImage(product.nama),
              ),
            ),
          ),
          
          // Footer dengan navigasi ke detail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailProdukPage(productId: product.id),
                      ),
                    );
                  },
                  child: const Text(
                    "Klik lebih lanjut",
                    style: TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
                Text(
                  "⭐ ${product.rating.toStringAsFixed(1)}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}