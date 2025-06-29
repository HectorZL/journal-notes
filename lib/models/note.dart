import 'package:flutter/material.dart';

class Note {
  final String id;
  final String content;
  final DateTime date;
  final int moodIndex;
  final Color color;

  Note({
    required this.id,
    required this.content,
    required this.date,
    required this.moodIndex,
    required this.color,
  });
}
