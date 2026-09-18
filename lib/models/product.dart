class Product {
  final int? id;
  final String name;
  final double price;
  final String imageUrl;

  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  Product copyWith({int? id, String? name, double? price, String? imageUrl}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Sent to the API on insert — id and created_at are handled by the DB.
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'price': price,
      'image_url': imageUrl,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
    );
  }
}
