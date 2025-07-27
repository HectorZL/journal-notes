import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'data/database_helper.dart';
import 'services/navigation_service.dart';
import 'providers/accessibility_provider.dart';
import 'models/accessibility_settings.dart';
import 'theme/theme.dart';

// Global error widget builder
Widget errorWidgetBuilder(FlutterErrorDetails errorDetails) {
  debugPrint('Error widget triggered: ${errorDetails.exception}');
  debugPrint('Stack trace: ${errorDetails.stack}');
  
  return Material(
    child: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                '¡Ups! Algo salió mal',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${errorDetails.exception}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Try to recover by restarting the app
                  runApp(const MyApp());
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> main() async {
  // Set up error handling
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(details.toString());  
  };
  
  // Set up error widget builder
  ErrorWidget.builder = errorWidgetBuilder;
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize database
  try {
    debugPrint('Initializing database...');
    final db = await DatabaseHelper.instance.database;
    debugPrint('Database initialized successfully');
    
    // Verify we can query the database
    try {
      final result = await db.rawQuery('SELECT sqlite_version()');
      debugPrint('SQLite version: $result');
    } catch (e) {
      debugPrint('Error querying database: $e');
      rethrow;
    }
  } catch (e, stackTrace) {
    debugPrint('Error initializing database: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error UI but don't crash
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al inicializar la base de datos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        // Try to delete and recreate the database
                        try {
                          await DatabaseHelper.instance.close();
                          await DatabaseHelper.instance.deleteDatabase();
                          runApp(const MyApp());
                        } catch (e) {
                          debugPrint('Error resetting database: $e');
                          // If we can't reset, just restart the app
                          runApp(const MyApp());
                        }
                      },
                      child: const Text('Reiniciar base de datos'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        runApp(const MyApp());
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  
  // Run the app with ProviderScope
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for changes in accessibility settings
    final accessibilitySettings = ref.watch(accessibilityProvider);
    final navService = ref.read(navigationServiceProvider);
    
    // Apply text scaling based on user preference
    final mediaQuery = MediaQuery.of(context);
    final modifiedMediaQuery = mediaQuery.copyWith(
      textScaler: TextScaler.linear(accessibilitySettings.fontSizeScale),
    );
    
    return MaterialApp(
      title: 'Mood Notes',
      debugShowCheckedModeBanner: false,
      themeMode: _getThemeMode(accessibilitySettings.themeMode, mediaQuery.platformBrightness),
      initialRoute: navService.getInitialRoute(),
      onGenerateRoute: (settings) => navService.generateRoute(settings),
      builder: (context, child) {
        return MediaQuery(
          data: modifiedMediaQuery,
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accessibilitySettings.selectedColor,
          brightness: Brightness.light,
          secondary: _adjustColorForAccessibility(
            accessibilitySettings.selectedColor.withOpacity(0.7),
            accessibilitySettings.colorBlindnessType,
          ),
          tertiary: _adjustColorForAccessibility(
            accessibilitySettings.selectedColor.withOpacity(0.5),
            accessibilitySettings.colorBlindnessType,
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _lighten(accessibilitySettings.selectedColor, 0.2),
          brightness: Brightness.dark,
          secondary: _adjustColorForAccessibility(
            _lighten(accessibilitySettings.selectedColor, 0.4),
            accessibilitySettings.colorBlindnessType,
          ),
          tertiary: _adjustColorForAccessibility(
            _lighten(accessibilitySettings.selectedColor, 0.6),
            accessibilitySettings.colorBlindnessType,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  static ThemeMode _getThemeMode(ThemeModeOption option, Brightness platformBrightness) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
      default:
        return ThemeMode.system;
    }
  }
  
  static Color _lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
  
  static Color _adjustColorForAccessibility(Color color, ColorBlindnessType type) {
    switch (type) {
      case ColorBlindnessType.protanopia:
        // Adjust for red-blindness
        return Color.fromARGB(
          color.alpha,
          (color.red * 0.8).round(),
          (color.green * 1.2).clamp(0, 255).round(),
          (color.blue * 1.2).clamp(0, 255).round(),
        );
      case ColorBlindnessType.deuteranopia:
        // Adjust for green-blindness
        return Color.fromARGB(
          color.alpha,
          (color.red * 1.2).clamp(0, 255).round(),
          (color.green * 0.8).round(),
          (color.blue * 1.2).clamp(0, 255).round(),
        );
      case ColorBlindnessType.tritanopia:
        // Adjust for blue-blindness
        return Color.fromARGB(
          color.alpha,
          (color.red * 1.2).clamp(0, 255).round(),
          (color.green * 1.2).clamp(0, 255).round(),
          (color.blue * 0.8).round(),
        );
      case ColorBlindnessType.achromatopsia:
        // Convert to grayscale
        final grayValue = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue).round();
        return Color.fromARGB(color.alpha, grayValue, grayValue, grayValue);
      case ColorBlindnessType.none:
      default:
        return color;
    }
  }
}
