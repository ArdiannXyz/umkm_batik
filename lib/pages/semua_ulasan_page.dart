import 'package:flutter/material.dart';

class SemuaUlasanPage extends StatelessWidget {
  const SemuaUlasanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Semua Ulasan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Rating
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ratingFilterButton('Semua', true),
                  _ratingFilterButton('5 ⭐', false),
                  _ratingFilterButton('4 ⭐', false),
                  _ratingFilterButton('3 ⭐', false),
                  _ratingFilterButton('2 ⭐', false),
                  _ratingFilterButton('1 ⭐', false),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Semua',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Daftar Ulasan
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _buildReviewCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk tombol filter rating
  Widget _ratingFilterButton(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          side: BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  // Widget untuk setiap ulasan
  Widget _buildReviewCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16), // Add padding inside the container
        decoration: BoxDecoration(
          color: Colors.white, // Set background to white
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3), // Shadow position
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ahmad Sumbul',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue, size: 16),
                      Icon(Icons.star, color: Colors.blue, size: 16),
                      Icon(Icons.star, color: Colors.blue, size: 16),
                      Icon(Icons.star, color: Colors.blue, size: 16),
                      Icon(Icons.star, color: Colors.blue, size: 16),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Batikinya dari segi kainnya lumayan bagus untuk harga segitu. Dan saya juga senang ketika mengunjungi tempatnya, pelayanannya ramah dan dengan beli batik ini bisa support umkm.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
