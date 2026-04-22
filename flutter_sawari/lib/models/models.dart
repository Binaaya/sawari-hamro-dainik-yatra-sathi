/// Route model matching backend API response
class RouteModel {
  final int id;
  final String name;
  final String code;
  final bool isActive;
  final int stopCount;
  final String? firstStop;
  final String? lastStop;
  final double? maxFare;
  final List<StopModel> stops;

  RouteModel({
    required this.id,
    required this.name,
    required this.code,
    this.isActive = true,
    this.stopCount = 0,
    this.firstStop,
    this.lastStop,
    this.maxFare,
    this.stops = const [],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['routeid'],
      name: json['routename'] ?? '',
      code: json['routecode'] ?? '',
      isActive: json['isactive'] ?? true,
      stopCount: int.tryParse(json['stop_count']?.toString() ?? '0') ?? 0,
      firstStop: json['first_stop'],
      lastStop: json['last_stop'],
      maxFare: double.tryParse(json['maxfarenpr']?.toString() ?? '0'),
    );
  }

  /// Create a copy with stops
  RouteModel copyWithStops(List<StopModel> stops) {
    return RouteModel(
      id: id,
      name: name,
      code: code,
      isActive: isActive,
      stopCount: stops.length,
      firstStop: stops.isNotEmpty ? stops.first.name : firstStop,
      lastStop: stops.isNotEmpty ? stops.last.name : lastStop,
      maxFare: maxFare,
      stops: stops,
    );
  }

  /// Get display name (code: start - end)
  String get displayName => '$code: ${firstStop ?? 'N/A'} - ${lastStop ?? 'N/A'}';
}

/// Stop model matching backend API response
class StopModel {
  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final int? sequence;
  final double? distanceFromStart;

  StopModel({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.sequence,
    this.distanceFromStart,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['stopid'],
      name: json['stopname'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      sequence: json['stopsequence'],
      distanceFromStart:
          double.tryParse(json['distancefromstartkm']?.toString() ?? ''),
    );
  }
}

/// User model matching backend API response
class UserModel {
  final int id;
  final String? firebaseUid;
  final String email;
  final String? phone;
  final String role;
  final String accountStatus;
  final DateTime? createdAt;

  // Passenger-specific fields
  final int? passengerId;
  final String? fullName;
  final String? address;
  final String? profilePicture;
  final double? balance;
  final String? citizenshipNumber;
  final int? rfidCardId;
  final String? rfidCardUid;

  // Operator-specific fields
  final int? operatorId;
  final String? operatorName;
  final String? approvalStatus;

  UserModel({
    required this.id,
    this.firebaseUid,
    required this.email,
    this.phone,
    required this.role,
    this.accountStatus = 'Active',
    this.createdAt,
    this.passengerId,
    this.fullName,
    this.address,
    this.profilePicture,
    this.balance,
    this.citizenshipNumber,
    this.rfidCardId,
    this.rfidCardUid,
    this.operatorId,
    this.operatorName,
    this.approvalStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userid'],
      firebaseUid: json['firebaseuid'],
      email: json['email'] ?? '',
      phone: json['phonenumber'],
      role: json['role'] ?? 'Passenger',
      accountStatus: json['accountstatus'] ?? 'Active',
      createdAt: json['createdat'] != null
          ? DateTime.tryParse(json['createdat'])
          : null,
      passengerId: json['passengerid'],
      fullName: json['fullname'],
      address: json['address'],
      profilePicture: json['profilepicture'],
      balance: double.tryParse(json['accountbalancenpr']?.toString() ?? ''),
      citizenshipNumber: json['citizenshipnumber'],
      rfidCardId: json['rfidcardid'],
      rfidCardUid: json['carduid'],
      operatorId: json['operatorid'],
      operatorName: json['operatorname'],
      approvalStatus: json['approvalstatus'] ?? json['operator_approved'],
    );
  }

  bool get isPassenger => role == 'Passenger';
  bool get isOperator => role == 'Operator';
  bool get isAdmin => role == 'Admin';
}

/// Ride model matching backend API response
class RideModel {
  final int id;
  final int passengerId;
  final int vehicleId;
  final int routeId;
  final String? routeName;
  final String? entryStopName;
  final String? exitStopName;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final double? fare;
  final double? balanceBefore;
  final double? balanceAfter;
  final String status;

  RideModel({
    required this.id,
    required this.passengerId,
    required this.vehicleId,
    required this.routeId,
    this.routeName,
    this.entryStopName,
    this.exitStopName,
    this.entryTime,
    this.exitTime,
    this.fare,
    this.balanceBefore,
    this.balanceAfter,
    required this.status,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['rideid'],
      passengerId: json['passengerid'],
      vehicleId: json['vehicleid'],
      routeId: json['routeid'],
      routeName: json['routename'],
      entryStopName: json['entry_stop_name'],
      exitStopName: json['exit_stop_name'],
      entryTime: json['entrytime'] != null
          ? DateTime.tryParse(json['entrytime'])
          : null,
      exitTime:
          json['exittime'] != null ? DateTime.tryParse(json['exittime']) : null,
      fare: double.tryParse(json['fareamountnpr']?.toString() ?? ''),
      balanceBefore:
          double.tryParse(json['balancebeforeentrynpr']?.toString() ?? ''),
      balanceAfter:
          double.tryParse(json['balanceafterexitnpr']?.toString() ?? ''),
      status: json['ridestatus'] ?? 'Unknown',
    );
  }

  bool get isCompleted => status == 'Completed';
  bool get isOngoing => status == 'Ongoing';
  bool get isCancelled => status == 'Cancelled';
}

/// Transaction model matching backend API response
class TransactionModel {
  final int id;
  final int userId;
  final String type;
  final double amount;
  final String paymentMethod;
  final int? rideId;
  final double balanceBefore;
  final double balanceAfter;
  final DateTime? transactionTime;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    this.rideId,
    required this.balanceBefore,
    required this.balanceAfter,
    this.transactionTime,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['transactionid'],
      userId: json['userid'],
      type: json['transactiontype'] ?? 'Unknown',
      amount: double.tryParse(json['amountnpr']?.toString() ?? '0') ?? 0,
      paymentMethod: json['paymentmethod'] ?? 'Unknown',
      rideId: json['rideid'],
      balanceBefore:
          double.tryParse(json['balancebeforenpr']?.toString() ?? '0') ?? 0,
      balanceAfter:
          double.tryParse(json['balanceafternpr']?.toString() ?? '0') ?? 0,
      transactionTime: json['transactiontime'] != null
          ? DateTime.tryParse(json['transactiontime'])
          : null,
    );
  }

  bool get isTopUp => type == 'TopUp';
  bool get isRidePayment => type == 'RidePayment';
}

/// Complaint model matching backend API response
class ComplaintModel {
  final int id;
  final String complaintText;
  final String status;
  final DateTime? complaintDate;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final int? rideId;
  final String? routeName;
  final String? complainantName;
  final String? complainantRole;

  ComplaintModel({
    required this.id,
    required this.complaintText,
    required this.status,
    this.complaintDate,
    this.resolutionNotes,
    this.resolvedAt,
    this.rideId,
    this.routeName,
    this.complainantName,
    this.complainantRole,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['complaintid'],
      complaintText: json['complainttext'] ?? '',
      status: json['complaintstatus'] ?? 'Pending',
      complaintDate: json['complaintdate'] != null
          ? DateTime.tryParse(json['complaintdate'])
          : null,
      resolutionNotes: json['resolutionnotes'],
      resolvedAt: json['resolvedat'] != null
          ? DateTime.tryParse(json['resolvedat'])
          : null,
      rideId: json['rideid'],
      routeName: json['routename'],
      complainantName: json['complainant_name'],
      complainantRole: json['complainant_role'],
    );
  }

  bool get isPending => status == 'Pending';
  bool get isInProgress => status == 'InProgress';
  bool get isResolved => status == 'Resolved';
  bool get isRejected => status == 'Rejected';
}

