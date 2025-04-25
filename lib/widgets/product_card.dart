import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Tetap
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 5,vertical: 5),
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
            padding: const EdgeInsets.symmetric( vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 10),
                Text(
                  "Batik Jeruk",
                  style: GoogleFonts.fredokaOne(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 25),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Gambar produk yang fleksibel menyesuaikan sisa ruang
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              child: Image.asset(
                'assets/images/ado2.jpg',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                
                Text(
                  "Klik untuk lebih lanjut",
                  
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
                Text("⭐ 4.2", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
