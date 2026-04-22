import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_snackbar.dart';

/// Main app state provider
class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  /// Expose API service for notification queries etc.
  ApiService get apiService => _apiService;

  // Auth state
  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _error;

  // Routes data
  List<RouteModel> _routes = [];
  bool _routesLoading = false;

  // Rides data
  List<RideModel> _recentRides = [];
  bool _ridesLoading = false;

  // Active ride data
  RideModel? _activeRide;
  bool _activeRideLoading = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get error => _error;
  double get balance => _currentUser?.balance ?? 0;

  List<RouteModel> get routes => _routes;
  bool get routesLoading => _routesLoading;

  List<RideModel> get recentRides => _recentRides;
  bool get ridesLoading => _ridesLoading;

  RideModel? get activeRide => _activeRide;
  bool get activeRideLoading => _activeRideLoading;
  bool get hasActiveRide => _activeRide != null;

  /// Initialize app state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Check if user is logged in
    if (_authService.isLoggedIn) {
      await _loadUserData();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with email/password
  /// [expectedRole] - if provided, rejects login if user role doesn't match
  Future<bool> login(String email, String password, {String? expectedRole}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signInWithEmailPassword(
      email: email,
      password: password,
    );

    if (result.success) {
      if (result.needsRegistration) {
        _error = 'Your account setup is incomplete. Please register again or contact support.';
        await _authService.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (result.userData != null) {
        _currentUser = UserModel.fromJson(result.userData!);

        // Check if account is suspended/inactive
        if (_currentUser!.accountStatus != 'Active') {
          _error = 'Your account is ${_currentUser!.accountStatus.toLowerCase()}. Please contact support for help.';
          _currentUser = null;
          await _authService.signOut();
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Block wrong role (e.g. operator trying passenger login)
        if (expectedRole != null && _currentUser!.role != expectedRole) {
          _error = _currentUser!.role == 'Operator'
              ? 'This is an operator account. Please use the Operator Login.'
              : 'This is a passenger account. Please use the Passenger Login.';
          _currentUser = null;
          await _authService.signOut();
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isAuthenticated = true;
        await _loadInitialData();
        // Start polling for notifications
        NotificationService().startPolling();
      }
    } else {
      _error = AppSnackBar.friendlyError(result.error);
    }

    _isLoading = false;
    notifyListeners();
    return result.success && !result.needsRegistration;
  }

  /// Register new operator
  Future<AuthResult> registerOperator({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String companyName,
    String? panNumber,
    String? businessDocPath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.createUserWithEmailPassword(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: 'Operator',
      companyName: companyName,
      panNumber: panNumber,
      businessDocPath: businessDocPath,
    );

    if (!result.success) {
      _error = AppSnackBar.friendlyError(result.error);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Register new user (creates Firebase account + sends verification email)
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? citizenshipNumber,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.createUserWithEmailPassword(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      citizenshipNumber: citizenshipNumber,
      address: address,
    );

    if (!result.success) {
      _error = AppSnackBar.friendlyError(result.error);
    }

    _isLoading = false;
    notifyListeners();
    return result;
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.completeRegistration(
      fullName: fullName,
      phone: phone,
      citizenshipNumber: citizenshipNumber,
      address: address,
      role: role,
      companyName: companyName,
      panNumber: panNumber,
      businessDocPath: businessDocPath,
    );

    if (result.success && result.userData != null) {
      _currentUser = UserModel.fromJson(result.userData!);
      _isAuthenticated = true;
      await _loadInitialData();
    } else {
      _error = AppSnackBar.friendlyError(result.error);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Resend verification email
  Future<AuthResult> resendVerificationEmail() async {
    final result = await _authService.resendVerificationEmail();
    if (!result.success) {
      _error = result.error;
    }
    return result;
  }

  /// Logout
  Future<void> logout() async {
    NotificationService().stopPolling();
    await _authService.signOut();
    _isAuthenticated = false;
    _currentUser = null;
    _routes = [];
    _recentRides = [];
    _activeRide = null;
    notifyListeners();
  }

  /// Load user data from backend
  Future<void> _loadUserData() async {
    final token = await _authService.getIdToken();
    _apiService.setAuthToken(token);

    final response = await _apiService.getCurrentUser();

    if (response.success && response.data != null) {
      final userData = response.data!['data']?['user'];
      if (userData != null) {
        _currentUser = UserModel.fromJson(userData);
        _isAuthenticated = true;
        // Start polling for notifications
        NotificationService().startPolling();
      }
    }
  }

  /// Load initial data after login
  Future<void> _loadInitialData() async {
    if (_currentUser?.isOperator == true) {
      // Operators don't need passenger-specific data
      return;
    }
    await Future.wait([
      loadRoutes(),
      loadRecentRides(),
      loadActiveRide(),
    ]);
  }

  /// Load all routes
  Future<void> loadRoutes() async {
    _routesLoading = true;
    notifyListeners();

    final response = await _apiService.getRoutes();

    if (response.success && response.data != null) {
      final routesData = response.data!['data']?['routes'] as List?;
      if (routesData != null) {
        _routes = routesData.map((r) => RouteModel.fromJson(r)).toList();
      }
    }

    _routesLoading = false;
    notifyListeners();
  }

  /// Load route details with stops
  Future<RouteModel?> loadRouteDetails(int routeId) async {
    final response = await _apiService.getRouteById(routeId);

    if (response.success && response.data != null) {
      final routeData = response.data!['data']?['route'];
      final stopsData = response.data!['data']?['stops'] as List?;

      if (routeData != null) {
        final route = RouteModel.fromJson(routeData);
        final stops =
            stopsData?.map((s) => StopModel.fromJson(s)).toList() ?? [];
        return route.copyWithStops(stops);
      }
    }
    return null;
  }

  /// Load recent rides
  Future<void> loadRecentRides() async {
    if (!_isAuthenticated) return;

    _ridesLoading = true;
    notifyListeners();

    final response = await _apiService.getRideHistory(limit: 5);

    if (response.success && response.data != null) {
      final ridesData = response.data!['data']?['rides'] as List?;
      if (ridesData != null) {
        _recentRides = ridesData.map((r) => RideModel.fromJson(r)).toList();
      }
    }

    _ridesLoading = false;
    notifyListeners();
  }

  /// Load active/ongoing ride
  Future<void> loadActiveRide() async {
    if (!_isAuthenticated) return;

    _activeRideLoading = true;
    notifyListeners();

    final response = await _apiService.get('/rides/status/ongoing');

    if (response.success && response.data != null) {
      final rideData = response.data!['data']?['ride'];
      if (rideData != null) {
        _activeRide = RideModel.fromJson(rideData);
      } else {
        _activeRide = null;
      }
    } else {
      _activeRide = null;
    }

    _activeRideLoading = false;
    notifyListeners();
  }

  /// Refresh user balance
  Future<void> refreshBalance() async {
    if (!_isAuthenticated) return;

    final response = await _apiService.getBalance();

    if (response.success && response.data != null) {
      final balanceData = response.data!['data'];
      if (balanceData != null && _currentUser != null) {
        // Create new user with updated balance
        _currentUser = UserModel(
          id: _currentUser!.id,
          firebaseUid: _currentUser!.firebaseUid,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          role: _currentUser!.role,
          accountStatus: _currentUser!.accountStatus,
          passengerId: _currentUser!.passengerId,
          fullName: _currentUser!.fullName,
          address: _currentUser!.address,
          balance:
              double.tryParse(balanceData['balance']?.toString() ?? '0') ?? 0,
          citizenshipNumber: _currentUser!.citizenshipNumber,
          rfidCardId: _currentUser!.rfidCardId,
          rfidCardUid: _currentUser!.rfidCardUid,
        );
        notifyListeners();
      }
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
