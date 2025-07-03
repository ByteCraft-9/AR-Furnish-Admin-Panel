import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // admin, manager, staff
  final String? phone;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool>? permissions; // Store sidebar access permissions

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.phone,
    this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle timestamp conversion with null safety
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is Map && timestamp.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
            (timestamp['_seconds'] as int) * 1000);
      } else {
        return DateTime.now(); // Default to current time if invalid
      }
    }

    // Parse permissions if available
    Map<String, bool>? permissions;
    if (json['permissions'] != null) {
      permissions = Map<String, bool>.from(json['permissions']);
    }

    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? 'no-email@example.com',
      photoUrl: json['photoUrl'],
      role: json['role'] ?? 'customer',
      phone: json['phone'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? parseTimestamp(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? parseTimestamp(json['updatedAt'])
          : DateTime.now(),
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'phone': phone,
      'address': address,
      'isActive': isActive,
      'permissions': permissions,
      // createdAt and updatedAt are handled by Firestore
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    String? phone,
    String? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      permissions: permissions ?? this.permissions,
    );
  }
}
