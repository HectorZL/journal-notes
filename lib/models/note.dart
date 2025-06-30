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

  // Convert Note to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'date': date.toIso8601String(),
      'moodIndex': moodIndex,
      'color': color.value,
    };
  }

  // Create a Note from a Map
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      moodIndex: json['moodIndex'],
      color: Color(json['color']),
    );
  }

  // Create a copy of the note with updated fields
  Note copyWith({
    String? id,
    String? content,
    DateTime? date,
    int? moodIndex,
    Color? color,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      date: date ?? this.date,
      moodIndex: moodIndex ?? this.moodIndex,
      color: color ?? this.color,
    );
  }
}
