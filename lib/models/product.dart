class Product {
  final String id;
  final String name;
  final double price;
  final double? price2;
  final String description;
  final String imageUrl;
  final String? category;
  final int? stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.price2,
    required this.description,
    required this.imageUrl,
    this.category,
    this.stock,
  });

  // Converte JSON para Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      price: _parseDouble(json['price']) ?? 0.0,
      price2: _parseDouble(json['price2']),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'],
      stock: json['stock'] is int ? json['stock'] : int.tryParse(json['stock']?.toString() ?? ''),
    );
  }

  // Método auxiliar para converter valores para double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Converte Product para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'price2': price2,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
    };
  }

  // Cria uma cópia do produto com novos valores
  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? price2,
    String? description,
    String? imageUrl,
    String? category,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      price2: price2 ?? this.price2,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stock: stock ?? this.stock,
    );
  }
} 