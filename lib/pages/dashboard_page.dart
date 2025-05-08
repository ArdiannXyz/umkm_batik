import 'package:flutter/material.dart';
import 'favorit_page.dart';
import 'batik_terbaik_page.dart';
import 'setting_page.dart';
import '../widgets/product_card.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardView(),
    FavoritPage(),
    BatikTerbaikPage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // agar label selalu muncul
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue, // Warna saat dipilih
        unselectedItemColor: Colors.black87, // Warna saat tidak dipilih
        showUnselectedLabels: true,
        selectedFontSize: 12, // Ukuran font saat dipilih
        unselectedFontSize: 12,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/home_agreement.png',
                  width: 20,
                  height: 20,
                  color: _currentIndex == 0 ? Colors.blue : Colors.black87,
                ),
                SizedBox(height: 4), // Jarak antara icon dan label
              ],
            ),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_add_outlined),
            label: "Favoritku",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: "Batik terbaik",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Setting",
          ),
        ],
      ),
    );
  }
}

// Halaman Dashboard utama
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  String userName = "Pengguna";
  Set<int> favoriteProductIds = {};
  TextEditingController searchController = TextEditingController();
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load user data
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        final user = await UserService.fetchUser(userId);
        if (user != null) {
          setState(() {
            userName = user.nama;
          });
        }
        final favoriteIds = await UserService.fetchFavorites(userId);
        setState(() {
          favoriteProductIds = favoriteIds.toSet();
        });
      }

      // Load products
      final fetchedProducts = await ProductService.fetchProducts();
      setState(() {
        products = fetchedProducts;
        filteredProducts = fetchedProducts;
        isLoading = false;
      });

      // Todo: Load favorite products
      // Implementasi untuk mendapatkan daftar produk favorit pengguna
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = products;
      });
    } else {
      setState(() {
        filteredProducts = products
            .where((product) =>
                product.nama.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _toggleFavorite(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    // Panggil API untuk toggle favorite di server
    await UserService.toggleFavorite(userId, productId);

    setState(() {
      if (favoriteProductIds.contains(productId)) {
        favoriteProductIds.remove(productId);
      } else {
        favoriteProductIds.add(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Search Bar
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: "Search",
                                  prefixIcon: Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: _filterProducts,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Box Selamat datang
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const SizedBox(width: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hi $userName,",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Text(
                                    "Selamat datang",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Grid produk
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 20),
                            Text(
                              "Produk batik kami",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            filteredProducts.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        "Tidak ada produk yang ditemukan",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: filteredProducts.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 250,
                                      mainAxisExtent: 230,
                                      crossAxisSpacing: 0,
                                      mainAxisSpacing: 5,
                                    ),
                                    itemBuilder: (context, index) {
                                      final product = filteredProducts[index];
                                      return ProductCard(
                                        product: product,
                                        isFavorite: favoriteProductIds
                                            .contains(product.id),
                                        onFavoriteToggle: () =>
                                            _toggleFavorite(product.id),
                                      );
                                    },
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
