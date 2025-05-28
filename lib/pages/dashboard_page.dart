import 'package:flutter/material.dart';
import 'favorit_page.dart';
import 'setting_page.dart';
import 'search_page.dart';
import '../widgets/product_card.dart';
import '../models/product_model.dart'; // Product utama dari model
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_page.dart' as cart; // Gunakan alias untuk cart_page

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // Menyimpan instance dari setiap halaman
  final List<Widget> _pages = const [
    DashboardView(),
    FavoritPage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black87,
        showUnselectedLabels: true,
        selectedFontSize: 12,
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
                const SizedBox(height: 4),
              ],
            ),
            label: "Dashboard",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_add_outlined),
            label: "Favoritku",
          ),
         
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Setting",
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // Data variables
  List<Product> products = [];
  List<Product> filteredProducts = []; 
  Set<int> favoriteProductIds = {};
  List<String> searchHistory = [];

  // UI state variables
  bool isLoading = true;
  String? errorMessage;
  String userName = "Pengguna";
  bool showSearchHistory = false;
  bool showFilterOptions = false;

  // Filter state variables
  RangeValues priceRange = const RangeValues(0, 5000000);
  double minRating = 0;

  // Controllers
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSearchHistory();
    // Tambahan ini untuk memastikan filter tidak muncul di awal
    showFilterOptions = false;
    showSearchHistory = false;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        // Load user data
        final user = await UserService.fetchUser(userId);
        if (user != null) {
          setState(() {
            userName = user.nama;
          });
        }

        // Load favorites
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

        // Set price range based on available products
        if (products.isNotEmpty) {
          double maxPrice = products
              .map((p) => p.harga)
              .reduce((value, element) => value > element ? value : element);
          priceRange = RangeValues(0, maxPrice);
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Search history methods
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', searchHistory);
  }

  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;

    setState(() {
      searchHistory.remove(query);
      searchHistory.insert(0, query);
      if (searchHistory.length > 10) {
        searchHistory = searchHistory.sublist(0, 10);
      }
    });
    _saveSearchHistory();
  }

  void _removeFromSearchHistory(String query) {
    setState(() {
      searchHistory.remove(query);
    });
    _saveSearchHistory();
  }

  void _clearSearchHistory() {
    setState(() {
      searchHistory.clear();
    });
    _saveSearchHistory();
  }

  // Filter methods
  void _filterProducts(String query) {
    if (query.isNotEmpty) {
      _addToSearchHistory(query);
    }

    _applyFilters(query);
    setState(() {
      showSearchHistory = false;
    });
  }

  void _applyFilters([String? query]) {
    setState(() {
      filteredProducts = products.where((product) {
        // Text search filter
        bool matchesQuery = true;
        if (query != null && query.isNotEmpty) {
          matchesQuery =
              product.nama.toLowerCase().contains(query.toLowerCase());
        }

        // Price range filter
        bool matchesPrice = product.harga >= priceRange.start &&
            product.harga <= priceRange.end;

        // Rating filter
        bool matchesRating = product.rating >= minRating;

        return matchesQuery && matchesPrice && matchesRating;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      if (products.isNotEmpty) {
        double maxPrice = products
            .map((p) => p.harga)
            .reduce((value, element) => value > element ? value : element);
        priceRange = RangeValues(0, maxPrice);
      }
      minRating = 0;
      _applyFilters(searchController.text);
    });
  }

  // UI interaction methods
  void _toggleFavorite(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(),

            // Search History
            if (showSearchHistory && searchHistory.isNotEmpty)
              _buildSearchHistory(),

            // Filter Options
            if (showFilterOptions) _buildFilterOptions(),

            // Welcome Banner
            if (!showSearchHistory && !showFilterOptions) _buildWelcomeBanner(),

            // Product Grid
            if (!showSearchHistory && !showFilterOptions) _buildProductGrid(),
          ],
        ),
      ),
    );
  }

// Update the _buildSearchBar method in DashboardView
Widget _buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Cari batik...",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Tombol keranjang - Updated with userId parameter
        GestureDetector(
          onTap: () async {
            // Get userId from SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getInt('user_id');
            
            if (userId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => cart.CartPage(userId: userId), // Gunakan alias cart
                ),
              );
            } else {
              // Handle case when user is not logged in
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Silakan login terlebih dahulu'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.grey),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSearchHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Pencarian Terakhir",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text(
                    "Hapus Semua",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchHistory.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Colors.grey,
                  size: 18,
                ),
                title: Text(
                  searchHistory[index],
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _removeFromSearchHistory(searchHistory[index]);
                  },
                ),
                onTap: () {
                  searchController.text = searchHistory[index];
                  _filterProducts(searchHistory[index]);
                },
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text("Reset"),
              ),
            ],
          ),
          const Divider(),

          // Price Range Filter
          const Text(
            "Harga",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rp. ${priceRange.start.round()}",
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                "Rp. ${priceRange.end.round()}",
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: priceRange,
            min: 0,
            max: products.isNotEmpty
                ? products.map((p) => p.harga).reduce(
                    (value, element) => value > element ? value : element)
                : 5000000,
            divisions: 10,
            labels: RangeLabels(
              "Rp ${priceRange.start.round()}",
              "Rp ${priceRange.end.round()}",
            ),
            onChanged: (RangeValues values) {
              setState(() {
                priceRange = values;
              });
            },
            onChangeEnd: (RangeValues values) {
              _applyFilters(searchController.text);
            },
          ),

          // Rating Filter
          const Text(
            "Rating",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: minRating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: minRating.toString(),
                  onChanged: (double value) {
                    setState(() {
                      minRating = value;
                    });
                  },
                  onChangeEnd: (double value) {
                    _applyFilters(searchController.text);
                  },
                ),
              ),
              Row(
                children: [
                  Text(
                    minRating.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.amber),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _applyFilters(searchController.text);
                  setState(() {
                    showFilterOptions = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Terapkan Filter"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  

Widget _buildWelcomeBanner() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
    child: Stack(
      children: [
        // Background SVG
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/banner.png', // Ganti sesuai nama file PNG kamu
            width: double.infinity,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        // Text di atasnya
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hi $userName",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5,),
                  const Text(
                    "Selamat datang",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            "Produk batik kami",
            style: GoogleFonts.varelaRound(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
            ),
                      ),
          ),
          const SizedBox(height: 10),
          filteredProducts.isEmpty
              ? _buildEmptyProductState()
              : _buildProductGridView(),
        ],
      ),
    );
  }

  Widget _buildEmptyProductState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              "Tidak ada produk yang ditemukan",
              style: TextStyle(fontSize: 16),
            ),
            if (searchController.text.isNotEmpty)
              Text(
                "untuk pencarian '${searchController.text}'",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridView() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisExtent: 230,
        crossAxisSpacing: 0,
        mainAxisSpacing: 5,
      ),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return ProductCard(
          product: product,
          isFavorite: favoriteProductIds.contains(product.id),
          onFavoriteToggle: () => _toggleFavorite(product.id),
        );
      },
    );
  }
}