import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';

class StatsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  StatsService();

  // Get mood statistics for a specific time period
  Future<Map<String, dynamic>> getMoodStats(int? userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Check if user ID is valid
      if (userId == null) {
        debugPrint('Error: User ID is null in getMoodStats');
        throw Exception('No se pudo obtener el ID del usuario. Por favor, inicia sesión nuevamente.');
      }
      
      // Initialize date formatting for Spanish locale
      await initializeDateFormatting('es_ES', null);
      
      // Get stats from database
      final stats = await _dbHelper.getStats(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      debugPrint('Retrieved stats for user $userId: $stats');

      // Process mood distribution
      final moodDistribution = _processMoodDistribution(
        stats['moodDistribution'] as List<Map<String, dynamic>>,
      );

      // Process notes per day
      final notesPerDay = _processNotesPerDay(
        stats['notesPerDay'] as List<Map<String, dynamic>>,
      );

      // Get most common mood
      final mostCommonMood = _getMostCommonMood(moodDistribution);

      return {
        'moodDistribution': moodDistribution,
        'notesPerDay': notesPerDay,
        'mostCommonMood': mostCommonMood,
        'totalNotes': notesPerDay.fold(0, (sum, day) => sum + (day['count'] as int)),
        'averageMood': _calculateAverageMood(moodDistribution),
      };
    } catch (e) {
      throw Exception('Error fetching mood statistics: $e');
    }
  }

  // Get weekly mood statistics
  Future<Map<String, dynamic>> getWeeklyStats(int? userId) async {
    if (userId == null) {
      debugPrint('Error: User ID is null in getWeeklyStats');
      return {
        'moodDistribution': [],
        'notesPerDay': [],
        'mostCommonMood': null,
        'totalNotes': 0,
        'averageMood': 0.0,
      };
    }
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getMoodStats(
      userId,
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: now,
    );
  }

  // Get monthly mood statistics
  Future<Map<String, dynamic>> getMonthlyStats(int? userId) async {
    if (userId == null) {
      debugPrint('Error: User ID is null in getMonthlyStats');
      return {
        'moodDistribution': [],
        'notesPerDay': [],
        'mostCommonMood': null,
        'totalNotes': 0,
        'averageMood': 0.0,
      };
    }
    final now = DateTime.now();
    return getMoodStats(
      userId,
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );
  }

  // Process mood distribution data
  List<Map<String, dynamic>> _processMoodDistribution(List<Map<String, dynamic>> rawData) {
    // Initialize mood distribution with all possible moods (0-4)
    final moodDistribution = List.generate(5, (index) => {
      'moodIndex': index,
      'count': 0,
      'percentage': 0.0,
    });

    // Calculate total count
    final total = rawData.fold<int>(0, (sum, item) => sum + (item['count'] as int));

    // Update mood distribution with actual data
    for (final item in rawData) {
      final moodIndex = item['mood_index'] as int;
      if (moodIndex >= 0 && moodIndex < moodDistribution.length) {
        final count = item['count'] as int;
        moodDistribution[moodIndex] = {
          'moodIndex': moodIndex,
          'count': count,
          'percentage': total > 0 ? (count / total) * 100 : 0.0,
        };
      }
    }

    return moodDistribution;
  }

  // Process notes per day data
  List<Map<String, dynamic>> _processNotesPerDay(List<Map<String, dynamic>> rawData) {
    return rawData.map((day) {
      final date = DateTime.parse(day['day'] as String);
      return {
        'date': date,
        'count': day['count'] as int,
        'formattedDate': DateFormat('EEEE, d MMMM', 'es_ES').format(date),
        'shortDate': DateFormat('MMM d', 'es_ES').format(date),
      };
    }).toList();
  }

  // Get most common mood from distribution
  Map<String, dynamic>? _getMostCommonMood(List<Map<String, dynamic>> moodDistribution) {
    if (moodDistribution.isEmpty) return null;
    
    moodDistribution.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return moodDistribution.first;
  }

  // Calculate average mood
  double _calculateAverageMood(List<Map<String, dynamic>> moodDistribution) {
    if (moodDistribution.isEmpty) return 0.0;
    
    final total = moodDistribution.fold<int>(0, (sum, mood) => sum + (mood['count'] as int));
    if (total == 0) return 0.0;
    
    final weightedSum = moodDistribution.fold<double>(
      0.0,
      (sum, mood) => sum + (mood['moodIndex'] as int) * (mood['count'] as int),
    );
    
    return weightedSum / total;
  }
}

// Provider for StatsService
final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService();
});
