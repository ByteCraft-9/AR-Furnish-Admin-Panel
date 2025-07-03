import 'package:cloud_firestore/cloud_firestore.dart';

class AIModelData {
  final String id;
  final Timestamp createdAt;
  final String outputImageUrl;
  final double processingTimeInSeconds;
  final String prompt;
  final String theme;
  final String userId;
  String? userName; // Will be populated from users collection

  AIModelData({
    required this.id,
    required this.createdAt,
    required this.outputImageUrl,
    required this.processingTimeInSeconds,
    required this.prompt,
    required this.theme,
    required this.userId,
    this.userName,
  });

  factory AIModelData.fromMap(Map<String, dynamic> map, String documentId) {
    return AIModelData(
      id: documentId,
      createdAt: map['createdAt'] as Timestamp,
      outputImageUrl: map['outputImageUrl'] as String,
      processingTimeInSeconds:
          (map['processingTimeInSeconds'] as num).toDouble(),
      prompt: map['prompt'] as String,
      theme: map['theme'] as String,
      userId: map['userId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'outputImageUrl': outputImageUrl,
      'processingTimeInSeconds': processingTimeInSeconds,
      'prompt': prompt,
      'theme': theme,
      'userId': userId,
    };
  }
}
