import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../services/khalti_payment_service.dart';

class BuyTokensModal extends StatefulWidget {
  const BuyTokensModal({super.key});

  @override
  State<BuyTokensModal> createState() => _BuyTokensModalState();
}

class _BuyTokensModalState extends State<BuyTokensModal> {
  static const List<Map<String, int>> _tokenPackages = [
    {'tokens': 50, 'npr': 250},
    {'tokens': 100, 'npr': 500},
    {'tokens': 200, 'npr': 1000},
    {'tokens': 500, 'npr': 2500},
  ];

  int _selectedIndex = 1; // default to 100 tokens
  bool _useCustom = false;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int get _displayTokens {
    if (_useCustom) {
      return int.tryParse(_customController.text) ?? 0;
    }
    return _tokenPackages[_selectedIndex]['tokens']!;
  }

  int get _displayNpr {
    if (_useCustom) {
      return (_displayTokens * 5);
    }
    return _tokenPackages[_selectedIndex]['npr']!;
  }

  bool _isProcessing = false;

  void _handlePurchase() async {
    final tokens = _displayTokens;
    if (tokens <= 0) return;

    // Check if RFID card is assigned
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.currentUser?.rfidCardId == null) {
      Navigator.pop(context);
      AppSnackBar.show(
        context,
        message: 'RFID card not registered. Please visit the admin office to get an RFID card before topping up.',
        type: SnackBarType.warning,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final amountNpr = _displayNpr.toDouble();

    setState(() => _isProcessing = true);

    try {
      final newBalance = await KhaltiPaymentService().startPayment(
        context: context,
        amountNpr: amountNpr,
      );

      if (!mounted) return;

      if (newBalance != null) {
        // Refresh balance in app state
        await appState.refreshBalance();

        if (!mounted) return;
        Navigator.pop(context);
        AppSnackBar.show(
          context,
          message: 'Top-up of NPR ${amountNpr.toInt()} successful!',
          type: SnackBarType.success,
        );
      } else {
        setState(() => _isProcessing = false);
        AppSnackBar.show(
          context,
          message: 'Payment was not completed. Please try again.',
          type: SnackBarType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      AppSnackBar.show(
        context,
        message: 'Payment failed. Please try again.',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.gray800 : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.gray900;
    final subtitleColor = isDark ? AppColors.gray400 : AppColors.gray600;
    final summaryBg = isDark ? AppColors.gray700 : AppColors.gray50;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Buy Tokens',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray700 : AppColors.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Token Packages
            Text(
              'Select a package',
              style: TextStyle(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemCount: _tokenPackages.length,
              itemBuilder: (context, index) {
                final pkg = _tokenPackages[index];
                final isSelected = !_useCustom && _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                      _useCustom = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.emerald900.withValues(alpha: 0.3)
                              : AppColors.emerald50)
                          : (isDark ? AppColors.gray700 : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 2,
                        color: isSelected
                            ? (isDark
                                ? AppColors.emerald400
                                : AppColors.emerald500)
                            : (isDark ? AppColors.gray600 : AppColors.gray200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${pkg['tokens']} Tokens',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pkg['npr']} NPR',
                          style: TextStyle(fontSize: 14, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Custom Amount
            Text(
              'Or enter custom amount',
              style: TextStyle(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {
                        _useCustom = _customController.text.isNotEmpty;
                      });
                    },
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Enter tokens',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.gray700 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.gray600 : AppColors.gray300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.gray600 : AppColors.gray300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.emerald400
                              : AppColors.emerald500,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  constraints: const BoxConstraints(minWidth: 100),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray700 : AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _customController.text.isNotEmpty
                          ? '${(int.tryParse(_customController.text) ?? 0) * 5} NPR'
                          : '0 NPR',
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: summaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tokens to buy:',
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                      ),
                      Text(
                        '$_displayTokens',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount to pay:',
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                      ),
                      Text(
                        '$_displayNpr NPR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Purchase Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing || (_useCustom && _customController.text.isEmpty)
                    ? null
                    : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.emerald500 : AppColors.emerald600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? AppColors.gray600 : AppColors.gray300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Pay with Khalti',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
