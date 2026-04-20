import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, bgColor, iconColor) = _getStyle(type, isDark);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
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
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static (IconData, Color, Color) _getStyle(SnackBarType type, bool isDark) {
    switch (type) {
      case SnackBarType.success:
        return (
          Icons.check_circle_outline,
          isDark ? const Color(0xFF065F46) : AppColors.emerald600,
          const Color(0xFF6EE7B7),
        );
      case SnackBarType.error:
        return (
          Icons.error_outline,
          isDark ? const Color(0xFF7F1D1D) : const Color(0xFFDC2626),
          const Color(0xFFFCA5A5),
        );
      case SnackBarType.warning:
        return (
          Icons.warning_amber_outlined,
          isDark ? const Color(0xFF78350F) : const Color(0xFFD97706),
          const Color(0xFFFDE68A),
        );
      case SnackBarType.info:
        return (
          Icons.info_outline,
          isDark ? const Color(0xFF1E3A5F) : const Color(0xFF2563EB),
          const Color(0xFF93C5FD),
        );
    }
  }

  /// Convert raw backend/firebase errors into user-friendly messages
  static String friendlyError(String? rawError) {
    if (rawError == null || rawError.isEmpty) return 'Something went wrong. Please try again.';

    final lower = rawError.toLowerCase();

    // Network errors
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('failed host lookup')) {
      return 'Unable to connect to server. Please check your internet connection and try again.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'The request timed out. Please check your connection and try again.';
    }

    // Auth errors (fallback for unhandled cases)
    if (lower.contains('no user found') || lower.contains('user-not-found')) {
      return 'No account found with this email. Please register first.';
    }
    if (lower.contains('wrong-password') || lower.contains('incorrect password')) {
      return 'Incorrect password. Please try again or reset your password.';
    }
    if (lower.contains('email-already-in-use') || lower.contains('already registered')) {
      return 'This email is already registered. Please login instead.';
    }
    if (lower.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters with a mix of letters and numbers.';
    }
    if (lower.contains('invalid-email') || lower.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (lower.contains('user-disabled') || lower.contains('account has been disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (lower.contains('token expired') || lower.contains('id-token-expired')) {
      return 'Your session has expired. Please login again.';
    }
    if (lower.contains('invalid token') || lower.contains('invalid-credential')) {
      return 'Invalid credentials. Please check your email and password.';
    }
    if (lower.contains('please register first') || lower.contains('please complete your registration')) {
      return 'Please complete your registration to continue.';
    }

    // Backend-specific
    if (lower.contains('user not found')) {
      return 'Account not found. Please register first.';
    }
    if (lower.contains('insufficient balance')) {
      return 'Insufficient balance. Please top up at least NPR 50 to ride.';
    }
    if (lower.contains('no ongoing ride')) {
      return 'No active ride found. Please tap in first.';
    }
    if (lower.contains('already has an ongoing ride')) {
      return 'You already have an active ride. Please tap out first.';
    }

    // If it still looks like a raw error, return a generic message
    if (lower.startsWith('exception') ||
        lower.startsWith('error') ||
        lower.contains('exception:') ||
        lower.contains('error:') ||
        rawError.length > 150) {
      return 'Something went wrong. Please try again later.';
    }

    // Otherwise return as-is (it's likely already human-readable)
    return rawError;
  }
}
