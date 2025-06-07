import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import '../widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Definisikan enum di luar class, di bagian atas file
enum SearchMode {
  suggestion, // Mode saran dan riwayat
  results, // Mode hasil pencarian
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Data variables
  List<Product> allProducts = [];
  List<Product> searchResults = [];
  List<String> searchHistory = [];
  List<String> popularKeywords = [
    'Batik Pekalongan',
    'Batik Solo',
    'Batik Tulis',
    'Batik Cap',
    'Batik Modern',
  ];
  List<String> searchSuggestions = [];
  Set<int> favoriteProductIds = {};

  // UI state variables
  bool isLoading = true;
  SearchMode currentMode = SearchMode.suggestion;
  String currentQuery = '';

  // Filter state variables
  RangeValues priceRange = const RangeValues(0, 5000000);
  double minRating = 0;
  bool showFilterOptions = false;

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Listen to text changes for suggestions
    searchController.addListener(_onSearchTextChanged);

    // Auto focus search bar when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchTextChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // Load all required data
  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadProducts(),
        _loadFavorites(),
        _loadSearchHistory(),
      ]);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    final fetchedProducts = await ProductService.GetProducts();
    setState(() {
      allProducts = fetchedProducts;

      // Set price range based on available products
      if (allProducts.isNotEmpty) {
        double maxPrice = allProducts
            .map((p) => p.harga)
            .reduce((value, element) => value > element ? value : element);
        priceRange = RangeValues(0, maxPrice);
      }
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      final favoriteIds = await UserService.fetchFavorites(userId);
      setState(() {
        favoriteProductIds = favoriteIds.toSet();
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
    if (currentQuery.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Remove if exists and add to the beginning
      searchHistory.remove(currentQuery);
      searchHistory.insert(0, currentQuery);

      // Limit history size
      if (searchHistory.length > 10) {
        searchHistory = searchHistory.sublist(0, 10);
      }
    });
    await prefs.setStringList('search_history', searchHistory);
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

  // Search functionality
  void _onSearchTextChanged() {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        searchSuggestions = [];
        currentMode = SearchMode.suggestion;
      });
      return;
    }

    // Generate suggestions based on query
    final suggestions = allProducts
        .where((product) =>
            product.nama.toLowerCase().contains(query.toLowerCase()))
        .map((product) => product.nama)
        .toSet() // Remove duplicates
        .toList();

    setState(() {
      searchSuggestions =
          suggestions.take(5).toList(); // Limit to 5 suggestions
    });
  }

  void _performSearch(String query) {
    setState(() {
      currentQuery = query.trim();
      if (currentQuery.isEmpty) return;

      // Save to history
      _saveSearchHistory();

      // Filter products
      searchResults = allProducts.where((product) {
        bool matchesQuery =
            product.nama.toLowerCase().contains(currentQuery.toLowerCase());
        bool matchesPrice = product.harga >= priceRange.start &&
            product.harga <= priceRange.end;
        bool matchesRating = product.rating >= minRating;

        return matchesQuery && matchesPrice && matchesRating;
      }).toList();

      // Change to results mode
      currentMode = SearchMode.results;

      // Clear suggestions
      searchSuggestions = [];
    });
  }

  void _applyFilters() {
    _performSearch(currentQuery);
    setState(() {
      showFilterOptions = false;
    });
  }

  void _resetFilters() {
    setState(() {
      if (allProducts.isNotEmpty) {
        double maxPrice = allProducts
            .map((p) => p.harga)
            .reduce((value, element) => value > element ? value : element);
        priceRange = RangeValues(0, maxPrice);
      }
      minRating = 0;
    });
    _performSearch(currentQuery);
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

  void _useSearchSuggestion(String suggestion) {
    searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _useHistoryItem(String historyItem) {
    searchController.text = historyItem;
    _performSearch(historyItem);
  }

  void _toggleFilterOptions() {
    setState(() {
      showFilterOptions = !showFilterOptions;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: _buildSearchAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: _buildSearchAppBar(),
      body: Column(
        children: [
          // Filter options
          if (showFilterOptions && currentMode == SearchMode.results)
            _buildFilterPanel(),

          // Content based on current mode
          Expanded(
            child: currentMode == SearchMode.suggestion
                ? _buildSuggestionsView()
                : _buildSearchResultsView(),
          ),
        ],
      ),
    );
  }

  // UI Builder methods
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        decoration: InputDecoration(
          hintText: "Cari batik...",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      currentMode = SearchMode.suggestion;
                    });
                  },
                )
              : null,
        ),
        onSubmitted: (query) {
          _performSearch(query);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.blue),
          onPressed: () {
            _performSearch(searchController.text);
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionsView() {
    return Container(
      color: Colors.white, // Tambahkan ini untuk background putih
      child: ListView(
        children: [
          // Display search suggestions if typing
          if (searchSuggestions.isNotEmpty) _buildSuggestionsList(),

          // Display search history
          if (searchHistory.isNotEmpty) _buildSearchHistorySection(),

          // Popular keywords section
          _buildPopularKeywordsSection(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            "Saran Pencarian",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: searchSuggestions.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.search, color: Colors.grey, size: 20),
              title: Text(
                searchSuggestions[index],
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () => _useSearchSuggestion(searchSuggestions[index]),
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSearchHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Riwayat Pencarian",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (searchHistory.isNotEmpty)
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: const Text(
                    "Hapus",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: searchHistory.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey, size: 20),
              title: Text(
                searchHistory[index],
                style: const TextStyle(fontSize: 14),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _removeFromSearchHistory(searchHistory[index]),
              ),
              onTap: () => _useHistoryItem(searchHistory[index]),
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildPopularKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            "Kata Kunci Populer",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularKeywords.map((keyword) {
              return InkWell(
                onTap: () => _useSearchSuggestion(keyword),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    keyword,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsView() {
    return Column(
      children: [
        // Search filters quick access
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${searchResults.length} hasil untuk \"$currentQuery\"",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: _toggleFilterOptions,
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 18,
                      color: showFilterOptions ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Filter",
                      style: TextStyle(
                        fontSize: 12,
                        color: showFilterOptions ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search results grid
        Expanded(
          child: searchResults.isEmpty
              ? _buildEmptyResultsView()
              : _buildResultsGrid(),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filter",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text("Reset"),
              ),
            ],
          ),

          // Price Range Filter
          const Text(
            "Harga",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rp ${priceRange.start.round()}",
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                "Rp ${priceRange.end.round()}",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          RangeSlider(
            values: priceRange,
            min: 0,
            max: allProducts.isNotEmpty
                ? allProducts.map((p) => p.harga).reduce(
                    (value, element) => value > element ? value : element)
                : 5000000,
            divisions: 10,
            onChanged: (RangeValues values) {
              setState(() {
                priceRange = values;
              });
            },
          ),

          // Rating Filter
          const Text(
            "Rating",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: minRating,
            min: 0,
            max: 5,
            divisions: 5,
            label: "$minRating★",
            onChanged: (double value) {
              setState(() {
                minRating = value;
              });
            },
          ),
          Text(
            "Minimal $minRating bintang",
            style: const TextStyle(fontSize: 12),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Terapkan Filter"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "Tidak ada hasil untuk \"$currentQuery\"",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Coba kata kunci lain atau ubah filter",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisExtent: 250,
        crossAxisSpacing: 0,
        mainAxisSpacing: 5,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final product = searchResults[index];
        return ProductCard(
          product: product,
          isFavorite: favoriteProductIds.contains(product.id),
          onFavoriteToggle: () => _toggleFavorite(product.id),
        );
      },
    );
  }
}
