import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

/// Authentication Service using Firebase and Backend API
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  /// Current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current Firebase ID token
  Future<String?> getIdToken() async {
    return await currentUser?.getIdToken();
  }

  /// Update API service with current token
  Future<void> _updateApiToken() async {
    final token = await getIdToken();
    _apiService.setAuthToken(token);
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _updateApiToken();

        // Get user info from backend
        final response = await _apiService.getCurrentUser();

        if (response.success && response.data != null) {
          return AuthResult(
            success: true,
            user: credential.user,
            userData: response.data!['data']?['user'],
          );
        } else if (response.error != null &&
            (response.error!.contains('SocketException') ||
             response.error!.contains('timeout') ||
             response.error!.contains('Connection refused'))) {
          // Backend unreachable — not a registration error
          await signOut();
          return AuthResult(success: false, error: response.error);
        } else {
          // User exists in Firebase but not in backend
          return AuthResult(
            success: true,
            user: credential.user,
            needsRegistration: true,
          );
        }
      }

      return AuthResult(success: false, error: 'Login failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Create new user with email and password (sends verification email)
  Future<AuthResult> createUserWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? citizenshipNumber,
    String? address,
    String role = 'Passenger',
    String? companyName,
    String? panNumber,
    String? businessDocPath,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Send email verification before backend registration
        await credential.user!.sendEmailVerification();

        return AuthResult(
          success: true,
          user: credential.user,
          needsEmailVerification: true,
          pendingRegistration: {
            'fullName': fullName,
            'phone': phone,
            'citizenshipNumber': citizenshipNumber,
            'address': address,
            'role': role,
            if (companyName != null) 'companyName': companyName,
            if (panNumber != null) 'panNumber': panNumber,
            if (businessDocPath != null) 'businessDocPath': businessDocPath,
          },
        );
      }

      return AuthResult(success: false, error: 'Registration failed');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Handle incomplete registration (Firebase-only account)
        // Attempt sign-in to recover partial registration
        try {
          final credential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (credential.user != null) {
            await _updateApiToken();
            final meResponse = await _apiService.getCurrentUser();
            if (meResponse.success && meResponse.data?['data']?['user'] != null) {
              // User fully registered — redirect to login
              await _firebaseAuth.signOut();
              return AuthResult(success: false, error: _getFirebaseErrorMessage(e.code));
            }

            // Firebase-only account — recover incomplete registration
            if (!credential.user!.emailVerified) {
              await credential.user!.sendEmailVerification();
            }
            return AuthResult(
              success: true,
              user: credential.user,
              needsEmailVerification: true,
              pendingRegistration: {
                'fullName': fullName,
                'phone': phone,
                'citizenshipNumber': citizenshipNumber,
                'address': address,
                'role': role,
                if (companyName != null) 'companyName': companyName,
                if (panNumber != null) 'panNumber': panNumber,
                if (businessDocPath != null) 'businessDocPath': businessDocPath,
              },
            );
          }
        } catch (_) {
          // Sign-in failed — propagate original error
        }
      }
      return AuthResult(success: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Complete registration after email verification
  Future<AuthResult> completeRegistration({
    required String fullName,
    required String phone,
    String? citizenshipNumber,
    String? address,
    String role = 'Passenger',
    String? companyName,
    String? panNumber,
    String? businessDocPath,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult(success: false, error: 'No user logged in');
      }

      // Reload to get latest emailVerified status
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        return AuthResult(success: false, error: 'Email not verified yet');
      }

      await _updateApiToken();

      final response = await _apiService.register(
        firebaseUid: refreshedUser.uid,
        email: refreshedUser.email ?? '',
        phone: phone,
        fullName: fullName,
        citizenshipNumber: citizenshipNumber,
        address: address,
        role: role,
        companyName: companyName,
        panNumber: panNumber,
        businessDocPath: businessDocPath,
      );

      if (response.success) {
        return AuthResult(
          success: true,
          user: refreshedUser,
          userData: response.data?['data']?['user'],
        );
      } else {
        final error = response.error ?? 'Registration failed';
        final isNetworkError = error.contains('SocketException') ||
            error.contains('TimeoutException') ||
            error.contains('Connection refused');

        // Backend rejected — remove Firebase user to allow fresh registration
        if (!isNetworkError) {
          try {
            await refreshedUser.delete();
          } catch (_) {}
        }

        return AuthResult(success: false, error: error);
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Resend verification email
  Future<AuthResult> resendVerificationEmail() async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult(success: false, error: 'No user logged in');
      }
      await user.sendEmailVerification();
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _apiService.setAuthToken(null);
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Get user-friendly error message
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please check your credentials and try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with letters and numbers.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'invalid-verification-code':
        return 'Invalid OTP code. Please check and try again.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Please include country code (e.g. +977).';
      case 'network-request-failed':
        return 'Unable to connect. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'This login method is not enabled. Please contact support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

/// Result of authentication operations
class AuthResult {
  final bool success;
  final User? user;
  final Map<String, dynamic>? userData;
  final String? error;
  final bool needsRegistration;
  final bool needsEmailVerification;
  final Map<String, dynamic>? pendingRegistration;

  AuthResult({
    required this.success,
    this.user,
    this.userData,
    this.error,
    this.needsRegistration = false,
    this.needsEmailVerification = false,
    this.pendingRegistration,
  });
}
