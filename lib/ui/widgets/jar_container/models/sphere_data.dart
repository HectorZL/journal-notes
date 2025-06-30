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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SphereData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          emoji == other.emoji &&
          color == other.color &&
          size == other.size;

  @override
  int get hashCode => Object.hash(id, emoji, color, size);
}
