import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../pages/detail_produk_page.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final Function()? onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Mendapatkan gambar utama dari produk (jika ada)
    Uint8List? imageBytes;
    if (product.images != null && product.images!.isNotEmpty) {
      final mainImage = product.images!.firstWhere(
        (img) => img.isMain,
        orElse: () => product.images!.first,
      );

      try {
        String cleaned = mainImage.base64Image;
        if (cleaned.contains(',')) {
          cleaned = cleaned.split(',').last;
        }
        imageBytes = base64Decode(cleaned);
      } catch (e) {
        print('Gagal decode base64: $e');
      }
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
                      style: GoogleFonts.fredokaOne(
                        fontWeight: FontWeight.normal,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(2)),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/brokenimage.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          // Footer dengan navigasi ke detail
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailProdukPage(productId: product.id),
                      ),
                    );
                  },
                  child: const Text(
                    "Klik untuk lebih lanjut",
                    style: TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
                Text(
                  "⭐ ${product.rating.toStringAsFixed(1)}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
