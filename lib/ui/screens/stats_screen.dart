import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/stats_service.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // State variables
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;
  String? _errorMessage;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _initializeData();
    
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
  
  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('userId');

      if (_userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      // Get stats service
      final statsService = ref.read(statsServiceProvider);
      
      // Fetch weekly stats
      _statsData = await statsService.getWeeklyStats(_userId!);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar las estadísticas: $e';
        });
      }
      debugPrint('Error initializing stats: $e');
    }
  }

  Future<void> _refreshData() async {
    await _initializeData();
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
  
  // Build loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Build error message
  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Ocurrió un error inesperado',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // Build a stat card with animation
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
    if (_isLoading) return _buildLoadingIndicator();
    if (_errorMessage != null) return _buildErrorMessage();
    if (_statsData == null || _statsData!['notesPerDay'].isEmpty) {
      return _buildEmptyState();
    }

    final notesPerDay = _statsData!['notesPerDay'] as List<dynamic>;
    final moodDistribution = _statsData!['moodDistribution'] as List<dynamic>;
    
    // Create a map of day of week to mood data
    final Map<String, dynamic> weeklyData = {};
    final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    // Initialize with default values
    for (final day in weekdays) {
      weeklyData[day] = {
        'count': 0,
        'moodIndex': 2, // Default to neutral
      };
    }
    
    // Update with actual data
    for (final dayData in notesPerDay) {
      final date = DateTime.parse(dayData['date']);
      final dayName = weekdays[date.weekday - 1];
      
      // Find the most common mood for this day
      final moodForDay = moodDistribution.firstWhere(
        (mood) => mood['moodIndex'] == dayData['moodIndex'],
        orElse: () => {'moodIndex': 2},
      );
      
      weeklyData[dayName] = {
        'count': dayData['count'],
        'moodIndex': moodForDay['moodIndex'],
      };
    }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Esta semana',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshData,
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: weeklyData.entries.map((entry) {
                    final moodIndex = entry.value['moodIndex'] as int? ?? 2;
                    final count = entry.value['count'] as int? ?? 0;
                    final height = (count * 20.0).clamp(0.0, 150.0);
                    final color = _getMoodColor(moodIndex);
                    
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      tween: Tween<double>(begin: 0, end: height),
                      builder: (context, value, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              count > 0 ? count.toString() : '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: value,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
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
  
  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos para mostrar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade notas para ver tus estadísticas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get most common mood info
    String getMostCommonMoodInfo() {
      if (_isLoading) return 'Cargando...';
      if (_errorMessage != null) return 'Error';
      if (_statsData == null || _statsData!['mostCommonMood'] == null) {
        return 'No hay datos';
      }
      
      final mood = _statsData!['mostCommonMood'] as Map<String, dynamic>;
      final moodIndex = mood['moodIndex'] as int;
      final count = mood['count'] as int;
      
      return '${_getMoodEmoji(moodIndex)} ${_getMoodDescription(moodIndex)} ($count veces)';
    }
    
    // Get average mood info
    String getAverageMoodInfo() {
      if (_isLoading) return 'Cargando...';
      if (_errorMessage != null) return 'Error';
      if (_statsData == null || _statsData!['averageMood'] == null) {
        return 'No hay datos';
      }
      
      final average = _statsData!['averageMood'] as double;
      final moodIndex = average.round().clamp(0, 4);
      
      return '${_getMoodEmoji(moodIndex)} ${_getMoodDescription(moodIndex)}';
    }
    
    // Get total notes count
    int getTotalNotes() {
      if (_isLoading || _statsData == null) return 0;
      return _statsData!['totalNotes'] as int? ?? 0;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 32),
              ] else if (_errorMessage != null) ...[
                _buildErrorMessage(),
              ] else ...[
                // Estado de ánimo más común
                _buildStatCard(
                  title: 'Estado de ánimo más común',
                  value: getMostCommonMoodInfo(),
                  icon: Icons.emoji_emotions_outlined,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                // Promedio de ánimo
                _buildStatCard(
                  title: 'Promedio de ánimo',
                  value: getAverageMoodInfo(),
                  icon: Icons.trending_up_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                // Total de notas
                _buildStatCard(
                  title: 'Total de notas',
                  value: getTotalNotes().toString(),
                  icon: Icons.note_alt_outlined,
                  color: Colors.purple,
                ),
                // Gráfico semanal
                _buildWeeklyChart(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}