import 'dart:async';
import 'package:flutter/material.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'api_service.dart';

class KhaltiPaymentService {
  static final KhaltiPaymentService _instance = KhaltiPaymentService._internal();
  factory KhaltiPaymentService() => _instance;
  KhaltiPaymentService._internal();

  final ApiService _apiService = ApiService();

  /// Verify payment with backend, retrying up to [maxRetries] times
  Future<double?> _verifyWithRetry(String pidx, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      if (i > 0) await Future.delayed(const Duration(seconds: 2));
      debugPrint('Verify attempt ${i + 1}/$maxRetries for pidx: $pidx');
      final response = await _apiService.verifyKhaltiPayment(pidx);
      if (response.success && response.data != null) {
        final balance = (response.data!['data']?['balance'] as num?)?.toDouble();
        if (balance != null) return balance;
      }
      debugPrint('Verify attempt ${i + 1} failed: ${response.error}');
    }
    return null;
  }

  /// Start the Khalti payment flow.
  /// Returns the new wallet balance on success, null on failure/cancel.
  Future<double?> startPayment({
    required BuildContext context,
    required double amountNpr,
  }) async {
    // Initiate payment via backend
    final initResponse = await _apiService.initiateKhaltiPayment(amountNpr);

    if (!initResponse.success || initResponse.data == null) {
      debugPrint('Khalti initiate failed: ${initResponse.error}');
      return null;
    }

    final pidx = initResponse.data!['data']?['pidx'] as String?;
    if (pidx == null) {
      debugPrint('No pidx returned from backend');
      return null;
    }

    final completer = Completer<double?>();

    final khaltiInstance = await Khalti.init(
      enableDebugging: true,
      payConfig: KhaltiPayConfig(
        publicKey: '1fcad9f0b9ba47a58c8f57f0a8574c12',
        pidx: pidx,
        environment: Environment.test,
      ),
      onPaymentResult: (paymentResult, khalti) async {
        debugPrint('Khalti onPaymentResult: ${paymentResult.payload?.status}');
        // ignore: use_build_context_synchronously
        khalti.close(context);
        final balance = await _verifyWithRetry(pidx);
        if (!completer.isCompleted) completer.complete(balance);
      },
      onMessage: (khalti, {description, statusCode, event, needsPaymentConfirmation}) async {
        debugPrint('Khalti onMessage: $description | event: $event | confirm: $needsPaymentConfirmation');

        // kpgDisposed is normal cleanup — ignore
        if (event == KhaltiEvent.kpgDisposed) return;

        // ignore: use_build_context_synchronously
        khalti.close(context);

        // Wait to let onPaymentResult fire first (it's the reliable callback)
        await Future.delayed(const Duration(seconds: 1));
        if (completer.isCompleted) return;

        // Payment might have succeeded — verify with backend
        final balance = await _verifyWithRetry(pidx);
        if (!completer.isCompleted) completer.complete(balance);
      },
      onReturn: () {
        debugPrint('Khalti return_url loaded');
      },
    );

    if (!context.mounted) return null;
    khaltiInstance.open(context);

    return completer.future;
  }
}
