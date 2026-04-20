import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> pendingRegistration;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.pendingRegistration,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to check if email is verified
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerification(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final result = await appState.completeRegistration(
      fullName: widget.pendingRegistration['fullName'],
      phone: widget.pendingRegistration['phone'],
      citizenshipNumber: widget.pendingRegistration['citizenshipNumber'],
      address: widget.pendingRegistration['address'],
      role: widget.pendingRegistration['role'] ?? 'Passenger',
      companyName: widget.pendingRegistration['companyName'],
      panNumber: widget.pendingRegistration['panNumber'],
      businessDocPath: widget.pendingRegistration['businessDocPath'],
    );

    setState(() => _isChecking = false);

    if (result.success) {
      _pollTimer?.cancel();
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Email verified! Welcome to Sawari.',
          type: SnackBarType.success,
        );
        // Clear navigation stack to allow root rebuild
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else if (!silent && mounted) {
      AppSnackBar.show(
        context,
        message: result.error ?? 'Email not verified yet. Please check your inbox.',
        type: SnackBarType.warning,
      );
    }

    // If Firebase user was deleted due to backend rejection, stop polling and go back
    if (!result.success &&
        result.error != null &&
        result.error != 'Email not verified yet' &&
        !result.error!.contains('SocketException') &&
        !result.error!.contains('TimeoutException') &&
        !result.error!.contains('Connection refused')) {
      _pollTimer?.cancel();
      if (mounted) {
        AppSnackBar.show(
          context,
          message: result.error!,
          type: SnackBarType.error,
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final result = await appState.resendVerificationEmail();

    setState(() => _isResending = false);

    if (mounted) {
      AppSnackBar.show(
        context,
        message: result.success
            ? 'Verification email sent again!'
            : result.error ?? 'Failed to resend email',
        type: result.success ? SnackBarType.success : SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the link in your email, then tap the button below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),

              // I've verified button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChecking
                      ? null
                      : () => _checkVerification(silent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.emerald600
                        : AppColors.emerald500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "I've verified my email",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend email
              TextButton(
                onPressed: _isResending ? null : _resendEmail,
                child: _isResending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark
                              ? AppColors.emerald400
                              : AppColors.emerald600,
                        ),
                      )
                    : Text(
                        'Resend verification email',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.emerald400
                              : AppColors.emerald600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
