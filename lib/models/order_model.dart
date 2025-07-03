class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String? shippingAddress;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final String
      status; // pending, confirmed, processing, shipped, delivered, cancelled
  final String paymentMethod;
  final String paymentStatus; // pending, paid, failed
  final String? paymentId;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    this.shippingAddress,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      userPhone: json['userPhone'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      paymentId: json['paymentId'] as String?,
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          (json['createdAt'] as Map<String, dynamic>).containsKey('_seconds')
              ? DateTime.fromMillisecondsSinceEpoch(
                  (json['createdAt']['_seconds'] as int) * 1000)
              : DateTime.parse(json['createdAt'].toDate().toString()),
      updatedAt:
          (json['updatedAt'] as Map<String, dynamic>).containsKey('_seconds')
              ? DateTime.fromMillisecondsSinceEpoch(
                  (json['updatedAt']['_seconds'] as int) * 1000)
              : DateTime.parse(json['updatedAt'].toDate().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'shippingAddress': shippingAddress,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? shippingAddress,
    double? subtotal,
    double? tax,
    double? shipping,
    double? discount,
    double? total,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentId,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shipping: shipping ?? this.shipping,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double total;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}
