import 'package:flutter/material.dart';
import 'package:umkm_batik/widgets/product_card.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  List<Product> _favoriteProducts = [];
  Set<int> _favoriteIds = {};
  int? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');

    if (_userId != null) {
      final allProducts = await ProductService.fetchProducts();
      final favoriteIds = await UserService.getFavorites(_userId!);

      final favorites = allProducts
          .where((product) => favoriteIds.contains(product.id))
          .toList();

      setState(() {
        _favoriteProducts = favorites;
        _favoriteIds = favoriteIds;
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite(int productId) async {
    if (_userId != null) {
      await UserService.toggleFavorite(_userId!, productId);
      await _loadFavorites(); // refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Favoritku",
                      style: GoogleFonts.fredokaOne(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _favoriteProducts.isEmpty
                            ? const Text('Belum ada produk favorit.')
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _favoriteProducts.length,
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 250,
                                  mainAxisExtent: 230,
                                  crossAxisSpacing: 0,
                                  mainAxisSpacing: 5,
                                ),
                                itemBuilder: (context, index) {
                                  final product = _favoriteProducts[index];
                                  return ProductCard(
                                    product: product,
                                    isFavorite: _favoriteIds.contains(product.id),
                                    onFavoriteToggle: () => _toggleFavorite(product.id),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
