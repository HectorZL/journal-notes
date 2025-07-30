import 'dart:typed_data';

class FaceAuthModel {
  final String userId;
  final String email;
  final String faceDescriptorPath;
  final DateTime createdAt;

  FaceAuthModel({
    required this.userId,
    required this.email,
    required this.faceDescriptorPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'faceDescriptorPath': faceDescriptorPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FaceAuthModel.fromMap(Map<String, dynamic> map) {
    return FaceAuthModel(
      userId: map['userId'],
      email: map['email'],
      faceDescriptorPath: map['faceDescriptorPath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class FaceMatchResult {
  final bool isMatch;
  final double confidence;
  final String? userId;

  FaceMatchResult({
    required this.isMatch,
    required this.confidence,
    this.userId,
  });
}
