import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SemuaUlasanPage extends StatefulWidget {
  final int productId;
  const SemuaUlasanPage({super.key, required this.productId});

  @override
  State<SemuaUlasanPage> createState() => _SemuaUlasanPageState();
}

class _SemuaUlasanPageState extends State<SemuaUlasanPage> {
  List<dynamic> allReviews = [];
  List<dynamic> filteredReviews = [];
  bool isLoading = true;
  int? selectedRating;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final response = await http.get(
      Uri.parse(
          "http://192.168.1.3/umkm_batik/API/get_reviews.php?product_id=${widget.productId}"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        setState(() {
          allReviews = data;
          filteredReviews = data;
          isLoading = false;
        });
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat ulasan")),
      );
    }
  }

  void filterReviews(int? rating) {
    setState(() {
      selectedRating = rating;
      if (rating == null) {
        filteredReviews = allReviews;
      } else {
        filteredReviews = allReviews
            .where(
                (review) => int.tryParse(review['rating'].toString()) == rating)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDEF1FF),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Rating
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ratingFilterButton(
                            'Semua', selectedRating == null, null),
                        _ratingFilterButton('5 ⭐', selectedRating == 5, 5),
                        _ratingFilterButton('4 ⭐', selectedRating == 4, 4),
                        _ratingFilterButton('3 ⭐', selectedRating == 3, 3),
                        _ratingFilterButton('2 ⭐', selectedRating == 2, 2),
                        _ratingFilterButton('1 ⭐', selectedRating == 1, 1),
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
                    child: filteredReviews.isEmpty
                        ? const Center(child: Text("Belum ada ulasan."))
                        : ListView.builder(
                            itemCount: filteredReviews.length,
                            itemBuilder: (context, index) {
                              final ulasan = filteredReviews[index];
                              return _buildReviewCard(ulasan);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // Tombol filter rating
  Widget _ratingFilterButton(String label, bool isSelected, int? ratingValue) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => filterReviews(ratingValue),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          side: const BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  // Widget untuk satu review
  Widget _buildReviewCard(dynamic ulasan) {
    int rating = int.tryParse(ulasan['rating'].toString()) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 0,
              offset: const Offset(0, 3),
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
                children: [
                  Text(
                    ulasan['nama'] ?? 'Pengguna',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      rating,
                      (index) =>
                          const Icon(Icons.star, color: Colors.blue, size: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ulasan['komentar'] ?? '',
                    style: const TextStyle(fontSize: 13),
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
