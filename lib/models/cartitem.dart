class CartItem {
  final int id; // cart_id
  final int productId;
  final int quantity;
  final double subtotal;
  final int totalWeight; // Tambahan untuk total berat item
  final String addedAt;
  final String? updatedAt;
  final bool isAvailable;
  final Product product;
  bool isSelected; // Tambahan untuk checkbox selection

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.subtotal,
    required this.totalWeight, // Tambahan
    required this.addedAt,
    this.updatedAt,
    required this.isAvailable,
    required this.product,
    this.isSelected = false, // Default tidak terpilih
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['cart_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalWeight: json['total_weight'] ?? 0, // Tambahan
      addedAt: json['added_at'] ?? '',
      updatedAt: json['updated_at'],
      isAvailable: json['is_available'] ?? false,
      product: Product.fromJson(json['product'] ?? {}),
      isSelected: false,
    );
  }

  String? get productName => product.nama;
  double? get productPrice => product.harga;
  String get productImage => product.mainImageUrl.isNotEmpty ? product.mainImageUrl : '';
  
  double get price => product.harga; 
  int get weight => product.berat; // Ubah dari weight ke berat sesuai backend
  String get nama => product.nama;
}

class Product {
  final int id;
  final String nama;
  final String? deskripsi;
  final double harga;
  final int stokId;
  final String? status;
  final double? rating;
  final String? createdAt;
  final Stock stock;
  final int berat; // Ubah dari weight ke berat sesuai backend
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.harga,
    required this.stokId,
    this.status,
    this.rating,
    this.createdAt,
    required this.stock,
    required this.berat, // Ubah dari weight ke berat
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      deskripsi: json['deskripsi'],
      harga: (json['harga'] ?? 0).toDouble(),
      stokId: json['stok_id'] ?? 0,
      status: json['status'],
      rating: json['rating']?.toDouble(),
      createdAt: json['created_at'],
      stock: Stock.fromJson(json['stock'] ?? {}),
      berat: json['berat'] ?? 0, // Ubah dari weight ke berat sesuai backend
      images: (json['images'] as List?)
          ?.map((img) => ProductImage.fromJson(img))
          .toList() ?? [],
    );
  }

  // Getter untuk kompatibilitas dengan kode lama yang masih menggunakan weight
  int get weight => berat;

  // Getter untuk mendapatkan URL gambar utama
  String get mainImageUrl {
    if (images.isEmpty) return '';
    
    // Cari gambar utama terlebih dahulu
    try {
      final mainImage = images.firstWhere(
        (img) => img.isMain,
        orElse: () => images.first,
      );
      return mainImage.imageUrl.isNotEmpty ? mainImage.imageUrl : '';
    } catch (e) {
      return '';
    }
  }
}

class Stock {
  final int quantity;
  final String? updatedAt;
  final bool isSufficient;

  Stock({
    required this.quantity,
    this.updatedAt,
    required this.isSufficient,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      quantity: json['quantity'] ?? 0,
      updatedAt: json['updated_at'],
      isSufficient: json['is_sufficient'] ?? false,
    );
  }
}

class ProductImage {
  final int id;
  final String imageUrl;
  final bool isMain;

  ProductImage({
    required this.id,
    required this.imageUrl,
    required this.isMain,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      isMain: json['is_main'] ?? false,
    );
  }
}

class CartSummary {
  final int totalItems;
  final int totalQuantity;
  final double totalAmount;
  final int totalWeight; // Tambahan untuk total berat
  final int availableItems;
  final double availableTotalAmount;
  final int availableTotalWeight; // Tambahan untuk total berat item available
  final bool hasUnavailableItems;

  CartSummary({
    required this.totalItems,
    required this.totalQuantity,
    required this.totalAmount,
    required this.totalWeight, // Tambahan
    required this.availableItems,
    required this.availableTotalAmount,
    required this.availableTotalWeight, // Tambahan
    required this.hasUnavailableItems,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      totalItems: json['total_items'] ?? 0,
      totalQuantity: json['total_quantity'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      totalWeight: json['total_weight'] ?? 0, // Tambahan
      availableItems: json['available_items'] ?? 0,
      availableTotalAmount: (json['available_total_amount'] ?? 0).toDouble(),
      availableTotalWeight: json['available_total_weight'] ?? 0, // Tambahan
      hasUnavailableItems: json['has_unavailable_items'] ?? false,
    );
  }

  // Getter untuk kompatibilitas dengan kode lama
  double? get totalPrice => totalAmount;
}

// Alias untuk kompatibilitas dengan kode checkout yang menggunakan 'cartItems'
// Buat class alias dengan nama yang sama persis seperti di checkout
class cartItems extends CartItem {
  cartItems({
    required super.id,
    required super.productId,
    required super.quantity,
    required super.subtotal,
    required super.totalWeight, // Tambahan
    required super.addedAt,
    super.updatedAt,
    required super.isAvailable,
    required super.product,
    super.isSelected = false,
  });

  factory cartItems.fromJson(Map<String, dynamic> json) {
    final cartItem = CartItem.fromJson(json);
    return cartItems(
      id: cartItem.id,
      productId: cartItem.productId,
      quantity: cartItem.quantity,
      subtotal: cartItem.subtotal,
      totalWeight: cartItem.totalWeight, // Tambahan
      addedAt: cartItem.addedAt,
      updatedAt: cartItem.updatedAt,
      isAvailable: cartItem.isAvailable,
      product: cartItem.product,
      isSelected: cartItem.isSelected,
    );
  }
}