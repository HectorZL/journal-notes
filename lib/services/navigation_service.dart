import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the auth service provider
import 'auth_service.dart';

// Import screens
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';
import '../ui/screens/auth/forgot_password_screen.dart';
import '../ui/screens/auth/reset_password_screen.dart';
import '../ui/screens/main_navigation_screen.dart';

// Define navigation service provider
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService(ref);
});

// Define navigation service class
class NavigationService {
  final Ref _ref;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  NavigationService(this._ref);
  
  // Define route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
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
    // Special case for register flow - don't redirect to login if we're in the middle of registration
    final isInRegistrationFlow = settings.name == register || 
        (navigatorKey.currentContext != null && 
         ModalRoute.of(navigatorKey.currentContext!)?.settings.name == register);
    
    // If not authenticated and not on login/register/forgot-password, redirect to login
    if (!isAuthenticated && 
        settings.name != login && 
        settings.name != register &&
        settings.name != forgotPassword &&
        !(settings.name?.startsWith('$resetPassword/') ?? false) &&
        !isInRegistrationFlow) {
      return _buildRoute(settings, const LoginScreen(), isLoginScreen: true);
    }
    
    switch (settings.name) {
      case splash:
        // If user is authenticated, go to home, otherwise to login
        return isAuthenticated 
            ? _buildRoute(settings, const MainNavigationScreen())
            : _buildRoute(settings, const LoginScreen(), isLoginScreen: true);
      case login:
        // If already authenticated, go to home
        if (isAuthenticated) {
          return _buildRoute(settings, const MainNavigationScreen());
        }
        return _buildRoute(settings, const LoginScreen(), isLoginScreen: true);
      case register:
        // Allow access to register screen even if authenticated
        return _buildRoute(settings, const RegisterScreen());
      case forgotPassword:
        return _buildRoute(settings, const ForgotPasswordScreen());
      case resetPassword when settings.name!.startsWith('$resetPassword/'):
        final email = settings.name!.split('/').last;
        return _buildRoute(
          settings, 
          ResetPasswordScreen(email: email),
        );
      case home:
        return _buildRoute(settings, const MainNavigationScreen());
      default:
        // Check if the route is a reset password route
        if (settings.name?.startsWith('$resetPassword/') ?? false) {
          final email = settings.name!.split('/').last;
          return _buildRoute(
            settings, 
            ResetPasswordScreen(email: email),
          );
        }
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
        // For login screen, use a fade transition
        if (isLoginScreen) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        }
        
        // For other screens, use a slide transition
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
  
  void pop(BuildContext context) {
    try {
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Navigation error: $e');
      _showErrorSnackBar(context, 'Error navigating back');
    }
  }
  
  // Navigation helper methods
  void navigateToHome(BuildContext context) {
    pushReplacementNamed(context, home);
  }
  
  void navigateToLogin(BuildContext context) {
    pushReplacementNamed(context, login);
  }
  
  void navigateToRegister(BuildContext context) {
    pushNamed(context, register);
  }
  
  void navigateToForgotPassword(BuildContext context) {
    pushNamed(context, forgotPassword);
  }
  
  void navigateToResetPassword(BuildContext context, String email) {
    pushNamed(context, '$resetPassword/$email');
  }
  
  // Helper method to show error messages
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Navigation method that handles both named and unnamed routes
  void navigateTo(BuildContext context, String route, {Object? arguments}) {
    if (route.startsWith('/')) {
      // Handle named routes
      Navigator.of(context).pushNamed(route, arguments: arguments);
    } else {
      // Handle direct navigation to widgets
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _getPageFromRoute(route, arguments),
          settings: RouteSettings(arguments: arguments),
        ),
      );
    }
  }

  // Helper method to get the appropriate page based on route name
  Widget _getPageFromRoute(String route, Object? arguments) {
    switch (route) {
      case 'reset-password':
        return ResetPasswordScreen(email: arguments as String);
      default:
        return const SizedBox.shrink();
    }
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
