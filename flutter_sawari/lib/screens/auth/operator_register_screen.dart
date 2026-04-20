import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import 'email_verification_screen.dart';

class OperatorRegisterScreen extends StatefulWidget {
  const OperatorRegisterScreen({super.key});

  @override
  State<OperatorRegisterScreen> createState() => _OperatorRegisterScreenState();
}

class _OperatorRegisterScreenState extends State<OperatorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  String? _businessDocPath;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _panCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_businessDocPath == null) {
      AppSnackBar.show(context,
          message: 'Business document is required',
          type: SnackBarType.warning);
      return;
    }

    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final result = await appState.registerOperator(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      panNumber: _panCtrl.text.trim(),
      businessDocPath: _businessDocPath,
    );
    setState(() => _isLoading = false);

    if (result.success && result.needsEmailVerification) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: _emailCtrl.text.trim(),
              pendingRegistration: result.pendingRegistration!,
            ),
          ),
        );
      }
    } else if (!result.success) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: AppSnackBar.friendlyError(appState.error),
          type: SnackBarType.error,
        );
        appState.clearError();
      }
    }
  }

  InputDecoration _field(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF90CAF9)),
      filled: true,
      fillColor: const Color(0xFFE3F2FD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF90CAF9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBBDEFB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.operatorPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operatorBg,
      appBar: AppBar(
        backgroundColor: AppColors.operatorPrimary,
        foregroundColor: Colors.white,
        title: const Text('Register as Operator'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.operatorLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.operatorPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bus Operator Registration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.operatorDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Submit your details. Admin will review and approve your account.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Full Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _field('Your full name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    _label('Company / Business Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyCtrl,
                      decoration: _field('e.g. Sharma Bus Service'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    _label('Phone Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _field('e.g. 9800000000'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone number is required';
                        if (v.trim().length < 10) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Email Address'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _field('business@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('PAN Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _panCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _field('Business PAN number'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'PAN number is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Business Document *'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        try {
                          final result = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                          );
                          if (result != null && result.files.single.path != null) {
                            setState(() => _businessDocPath = result.files.single.path!);
                          }
                        } catch (e) {
                          if (mounted) {
                            AppSnackBar.show(context,
                                message: 'Could not open gallery: $e',
                                type: SnackBarType.error);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _businessDocPath != null
                              ? AppColors.operatorPrimary.withValues(alpha: 0.08)
                              : const Color(0xFFE3F2FD),
                          border: Border.all(
                            color: _businessDocPath != null
                                ? AppColors.operatorPrimary
                                : AppColors.operatorPrimary.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _businessDocPath != null ? Icons.check_circle : Icons.upload_file,
                              color: _businessDocPath != null ? Colors.green : AppColors.operatorPrimary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _businessDocPath != null
                                    ? _businessDocPath!.split(RegExp(r'[/\\]')).last
                                    : 'Tap to upload business document',
                                style: TextStyle(
                                  color: _businessDocPath != null ? Colors.green : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_businessDocPath != null)
                              GestureDetector(
                                onTap: () => setState(() => _businessDocPath = null),
                                child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      decoration: _field(
                        'Min. 6 characters',
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.operatorPrimary,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Confirm Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      decoration: _field(
                        'Re-enter your password',
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.operatorPrimary,
                          ),
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.operatorPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.how_to_reg, size: 20),
                                  SizedBox(width: 8),
                                  Text('Register Business',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(color: AppColors.operatorPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.operatorDark,
      ),
    );
  }
}
