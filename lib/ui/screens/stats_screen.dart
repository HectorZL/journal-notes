import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Mock data - in a real app, this would come from your data store
  final Map<String, int> _weeklyData = {
    'Lun': 3,
    'Mar': 2,
    'Mié': 4,
    'Jue': 1,
    'Vie': 3,
    'Sáb': 2,
    'Dom': 4,
  };

  @override
  void initState() {
    super.initState();
    
    try {
      // Initialize date formatting for Spanish locale
      initializeDateFormatting('es_ES', null);
      
      // Initialize animations
      _fadeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      
      // Initialize fade controller with a tween
      _fadeController.animateTo(1.0, duration: const Duration(milliseconds: 800));
      
      _slideController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ));
      
      // Start animations with a slight delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _fadeController.forward();
          _slideController.forward();
        }
      });
    } catch (e) {
      debugPrint('Error initializing stats screen: $e');
    }
  }
  
  @override
  void dispose() {
    try {
      _fadeController.dispose();
      _slideController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }
    super.dispose();
  }
  
  // Get mood emoji based on mood index
  String _getMoodEmoji(int moodIndex) {
    const emojis = ['😊', '🙂', '😐', '😔', '😢'];
    return emojis[moodIndex];
  }
  
  // Get mood description in Spanish
  String _getMoodDescription(int moodIndex) {
    const descriptions = ['Feliz', 'Contento', 'Neutral', 'Triste', 'Muy triste'];
    return descriptions[moodIndex];
  }
  
  // Get mood color with bounds checking
  Color _getMoodColor(int moodIndex) {
    final colors = [
      const Color(0xFF4CAF50), // Green - Happy
      const Color(0xFF8BC34A), // Light Green - Content
      const Color(0xFFFFC107), // Amber - Neutral
      const Color(0xFFFF9800), // Orange - Sad
      const Color(0xFFF44336), // Red - Very Sad
    ];
    
    // Ensure moodIndex is within bounds
    final index = moodIndex.clamp(0, colors.length - 1);
    return colors[index];
  }
  
  // Build a stat card with animation
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    int delay = 0,
  }) {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Build weekly chart
  Widget _buildWeeklyChart() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta semana',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _weeklyData.entries.map((entry) {
                    final height = entry.value * 30.0;
                    final color = _getMoodColor(entry.value - 1);
                    
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      tween: Tween<double>(begin: 0, end: height),
                      builder: (context, value, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${entry.value}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: value,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    color.withOpacity(0.8),
                                    color,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Mock data - in a real app, this would come from your data store
      final now = DateTime.now();
      final happiestDay = now.subtract(const Duration(days: 2));
      final saddestDay = now.subtract(const Duration(days: 5));
      
      // Format dates with error handling
      String formatDate(DateTime date) {
        try {
          final formatted = DateFormat('EEEE, d MMMM', 'es_ES').format(date);
          // Capitalize first letter of each word
          return formatted.split(' ').map((word) {
            if (word.isEmpty) return word;
            return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
          }).join(' ');
        } catch (e) {
          debugPrint('Error formatting date: $e');
          return DateFormat('EEEE, d MMMM').format(date);
        }
      }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Día más feliz
            _buildStatCard(
              title: 'Día más feliz',
              value: '${formatDate(happiestDay)} ${_getMoodEmoji(0)}',
              icon: Icons.emoji_emotions_outlined,
              color: Colors.green,
              delay: 100,
            ),
            
            // Día más triste
            _buildStatCard(
              title: 'Día más triste',
              value: '${formatDate(saddestDay)} ${_getMoodEmoji(3)}',
              icon: Icons.sentiment_dissatisfied_outlined,
              color: Colors.orange,
              delay: 200,
            ),
            
            // Resumen semanal
            _buildWeeklyChart(),
            
            // Resumen mensual
            _buildStatCard(
              title: 'Resumen mensual',
              value: '15 días positivos / 10 días negativos',
              icon: Icons.calendar_today_outlined,
              color: Colors.blue,
              delay: 300,
            ),
            
            // Estado de ánimo promedio
            _buildStatCard(
              title: 'Estado de ánimo promedio',
              value: '${_getMoodDescription(1)} ${_getMoodEmoji(1)}',
              icon: Icons.analytics_outlined,
              color: Colors.purple,
              delay: 400,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    } catch (e) {
      debugPrint('Error building stats screen: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Estadísticas'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No se pudieron cargar las estadísticas. Por favor, inténtalo de nuevo más tarde.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
  }
}
