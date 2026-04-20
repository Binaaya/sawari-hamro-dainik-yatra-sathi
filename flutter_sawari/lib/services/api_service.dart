import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API endpoint configuration
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({required this.success, this.data, this.error});
}

/// Main API Service for communicating with the backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  /// Set the auth token (Firebase ID token)
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get headers with auth token
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Generic GET request
  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Generic POST request
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Generic PUT request
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<Map<String, dynamic>>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Handle HTTP response
  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: data['success'] ?? true,
          data: data,
        );
      } else {
        return ApiResponse(
          success: false,
          error: data['error'] ?? 'Request failed',
          data: data,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to parse response: $e',
      );
    }
  }

  // Route Endpoints

  /// Get all routes
  Future<ApiResponse<Map<String, dynamic>>> getRoutes() {
    return get('/routes');
  }

  /// Get route by ID with stops
  Future<ApiResponse<Map<String, dynamic>>> getRouteById(int routeId) {
    return get('/routes/$routeId');
  }

  /// Get all stops
  Future<ApiResponse<Map<String, dynamic>>> getAllStops() {
    return get('/routes/stops/all');
  }

  /// Calculate fare between stops
  Future<ApiResponse<Map<String, dynamic>>> calculateFare(
    int routeId,
    int fromStopId,
    int toStopId,
  ) {
    return get('/routes/$routeId/fare?from_stop=$fromStopId&to_stop=$toStopId');
  }

  /// Search routes by stop names
  Future<ApiResponse<Map<String, dynamic>>> searchRoutes(
    String fromStop,
    String toStop,
  ) {
    return get('/routes/search/by-stops?from=$fromStop&to=$toStop');
  }

  // Passenger Endpoints

  /// Get passenger balance
  Future<ApiResponse<Map<String, dynamic>>> getBalance() {
    return get('/passengers/balance');
  }

  /// Get passenger profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() {
    return get('/passengers/profile');
  }

  /// Get ride history
  Future<ApiResponse<Map<String, dynamic>>> getRideHistory({
    int page = 1,
    int limit = 20,
  }) {
    return get('/passengers/rides?page=$page&limit=$limit');
  }

  // Transaction Endpoints

  /// Get transaction history
  Future<ApiResponse<Map<String, dynamic>>> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) {
    String endpoint = '/transactions?page=$page&limit=$limit';
    if (type != null) endpoint += '&type=$type';
    return get(endpoint);
  }

  /// Get transaction summary
  Future<ApiResponse<Map<String, dynamic>>> getTransactionSummary() {
    return get('/transactions/summary');
  }

  // Complaint Endpoints

  /// Get complaints
  Future<ApiResponse<Map<String, dynamic>>> getComplaints({
    int page = 1,
    int limit = 20,
  }) {
    return get('/complaints?page=$page&limit=$limit');
  }

  /// Create complaint
  Future<ApiResponse<Map<String, dynamic>>> createComplaint({
    int? rideId,
    required String complaintText,
  }) {
    return post('/complaints', {
      if (rideId != null) 'rideId': rideId,
      'complaintText': complaintText,
    });
  }

  // Notification Endpoints

  /// Register FCM token for push notifications
  Future<ApiResponse<Map<String, dynamic>>> registerFcmToken({
    required String fcmToken,
    String deviceType = 'android',
  }) {
    return post('/notifications/register-token', {
      'fcmToken': fcmToken,
      'deviceType': deviceType,
    });
  }

  /// Get notifications
  Future<ApiResponse<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) {
    return get('/notifications?page=$page&limit=$limit');
  }

  /// Mark notification as read
  Future<ApiResponse<Map<String, dynamic>>> markNotificationRead(int id) {
    return put('/notifications/$id/read', {});
  }

  // Payment Endpoints (Khalti)

  /// Initiate Khalti payment (returns pidx)
  Future<ApiResponse<Map<String, dynamic>>> initiateKhaltiPayment(double amount) {
    return post('/payments/khalti/initiate', {'amount': amount});
  }

  /// Verify Khalti payment after user completes checkout
  Future<ApiResponse<Map<String, dynamic>>> verifyKhaltiPayment(String pidx) {
    return post('/payments/khalti/verify', {'pidx': pidx});
  }

  // Auth Endpoints

  /// Register new user
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String firebaseUid,
    required String email,
    required String phone,
    required String fullName,
    String? citizenshipNumber,
    String? address,
    String role = 'Passenger',
    String? companyName,
    String? panNumber,
    String? businessDocPath,
  }) async {
    if (businessDocPath != null) {
      // Multipart upload for operator with business document
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
        final request = http.MultipartRequest('POST', uri);
        if (_authToken != null) {
          request.headers['Authorization'] = 'Bearer $_authToken';
        }
        request.fields['firebaseUid'] = firebaseUid;
        request.fields['email'] = email;
        request.fields['phone'] = phone;
        request.fields['fullName'] = fullName;
        request.fields['role'] = role;
        if (companyName != null) request.fields['companyName'] = companyName;
        if (panNumber != null) request.fields['panNumber'] = panNumber;
        request.files.add(await http.MultipartFile.fromPath('businessDocument', businessDocPath));

        final streamed = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamed);
        return _handleResponse(response);
      } catch (e) {
        return ApiResponse(success: false, error: e.toString());
      }
    }

    return post('/auth/register', {
      'firebaseUid': firebaseUid,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      if (citizenshipNumber != null) 'citizenshipNumber': citizenshipNumber,
      if (address != null) 'address': address,
      'role': role,
      if (companyName != null) 'companyName': companyName,
      if (panNumber != null) 'panNumber': panNumber,
    });
  }

  // Operator Endpoints

  Future<ApiResponse<Map<String, dynamic>>> getOperatorProfile() =>
      get('/operators/profile');

  Future<ApiResponse<Map<String, dynamic>>> getOperatorDashboard() =>
      get('/operators/dashboard');

  Future<ApiResponse<Map<String, dynamic>>> getOperatorVehicles() =>
      get('/operators/vehicles');

  Future<ApiResponse<Map<String, dynamic>>> createVehicle({
    required String registrationNumber,
    required String vehicleType,
    required String bluebookPath,
    int seatingCapacity = 40,
    int? modelYear,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/operators/vehicles');
      final request = http.MultipartRequest('POST', uri);

      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.fields['registrationNumber'] = registrationNumber;
      request.fields['vehicleType'] = vehicleType;
      request.fields['seatingCapacity'] = seatingCapacity.toString();
      if (modelYear != null) {
        request.fields['modelYear'] = modelYear.toString();
      }

      request.files.add(await http.MultipartFile.fromPath('bluebook', bluebookPath));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getOperatorDrivers() =>
      get('/operators/drivers');

  Future<ApiResponse<Map<String, dynamic>>> createDriver({
    required String driversName,
    required String phoneNumber,
    required String licenseNumber,
    required String licenseExpiryDate,
  }) =>
      post('/operators/drivers', {
        'driversName': driversName,
        'phoneNumber': phoneNumber,
        'licenseNumber': licenseNumber,
        'licenseExpiryDate': licenseExpiryDate,
      });

  Future<ApiResponse<Map<String, dynamic>>> deleteDriver(int driverId) =>
      delete('/operators/drivers/$driverId');

  Future<ApiResponse<Map<String, dynamic>>> assignDriverToVehicle(
          int vehicleId, int driverId) =>
      post('/operators/vehicles/$vehicleId/assign-driver',
          {'driverId': driverId});

  Future<ApiResponse<Map<String, dynamic>>> unassignDriverFromVehicle(
          int vehicleId) =>
      delete('/operators/vehicles/$vehicleId/unassign-driver');

  Future<ApiResponse<Map<String, dynamic>>> updateVehicle(
          int vehicleId,
          {String? vehicleType, int? seatingCapacity}) =>
      put('/operators/vehicles/$vehicleId', {
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (seatingCapacity != null) 'seatingCapacity': seatingCapacity,
      });

  Future<ApiResponse<Map<String, dynamic>>> updateDriver(
          int driverId,
          {String? driversName,
          String? phoneNumber,
          String? licenseNumber}) =>
      put('/operators/drivers/$driverId', {
        if (driversName != null) 'driversName': driversName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
      });

  Future<ApiResponse<Map<String, dynamic>>> getVehicleRoutes(int vehicleId) =>
      get('/operators/vehicles/$vehicleId/routes');

  /// Get current user profile
  Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() {
    return get('/auth/me');
  }

  /// Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? profilePicturePath,
  }) async {
    if (profilePicturePath != null) {
      // Multipart upload when profile picture is included
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/profile');
        final request = http.MultipartRequest('PUT', uri);
        if (_authToken != null) {
          request.headers['Authorization'] = 'Bearer $_authToken';
        }
        if (fullName != null) request.fields['fullName'] = fullName;
        if (phone != null) request.fields['phone'] = phone;
        if (address != null) request.fields['address'] = address;
        request.files.add(await http.MultipartFile.fromPath('profilepicture', profilePicturePath));

        final streamed = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamed);
        return _handleResponse(response);
      } catch (e) {
        return ApiResponse(success: false, error: e.toString());
      }
    }

    return put('/auth/profile', {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    });
  }

  // Test Endpoints

  /// Test API connection
  Future<ApiResponse<Map<String, dynamic>>> testConnection() {
    return get('/test');
  }

  /// Test database connection
  Future<ApiResponse<Map<String, dynamic>>> testDatabase() {
    return get('/test/db');
  }

  /// Get database stats
  Future<ApiResponse<Map<String, dynamic>>> getStats() {
    return get('/test/stats');
  }
}
