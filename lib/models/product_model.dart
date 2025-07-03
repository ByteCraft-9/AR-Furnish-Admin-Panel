class ProductModel {
  final String docId; // Firestore document ID
  final int id; // Auto-incrementing integer ID
  final String name;
  final double price;
  final String description;
  final String category;
  final String color;
  final String featuredImage;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isEnabled;
  final int quantity;

  ProductModel({
    required this.docId,
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.color,
    required this.featuredImage,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.quantity,
    this.isEnabled = true,
  });

  // Convert from Firestore document to ProductModel
  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      docId: docId,
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      color: map['color'] ?? '',
      featuredImage: map['feature_image'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['review_count'] ?? 0,
      quantity: map['quantity'] ?? 0,
      isEnabled: map['is_enabled'] ?? true,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'color': color,
      'feature_image': featuredImage,
      'images': images,
      'rating': rating,
      'review_count': reviewCount,
      'quantity': quantity,
      'is_enabled': isEnabled,
    };
  }

  // Create a copy of this ProductModel with given fields replaced with new values
  ProductModel copyWith({
    String? docId,
    int? id,
    String? name,
    double? price,
    String? description,
    String? category,
    String? color,
    String? featuredImage,
    List<String>? images,
    double? rating,
    int? reviewCount,
    int? quantity,
    bool? isEnabled,
  }) {
    return ProductModel(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      featuredImage: featuredImage ?? this.featuredImage,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      quantity: quantity ?? this.quantity,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
