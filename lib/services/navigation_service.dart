import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the auth service provider
import 'auth_service.dart';

// Import screens
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';
import '../ui/screens/main_navigation_screen.dart';

// Define navigation service provider
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService(ref);
});

// Define navigation service class
class NavigationService {
  final Ref _ref;
  
  NavigationService(this._ref);
  
  // Define route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  
  // Check if user is authenticated
  bool get isAuthenticated {
    try {
      return _ref.read(authServiceProvider).isLoggedIn();
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
      return false;
    }
  }
  
  // Generate routes
  Route<dynamic> generateRoute(RouteSettings settings) {
    // If not authenticated and not on login/register, redirect to login
    if (!isAuthenticated && settings.name != login && settings.name != register) {
      return _buildRoute(settings, const LoginScreen(), isLoginScreen: true);
    }
    
    switch (settings.name) {
      case splash:
        // If user is authenticated, go to home, otherwise to login
        return isAuthenticated 
            ? _buildRoute(settings, const MainNavigationScreen())
            : _buildRoute(settings, const LoginScreen(), isLoginScreen: true);
      case login:
        return _buildRoute(settings, const LoginScreen(), isLoginScreen: true);
      case register:
        return _buildRoute(settings, const RegisterScreen());
      case home:
        return _buildRoute(settings, const MainNavigationScreen());
      default:
        // Default to login if route not found and not authenticated
        return isAuthenticated 
            ? _buildRoute(settings, const MainNavigationScreen())
            : _buildRoute(settings, const LoginScreen(), isLoginScreen: true);
    }
  }
  
  // Helper method to build routes with transitions
  PageRouteBuilder _buildRoute(RouteSettings settings, Widget page, {bool isLoginScreen = false}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
  
  // Navigation methods with error handling
  void pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) {
    try {
      Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
    } catch (e) {
      debugPrint('Navigation error: $e');
      _showErrorSnackBar(context, 'Error navigating to $routeName');
    }
  }
  
  void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    try {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    } catch (e) {
      debugPrint('Navigation error: $e');
      _showErrorSnackBar(context, 'Error navigating to $routeName');
    }
  }
  
  void pop<T extends Object?>(BuildContext context, [T? result]) {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      debugPrint('Error popping route: $e');
    }
  }
  
  // Show error message as a snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  // Navigate to home with a clean stack
  void navigateToHome(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        home, 
        (route) => false, // This removes all previous routes
      );
    }
  }
  
  // Navigate to login with a clean stack
  void navigateToLogin(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        login, 
        (route) => false, // This removes all previous routes
      );
    }
  }
  
  // Handle initial route based on auth state
  String getInitialRoute() {
    return isAuthenticated ? home : login;
  }
}

// Splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
