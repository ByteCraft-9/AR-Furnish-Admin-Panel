class PromotionModel {
  final String id;
  final String promotionName;
  final double price;
  final double discount;
  final String duration;
  final List<String> imageUrls;

  PromotionModel({
    required this.id,
    required this.promotionName,
    required this.price,
    required this.discount,
    required this.duration,
    required this.imageUrls,
  });

  // Convert from Firestore document to PromotionModel
  factory PromotionModel.fromMap(Map<String, dynamic> map, String id) {
    return PromotionModel(
      id: id,
      promotionName: map['promotion_name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      duration: map['duration'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? []),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'promotion_name': promotionName,
      'price': price,
      'discount': discount,
      'duration': duration,
      'image_urls': imageUrls,
    };
  }

  // Create a copy of this PromotionModel with given fields replaced with new values
  PromotionModel copyWith({
    String? id,
    String? promotionName,
    double? price,
    double? discount,
    String? duration,
    List<String>? imageUrls,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      promotionName: promotionName ?? this.promotionName,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      duration: duration ?? this.duration,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
