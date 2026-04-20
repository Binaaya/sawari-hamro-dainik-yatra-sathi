import 'dart:async';
import 'package:flutter/material.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'api_service.dart';

class KhaltiPaymentService {
  static final KhaltiPaymentService _instance = KhaltiPaymentService._internal();
  factory KhaltiPaymentService() => _instance;
  KhaltiPaymentService._internal();

  final ApiService _apiService = ApiService();

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

    // Bridge callback-based SDK with async/await
    final completer = Completer<double?>();

    // Initialize Khalti SDK
    final khaltiInstance = await Khalti.init(
      enableDebugging: true,
      payConfig: KhaltiPayConfig(
        publicKey: '1fcad9f0b9ba47a58c8f57f0a8574c12',
        pidx: pidx,
        environment: Environment.test,
      ),
      onPaymentResult: (paymentResult, khalti) async {
        debugPrint('Khalti payment result: ${paymentResult.payload?.status}');
        // ignore: use_build_context_synchronously
        khalti.close(context);
        // Verify payment with backend
        final verifyResponse = await _apiService.verifyKhaltiPayment(pidx);
        if (verifyResponse.success && verifyResponse.data != null) {
          final balance = (verifyResponse.data!['data']?['balance'] as num?)?.toDouble();
          completer.complete(balance);
        } else {
          debugPrint('Backend verify failed: ${verifyResponse.error}');
          completer.complete(null);
        }
      },
      onMessage: (khalti, {description, statusCode, event, needsPaymentConfirmation}) async {
        debugPrint('Khalti message: $description | event: $event | needsConfirmation: $needsPaymentConfirmation');
        if (needsPaymentConfirmation == true) {
          // Payment status uncertain — verify with backend
          await khalti.verify();
        }
        // ignore: use_build_context_synchronously
        khalti.close(context);
        if (!completer.isCompleted) completer.complete(null);
      },
      onReturn: () {
        debugPrint('Khalti return_url loaded');
      },
    );

    // Open payment UI
    if (!context.mounted) return null;
    khaltiInstance.open(context);

    // Await payment completion
    return completer.future;
  }
}
