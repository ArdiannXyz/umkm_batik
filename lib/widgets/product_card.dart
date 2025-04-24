import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Mengatur Column agar tidak memanjang ke bawah
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama Produk dan Icon Bookmark di sebelah kanan
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Batik Jeruk",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)), // Nama produk
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ), // Icon bookmark di sebelah kanan
              ],
            ),
          ),

          // Gambar Produk
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(
              'assets/images/ado2.jpg',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Rating di sebelah kanan dan "Klik untuk lebih lanjut" di kiri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Klik untuk lebih lanjut",
                    style: TextStyle(fontSize: 10, color: Colors.blue)),
                Text("Rating ⭐ 4.2", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
