import 'package:flutter/material.dart';

const List<Color> moodColors = [
  Color(0xFF4CAF50), // Green - Happy
  Color(0xFF8BC34A), // Light Green - Content
  Color(0xFFFFC107), // Amber - Neutral
  Color(0xFFFF9800), // Orange - Sad
  Color(0xFFF44336), // Red - Very Sad
];

const List<String> moodIcons = ['😊', '🙂', '😐', '😔', '😢'];
const List<String> moodDescriptions = [
  'Feliz',
  'Contento',
  'Neutral',
  'Triste',
  'Muy triste'
];

// Animation effects for each mood
const List<Map<String, dynamic>> moodAnimations = [
  {'scale': 1.2, 'rotate': 0.1, 'bounce': 1.5}, // Happy
  {'scale': 1.1, 'rotate': 0.05, 'bounce': 1.2}, // Content
  {'scale': 1.0, 'rotate': 0.0, 'bounce': 1.0}, // Neutral
  {'scale': 0.9, 'rotate': -0.05, 'bounce': 0.9}, // Sad
  {'scale': 0.8, 'rotate': -0.1, 'bounce': 0.8}, // Very Sad
];

// Additional effects when tapped
const List<String> tapEffects = ['😄', '🙃', '🤔', '💧', '😭'];
