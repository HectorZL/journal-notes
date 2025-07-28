import 'package:flutter/material.dart';

class Note {
  final int? id; // This will be the primary key from the database
  final String uuid; // For temporary reference before saving to DB
  final int userId;
  final String content;
  final DateTime date;
  final int moodIndex;
  final String? tags;
  final Color color;

  Note({
    this.id,
    String? uuid,
    required this.userId,
    required this.content,
    required this.date,
    required this.moodIndex,
    this.tags,
    required this.color,
  }) : uuid = uuid ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert Note to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'note_id': id,
      'user_id': userId,
      'content': content,
      'date': date.toIso8601String(),
      'mood_index': moodIndex,
      'tags': tags,
      'color': color.toARGB32(),
    };
  }

  // Create a Note from a database map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      uuid: map['note_id']?.toString() ?? '',
      userId: map['user_id'] is int ? map['user_id'] : int.tryParse(map['user_id']?.toString() ?? '-1') ?? -1,
      content: map['content'] ?? '',
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      moodIndex: map['mood_index'] is int ? map['mood_index'] : int.tryParse(map['mood_index']?.toString() ?? '0') ?? 0,
      tags: map['tags'],
      color: map['color'] != null 
          ? Color(map['color'] is int ? map['color'] : int.tryParse(map['color'].toString()) ?? 0xFF0000FF)
          : Colors.blue,
    );
  }

  // For backward compatibility with SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': uuid,
      'user_id': userId,
      'content': content,
      'date': date.toIso8601String(),
      'mood_index': moodIndex,
      'tags': tags,
      'color': color.toARGB32(),
    };
  }

  // For backward compatibility with SharedPreferences
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      uuid: json['id'],
      userId: json['user_id'] ?? -1, // -1 will be replaced with actual user ID
      content: json['content'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      moodIndex: json['mood_index'] ?? 0,
      tags: json['tags'],
      color: json['color'] != null 
          ? Color(json['color'] as int) 
          : Colors.blue,
    );
  }

  // Create a copy of the note with updated fields
  Note copyWith({
    int? id,
    String? uuid,
    int? userId,
    String? content,
    DateTime? date,
    int? moodIndex,
    String? tags,
    Color? color,
  }) {
    return Note(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      date: date ?? this.date,
      moodIndex: moodIndex ?? this.moodIndex,
      tags: tags ?? this.tags,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Note &&
        other.id == id &&
        other.userId == userId &&
        other.content == content &&
        other.date == date &&
        other.moodIndex == moodIndex;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        content.hashCode ^
        date.hashCode ^
        moodIndex.hashCode;
  }
}
