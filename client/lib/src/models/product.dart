class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool available;
  final bool featured;
  final int stockQuantity;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.available,
    required this.featured,
    required this.stockQuantity,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      category: json['category'] ?? '',
      available: json['available'] == 1 || json['available'] == true,
      featured: json['featured'] == 1 || json['featured'] == true,
      stockQuantity: json['stock_quantity'] ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'available': available,
      'featured': featured,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
    };
  }
}