import 'dart:math';

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
    
    // Create a color filter for the entire app based on accessibility settings
    final colorFilter = _createColorFilter(accessibilitySettings.colorBlindnessType);
    
    return MaterialApp(
      title: 'Mood Notes',
      debugShowCheckedModeBanner: false,
      themeMode: _getThemeMode(accessibilitySettings.themeMode, mediaQuery.platformBrightness),
      initialRoute: NavigationService.splash,
      onGenerateRoute: (settings) => navService.generateRoute(settings),
      builder: (context, child) {
        return MediaQuery(
          data: modifiedMediaQuery,
          child: ColorFiltered(
            colorFilter: colorFilter,
            child: child!,
          ),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accessibilitySettings.selectedColor,
          brightness: Brightness.light,
          secondary: _adjustColorForAccessibility(
            accessibilitySettings.selectedColor.withValues(alpha: 170),
            accessibilitySettings.colorBlindnessType,
          ),
          tertiary: _adjustColorForAccessibility(
            accessibilitySettings.selectedColor.withValues(alpha: 130),
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
    // Convert color to linear RGB (approximate sRGB to linear RGB)
    double toLinear(double channel) {
      channel = channel / 255.0;
      return channel <= 0.04045 
          ? channel / 12.92 
          : pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    // Convert linear RGB to sRGB
    double toSRGB(double channel) {
      return channel <= 0.0031308
          ? 12.92 * channel
          : 1.055 * pow(channel, 1 / 2.4) - 0.055;
    }

    // Apply color transformation matrix
    List<double> applyColorMatrix(List<double> rgb, List<List<double>> matrix) {
      return [
        rgb[0] * matrix[0][0] + rgb[1] * matrix[0][1] + rgb[2] * matrix[0][2],
        rgb[0] * matrix[1][0] + rgb[1] * matrix[1][1] + rgb[2] * matrix[1][2],
        rgb[0] * matrix[2][0] + rgb[1] * matrix[2][1] + rgb[2] * matrix[2][2],
      ];
    }

    // Convert color to linear RGB
    final r = toLinear(color.r.toDouble());
    final g = toLinear(color.g.toDouble());
    final b = toLinear(color.b.toDouble());

    List<double> result = [r, g, b];

    switch (type) {
      case ColorBlindnessType.protanopia:
        // Simulate red-blindness (protanopia)
        result = applyColorMatrix([r, g, b], [
          [0.567, 0.433, 0.0],
          [0.558, 0.442, 0.0],
          [0.0, 0.242, 0.758]
        ]);
        break;
        
      case ColorBlindnessType.deuteranopia:
        // Simulate green-blindness (deuteranopia)
        result = applyColorMatrix([r, g, b], [
          [0.625, 0.375, 0.0],
          [0.7, 0.3, 0.0],
          [0.0, 0.3, 0.7]
        ]);
        break;
        
      case ColorBlindnessType.tritanopia:
        // Simulate blue-blindness (tritanopia)
        result = applyColorMatrix([r, g, b], [
          [0.95, 0.05, 0.0],
          [0.0, 0.433, 0.567],
          [0.0, 0.475, 0.525]
        ]);
        break;
        
      case ColorBlindnessType.achromatopsia:
        // Convert to grayscale using perceptual luminance
        final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        result = [luminance, luminance, luminance];
        break;
        
      case ColorBlindnessType.none:
      default:
        return color;
    }

    // Apply the color matrix and convert back to color
    return Color.fromARGB(
      color.alpha,
      (toSRGB(result[0]) * 255).round().clamp(0, 255),
      (toSRGB(result[1]) * 255).round().clamp(0, 255),
      (toSRGB(result[2]) * 255).round().clamp(0, 255),
    );
  }
  
  static ColorFilter _createColorFilter(ColorBlindnessType type) {
    switch (type) {
      case ColorBlindnessType.protanopia:
        return const ColorFilter.matrix([
          0.567, 0.433, 0, 0, 0,
          0.558, 0.442, 0, 0, 0,
          0, 0.242, 0.758, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.deuteranopia:
        return const ColorFilter.matrix([
          0.625, 0.375, 0, 0, 0,
          0.7, 0.3, 0, 0, 0,
          0, 0.3, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.tritanopia:
        return const ColorFilter.matrix([
          0.95, 0.05, 0, 0, 0,
          0, 0.433, 0.567, 0, 0,
          0, 0.475, 0.525, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.achromatopsia:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.daltonism:
        // Daltonism filter - a moderate red-green color deficiency simulation
        return const ColorFilter.matrix([
          0.8, 0.2, 0, 0, 0,
          0.258, 0.742, 0, 0, 0,
          0, 0.142, 0.858, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.none:
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}
