import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'data/database_helper.dart';
import 'services/navigation_service.dart';

Future<void> main() async {
  // Enable better error handling
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error widget builder
  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                '¡Ups! Algo salió mal.\nPor favor, reinicia la aplicación.',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Try to recover by restarting the app
                  runApp(ProviderScope(child: MyApp()));
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  };
  
  // Initialize database
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    debugPrint('Database initialized successfully');
  } catch (e) {
    debugPrint('Error initializing database: $e');
    // Show error UI but don't crash
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error al inicializar la base de datos: $e'),
          ),
        ),
      ),
    );
    return;
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Run the app
  runApp(
    ProviderScope(
      child: const MyApp(),
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
