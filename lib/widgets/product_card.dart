import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Batik-Indonesia.jpg/640px-Batik-Indonesia.jpg',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Nama Produk
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Batik Jeruk", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Rating & Bookmark
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Rating ⭐ 4.2"),
                Icon(Icons.bookmark_border),
              ],
            ),
          ),

          // Tombol Berikan Rating
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {},
                child: Text("Berikan Rating", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
