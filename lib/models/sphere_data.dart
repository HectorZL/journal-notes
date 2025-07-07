import 'package:flutter/material.dart';

@immutable
class SphereData {
  final String emoji;
  final Color color;
  final double size;
  final String id;
  
  const SphereData({
    required this.emoji,
    required this.color, 
    this.size = 40.0,
    required this.id,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SphereData &&
        other.emoji == emoji &&
        other.color == color &&
        other.size == size &&
        other.id == id;
  }

  @override
  int get hashCode {
    return Object.hash(emoji, color, size, id);
  }
}
