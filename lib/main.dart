import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'data/database_helper.dart';
import 'services/navigation_service.dart';
import 'providers/auth_provider.dart';

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
    debugPrint(details.toString());  };
  
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
    // Get navigation service from provider
    final navService = ref.read(navigationServiceProvider);
    
    return MaterialApp(
      title: 'Mood Notes',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      initialRoute: navService.getInitialRoute(),
      onGenerateRoute: (settings) => navService.generateRoute(settings),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Primary color
          brightness: Brightness.light,
          secondary: const Color(0xFF625B71), // Secondary color
          tertiary: const Color(0xFF7D5260), // Tertiary color
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
        // Add more theme configurations as needed
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF), // Primary color for dark theme
          brightness: Brightness.dark,
          secondary: const Color(0xFFCCC2DC), // Secondary color for dark theme
          tertiary: const Color(0xFFEFB8C8), // Tertiary color for dark theme
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Add more dark theme configurations as needed
      ),
    );
  }
}
