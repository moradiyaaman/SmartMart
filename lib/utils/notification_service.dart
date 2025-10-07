import 'package:flutter/material.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class NotificationService {
  static void showSnackBar(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars
    scaffoldMessenger.clearSnackBars();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIconForType(type),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _getColorForType(type),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      action: action,
    );
    
    scaffoldMessenger.showSnackBar(snackBar);
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      type: NotificationType.success,
      duration: duration,
      action: action,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      type: NotificationType.error,
      duration: duration,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      type: NotificationType.warning,
      duration: duration,
      action: action,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      type: NotificationType.info,
      duration: duration,
      action: action,
    );
  }

  static IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  static Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50); // Green
      case NotificationType.error:
        return const Color(0xFFE53E3E); // Red
      case NotificationType.warning:
        return const Color(0xFFFF9800); // Orange
      case NotificationType.info:
        return const Color(0xFF2196F3); // Blue
    }
  }
}

// Authentication specific messages
class AuthMessages {
  static const String loginSuccess = 'Login successful! Welcome back.';
  static const String signupSuccess = 'Account created successfully! Please complete your profile.';
  static const String logoutSuccess = 'Logged out successfully.';
  
  // Error messages
  static const String invalidCredentials = 'Invalid email or password. Please try again.';
  static const String userNotFound = 'No account found with this email address.';
  static const String wrongPassword = 'Incorrect password. Please try again.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String userDisabled = 'This account has been disabled. Please contact support.';
  static const String emailAlreadyInUse = 'An account already exists with this email address.';
  static const String weakPassword = 'Password is too weak. Please use at least 6 characters.';
  static const String networkError = 'Network error. Please check your connection and try again.';
  static const String unknownError = 'Something went wrong. Please try again.';
  
  // Form validation
  static const String emailRequired = 'Email address is required.';
  static const String passwordRequired = 'Password is required.';
  static const String nameRequired = 'Full name is required.';
  static const String phoneRequired = 'Phone number is required.';
  static const String passwordMismatch = 'Passwords do not match.';
  static const String invalidPhoneNumber = 'Please enter a valid phone number.';
  static const String nameMinLength = 'Name must be at least 2 characters long.';
  static const String passwordMinLength = 'Password must be at least 6 characters long.';
}

// General app messages
class AppMessages {
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'Something went wrong. Please try again.';
  static const String noDataFound = 'No data found.';
  static const String loadingError = 'Failed to load data. Please try again.';
  
  // Success messages
  static const String dataUpdated = 'Data updated successfully.';
  static const String dataSaved = 'Data saved successfully.';
  static const String dataDeleted = 'Data deleted successfully.';
  
  // Product messages
  static const String productAdded = 'Product added to cart successfully.';
  static const String productRemoved = 'Product removed from cart.';
  static const String productUpdated = 'Product updated successfully.';
  static const String productDeleted = 'Product deleted successfully.';
  
  // Order messages
  static const String orderPlaced = 'Order placed successfully!';
  static const String orderCancelled = 'Order cancelled successfully.';
  static const String orderUpdated = 'Order status updated.';
}