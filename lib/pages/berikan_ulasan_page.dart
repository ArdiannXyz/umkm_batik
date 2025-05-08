import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import EditUlasanPage
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
    try {
      final url =
          Uri.parse("http://localhost/umkm_batik/API/check_reviews.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'product_id': widget.productId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        // Print response for debugging
        print("API Response: ${response.body}");

        final result = jsonDecode(response.body);

        setState(() {
          hasReviewed = result['has_reviewed'] ?? false;

          // Simpan data ulasan jika ada
          if (hasReviewed && result['review_data'] != null) {
            existingReview = Map<String, dynamic>.from(result['review_data']);
            print("Existing Review Data: $existingReview");
          }

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Gagal memeriksa status ulasan: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Terjadi kesalahan saat memeriksa status ulasan: ${e.toString()}';
        isLoading = false;
      });
    }
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

    final url = Uri.parse("http://localhost/umkm_batik/API/add_reviews.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'product_id': widget.productId,
          'user_id': userId,
          'rating': selectedRating,
          'komentar': _reviewController.text,
        }),
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ulasan berhasil dikirim')),
          );
          Navigator.pop(
              context, true); // Return true to indicate successful review
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message'] ?? 'Gagal mengirim ulasan')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Terjadi kesalahan saat mengirim ulasan')),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Fungsi untuk navigasi ke halaman edit ulasan
  void navigateToEditReview() async {
    if (existingReview == null) {
      // Debug message untuk memeriksa nilai existingReview
      print("existingReview is null - hasReviewed: $hasReviewed");

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
      backgroundColor: const Color(0xFFDEF1FF),
      appBar: AppBar(
        title: const Text('Berikan Ulasan'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
      padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      size: 42,
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
