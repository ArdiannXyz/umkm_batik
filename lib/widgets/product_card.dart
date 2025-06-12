import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../pages/detail_produk_page.dart';

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

  // Widget untuk fallback jika gambar gagal dimuat
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

  // Widget untuk menampilkan gambar dari base64
  Widget _buildProductImage() {
    // Cek apakah ada main_image_base64 dari ProductController
    if (product.mainImageBase64 != null && product.mainImageBase64!.isNotEmpty) {
      try {
        // Parse base64 string
        String base64String = product.mainImageBase64!;
        
        // Remove data URL prefix if present (data:image/jpeg;base64,)
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        
        // Decode base64
        final bytes = base64Decode(base64String);
        
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error decoding base64 image for product ${product.nama}: $error');
            return _buildFallbackImage(product.nama);
          },
        );
      } catch (e) {
        print('Error processing base64 image for product ${product.nama}: $e');
        return _buildFallbackImage(product.nama);
      }
    }
    
    // Fallback jika tidak ada gambar
    return _buildFallbackImage(product.nama);
  }

  @override
  Widget build(BuildContext context) {
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
          // Header produk
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
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

          // Gambar produk
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                child: _buildProductImage(),
              ),
            ),
          ),

          // Footer produk
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