import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'mood_prompt_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'calendar_screen.dart';

// Constants for animation durations and curves
const _kAnimationDuration = Duration(milliseconds: 300);
const _kAnimationCurve = Curves.easeInOut;
const _kNavigationBarHeight = 80.0;



class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  
  // Keep track of controllers and animations
  late final List<AnimationController> _fadeControllers;
  late final List<Animation<double>> _fadeAnimations;
  
  // Screens with PageStorageKey to maintain scroll position
  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];
  
  // PageStorageKeys for maintaining scroll position
  final List<PageStorageKey> _pageStorageKeys = [
    const PageStorageKey('home_page'),
    const PageStorageKey('calendar_page'),
    const PageStorageKey('stats_page'),
    const PageStorageKey('profile_page'),
  ];
  
  // Track if screens should be kept alive
  final _shouldKeepAlives = List<bool>.filled(4, false);

  // Add controller for FAB animation
  late final AnimationController _fabController;
  late final Animation<double> _fabAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize FAB animation
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _fabAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize animation controllers
    _fadeControllers = List.generate(
      _screens.length,
      (index) => AnimationController(
        vsync: this,
        duration: _kAnimationDuration,
      ),
    );

    // Initialize animations
    _fadeAnimations = List.generate(
      _screens.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeControllers[index],
          curve: _kAnimationCurve,
        ),
      ),
    );

    // Start with first screen visible and keep it alive
    _fadeControllers[0].forward();
    _shouldKeepAlives[0] = true;
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    _fabController.dispose();
    for (final controller in _fadeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Already on this tab
    
    setState(() {
      // Mark the new screen to be kept alive
      _shouldKeepAlives[index] = true;
      
      // Fade out current screen
      _fadeControllers[_selectedIndex].reverse();
      
      // Update selected index
      final previousIndex = _selectedIndex;
      _selectedIndex = index;
      
      // Fade in new screen
      _fadeControllers[_selectedIndex].forward().then((_) {
        // After animation completes, mark previous screen as not needing to be kept alive
        if (mounted) {
          setState(() {
            _shouldKeepAlives[previousIndex] = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      // Floating action button with pulsing animation
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            // Add a little bounce effect when pressed
            _fabController.stop();
            _fabController.forward();
            
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _fabController.repeat(reverse: true);
              }
            });
            
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, _, __) => const MoodPromptScreen(),
                transitionsBuilder: (context, animation, _, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutQuart;
                  
                  final tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          highlightElevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Use IndexedStack to maintain state of all screens
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_screens.length, (index) {
          return _shouldKeepAlives[index]
              ? FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: KeyedSubtree(
                    key: _pageStorageKeys[index],
                    child: _screens[index],
                  ),
                )
              : const SizedBox.shrink(); // Use SizedBox.shrink for non-visible screens
        }),
      ),
      // Bottom navigation bar with optimized performance
      bottomNavigationBar: Container(
        height: _kNavigationBarHeight,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 26), // 0.1 * 255 ≈ 26
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: _kAnimationDuration * 2,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, size: 24),
              selectedIcon: const Icon(Icons.home_filled, size: 24),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_today_outlined, size: 24),
              selectedIcon: const Icon(Icons.calendar_today, size: 24),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined, size: 24),
              selectedIcon: const Icon(Icons.insights, size: 24),
              label: 'Estadísticas',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline, size: 24),
              selectedIcon: const Icon(Icons.person, size: 24),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
