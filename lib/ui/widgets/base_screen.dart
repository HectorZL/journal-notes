import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/navigation_service.dart';

/// A base screen widget that provides common functionality to all screens
class BaseScreen extends ConsumerStatefulWidget {
  final Widget child;
  final bool showAppBar;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const BaseScreen({
    Key? key,
    required this.child,
    this.showAppBar = true,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  }) : super(key: key);

  @override
  ConsumerState<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends ConsumerState<BaseScreen> {
  @override
  Widget build(BuildContext context) {
    final navService = ref.read(navigationServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        if (widget.showBackButton) {
          navService.pop(context);
        }
        return false;
      },
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: widget.title != null ? Text(widget.title!) : null,
                centerTitle: true,
                automaticallyImplyLeading: widget.showBackButton,
                actions: widget.actions,
                elevation: 0,
                scrolledUnderElevation: 1,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                titleTextStyle: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        body: _buildBody(),
        floatingActionButton: widget.floatingActionButton,
        backgroundColor: colorScheme.surface,
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: widget.onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  // Show a snackbar with the given message
  void showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error 
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
