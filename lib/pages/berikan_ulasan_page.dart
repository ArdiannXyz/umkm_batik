import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/review_service.dart';
import 'edit_ulasan_page.dart'; // Pastikan jalur import ini sesuai dengan struktur proyek Anda

class TulisUlasanPage extends StatefulWidget {
  final int productId;
  final int initialRating;

  const TulisUlasanPage({
    super.key,
    required this.productId,
    this.initialRating = 0,
  });

  @override
  State<TulisUlasanPage> createState() => _TulisUlasanPageState();
}

class _TulisUlasanPageState extends State<TulisUlasanPage> {
  late int selectedRating;
  final TextEditingController _reviewController = TextEditingController();
  int? userId;
  bool isSubmitting = false;
  bool isLoading = true;
  bool hasReviewed = false;
  String errorMessage = '';
  Map<String, dynamic>? existingReview;

  @override
  void initState() {
    super.initState();
    selectedRating = widget.initialRating;
    loadUserIdAndCheckReview();
  }

  Future<void> loadUserIdAndCheckReview() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');

      if (id == null) {
        setState(() {
          errorMessage = 'Silakan login terlebih dahulu';
          isLoading = false;
        });
        return;
      }

      setState(() {
        userId = id;
      });

      // Cek apakah user sudah memberikan ulasan
      await checkExistingReview(id);
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat memuat data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> checkExistingReview(int userId) async {
  final result = await ReviewService.checkExistingReview(
    productId: widget.productId,
    userId: userId,
  );

  setState(() {
    isLoading = false;
    if (result['success']) {
      final data = result['data'];
      hasReviewed = data['has_reviewed'] ?? false;
      if (hasReviewed && data['review_data'] != null) {
        existingReview = Map<String, dynamic>.from(data['review_data']);
      }
    } else {
      errorMessage = result['message'];
    }
  });
}


  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> submitReview() async {
  if (selectedRating == 0 ||
      _reviewController.text.isEmpty ||
      userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Harap isi semua bidang dan pilih rating')),
    );
    return;
  }

  setState(() => isSubmitting = true);

  final result = await ReviewService.submitReview(
    productId: widget.productId,
    userId: userId!,
    rating: selectedRating,
    komentar: _reviewController.text,
  );

  setState(() => isSubmitting = false);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'])),
  );

  if (result['success']) {
    Navigator.pop(context, true);
  }
}


  // Fungsi untuk navigasi ke halaman edit ulasan
  void navigateToEditReview() async {
    if (existingReview == null) {
      // Debug message untuk memeriksa nilai existingReview

      // Coba refresh data ulasan
      await loadUserIdAndCheckReview();

      // Cek lagi setelah refresh
      if (existingReview == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Data ulasan tidak ditemukan, mencoba memuat ulang...')),
        );
        return;
      }
    }

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditUlasanPage(
            productId: widget.productId,
            existingReview: existingReview!,
          ),
        ),
      );

      // Jika edit berhasil, refresh halaman ini
      if (result == true) {
        loadUserIdAndCheckReview();
      }
    } catch (e) {
      print("Error navigating to edit page: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Berikan Ulasan',
          style: TextStyle(color: Colors.white), // Perbaikan di sini
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                  ),
                )
              : hasReviewed
                  ? _buildAlreadyReviewedScreen()
                  : _buildReviewForm(),
    );
  }

  // Widget untuk tampilan "sudah memberikan ulasan" dengan tombol edit
  Widget _buildAlreadyReviewedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Anda sudah memberikan ulasan untuk produk ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              existingReview != null
                  ? 'Rating: ${existingReview!['rating']} - "${existingReview!['komentar']}"'
                  : 'Terima kasih atas partisipasi Anda dalam memberikan ulasan produk',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Container untuk menyamakan ukuran tombol
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Tombol Edit Ulasan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: navigateToEditReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Edit Ulasan',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Kembali
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Kembali',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Rating bintang
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      size: 35,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // TextField ulasan
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Deskripsikan Pengalaman Anda',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Spacer(),

          // Tombol Posting
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Posting',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
