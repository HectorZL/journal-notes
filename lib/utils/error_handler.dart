import 'package:flutter/material.dart';

class ErrorHandler {
  static void handleError(
    BuildContext context, {
    required dynamic error,
    required VoidCallback onRetry,
    String? customMessage,
    bool popOnError = true,
  }) {
    debugPrint('Error: $error');
    
    if (!context.mounted) return;
    
    final snackBar = SnackBar(
      content: Text(customMessage ?? 'Ha ocurrido un error. Intente nuevamente.'),
      action: SnackBarAction(
        label: 'Reintentar',
        onPressed: onRetry,
      ),
      duration: const Duration(seconds: 5),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    if (popOnError) {
      Navigator.of(context).pop();
    }
  }
  
  static Future<T?> runWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() action,
    String? errorMessage,
    bool popOnError = false,
  }) async {
    try {
      return await action();
    } catch (e) {
      if (context.mounted) {
        handleError(
          context,
          error: e,
          onRetry: () => runWithErrorHandling(
            context: context,
            action: action,
            errorMessage: errorMessage,
            popOnError: popOnError,
          ),
          customMessage: errorMessage,
          popOnError: popOnError,
        );
      }
      return null;
    }
  }
}
