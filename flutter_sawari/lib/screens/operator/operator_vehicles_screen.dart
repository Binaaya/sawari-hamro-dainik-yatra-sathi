import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';

class OperatorVehiclesScreen extends StatefulWidget {
  const OperatorVehiclesScreen({super.key});

  @override
  State<OperatorVehiclesScreen> createState() => _OperatorVehiclesScreenState();
}

class _OperatorVehiclesScreenState extends State<OperatorVehiclesScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.getOperatorVehicles();
    final driversRes = await _api.getOperatorDrivers();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.success && res.data != null) {
          _vehicles = List<Map<String, dynamic>>.from(
              res.data!['data']?['vehicles'] ?? []);
        } else {
          _error = res.error;
        }
        if (driversRes.success && driversRes.data != null) {
          _drivers = List<Map<String, dynamic>>.from(
              driversRes.data!['data']?['drivers'] ?? []);
        }
      });
    }
  }

  void _showAddVehicleDialog() {
    final regCtrl = TextEditingController();
    String vehicleType = 'Bus';
    final seatsCtrl = TextEditingController(text: '40');
    final modelYearCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? bluebookPath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Vehicle',
              style: TextStyle(color: AppColors.operatorDark, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogLabel('Registration Number'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: regCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _dialogField('e.g. BA 1 KHA 1234'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Vehicle Type'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: vehicleType,
                    decoration: _dialogField(''),
                    items: const [
                      DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                      DropdownMenuItem(value: 'Minibus', child: Text('Minibus')),
                      DropdownMenuItem(value: 'Microbus', child: Text('Microbus')),
                    ],
                    onChanged: (v) => setDialogState(() => vehicleType = v!),
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Seating Capacity'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: seatsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogField('Number of seats'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Model Year'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: modelYearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogField('e.g. 2020'),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final year = int.tryParse(v.trim());
                        if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                          return 'Enter a valid year';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Bluebook Photo *'),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      try {
                        final result = await FilePicker.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null && result.files.single.path != null) {
                          setDialogState(() => bluebookPath = result.files.single.path!);
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackBar.show(context,
                              message: 'Could not open gallery: $e',
                              type: SnackBarType.error);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bluebookPath != null
                            ? AppColors.operatorPrimary.withValues(alpha: 0.08)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: bluebookPath != null
                              ? AppColors.operatorPrimary
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            bluebookPath != null ? Icons.check_circle : Icons.upload_file,
                            size: 20,
                            color: bluebookPath != null
                                ? AppColors.operatorPrimary
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bluebookPath != null ? 'Bluebook selected' : 'Tap to upload bluebook',
                              style: TextStyle(
                                fontSize: 13,
                                color: bluebookPath != null
                                    ? AppColors.operatorPrimary
                                    : Colors.grey[700],
                                fontWeight: bluebookPath != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (bluebookPath != null)
                            GestureDetector(
                              onTap: () => setDialogState(() => bluebookPath = null),
                              child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (bluebookPath == null) {
                  AppSnackBar.show(context,
                      message: 'Bluebook photo is required',
                      type: SnackBarType.warning);
                  return;
                }
                Navigator.pop(ctx);
                final res = await _api.createVehicle(
                  registrationNumber: regCtrl.text.trim().toUpperCase(),
                  vehicleType: vehicleType,
                  seatingCapacity: int.tryParse(seatsCtrl.text.trim()) ?? 40,
                  modelYear: modelYearCtrl.text.trim().isNotEmpty
                      ? int.tryParse(modelYearCtrl.text.trim())
                      : null,
                  bluebookPath: bluebookPath!,
                );
                if (mounted) {
                  if (res.success) {
                    AppSnackBar.show(context,
                        message: 'Vehicle registered. Pending admin approval.',
                        type: SnackBarType.success);
                    _load();
                  } else {
                    AppSnackBar.show(context,
                        message: res.error ?? 'Failed to add vehicle',
                        type: SnackBarType.error);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operatorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVehicleDialog(Map<String, dynamic> vehicle) {
    String vehicleType = vehicle['vehicletype'] ?? 'Bus';
    final seatsCtrl = TextEditingController(
        text: (vehicle['seatingcapacity'] ?? 40).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Vehicle',
              style: TextStyle(
                  color: AppColors.operatorDark, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogLabel('Registration Number'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      vehicle['registrationnumber'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Vehicle Type'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: vehicleType,
                    decoration: _dialogField(''),
                    items: const [
                      DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                      DropdownMenuItem(
                          value: 'Minibus', child: Text('Minibus')),
                      DropdownMenuItem(
                          value: 'Microbus', child: Text('Microbus')),
                    ],
                    onChanged: (v) => setDialogState(() => vehicleType = v!),
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Seating Capacity'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: seatsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogField('Number of seats'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final res = await _api.updateVehicle(
                  vehicle['vehicleid'] as int,
                  vehicleType: vehicleType,
                  seatingCapacity:
                      int.tryParse(seatsCtrl.text.trim()) ?? 40,
                );
                if (mounted) {
                  if (res.success) {
                    AppSnackBar.show(context,
                        message: 'Vehicle updated successfully',
                        type: SnackBarType.success);
                    _load();
                  } else {
                    AppSnackBar.show(context,
                        message: res.error ?? 'Failed to update vehicle',
                        type: SnackBarType.error);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operatorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDriverDialog(Map<String, dynamic> vehicle) {
    final unassignedDrivers = _drivers
        .where((d) => d['assigned_vehicle'] == null || d['assigned_vehicle'] == '')
        .toList();

    if (unassignedDrivers.isEmpty) {
      AppSnackBar.show(context,
          message: 'No unassigned drivers available. Add a driver first.',
          type: SnackBarType.warning);
      return;
    }

    int? selectedDriverId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Assign Driver',
              style: TextStyle(color: AppColors.operatorDark, fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<int>(
            decoration: _dialogField('Select a driver'),
            initialValue: selectedDriverId,
            items: unassignedDrivers.map((d) {
              return DropdownMenuItem<int>(
                value: d['driverid'] as int,
                child: Text(d['driversname'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (v) => setDialogState(() => selectedDriverId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: selectedDriverId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final res = await _api.assignDriverToVehicle(
                          vehicle['vehicleid'] as int, selectedDriverId!);
                      if (mounted) {
                        if (res.success) {
                          AppSnackBar.show(context,
                              message: 'Driver assigned successfully',
                              type: SnackBarType.success);
                          _load();
                        } else {
                          AppSnackBar.show(context,
                              message: res.error ?? 'Failed to assign driver',
                              type: SnackBarType.error);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operatorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser;
    final isApproved = user?.approvalStatus == 'Approved';

    return Scaffold(
      backgroundColor: AppColors.operatorBg,
      appBar: AppBar(
        backgroundColor: AppColors.operatorPrimary,
        foregroundColor: Colors.white,
        title: const Text('Vehicles'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: isApproved
          ? FloatingActionButton(
              backgroundColor: AppColors.operatorPrimary,
              foregroundColor: Colors.white,
              onPressed: _showAddVehicleDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.operatorPrimary))
          : !isApproved
              ? const _PendingMessage(
                  icon: Icons.directions_bus_outlined,
                  message: 'Vehicle management is available after admin approves your account.',
                )
              : _error != null
                  ? _ErrorView(onRetry: _load)
                  : _vehicles.isEmpty
                      ? const _EmptyView(
                          icon: Icons.directions_bus_outlined,
                          message: 'No vehicles yet.\nTap + to register your first vehicle.',
                        )
                      : RefreshIndicator(
                          color: AppColors.operatorPrimary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _vehicles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final v = _vehicles[i];
                              return _VehicleCard(
                                vehicle: v,
                                onEdit: () => _showEditVehicleDialog(v),
                                onAssignDriver: () => _showAssignDriverDialog(v),
                                onUnassignDriver: () async {
                                  final res = await _api.unassignDriverFromVehicle(
                                      v['vehicleid'] as int);
                                  if (context.mounted) {
                                    if (res.success) {
                                      AppSnackBar.show(context,
                                          message: 'Driver unassigned',
                                          type: SnackBarType.success);
                                      _load();
                                    } else {
                                      AppSnackBar.show(context,
                                          message: res.error ?? 'Failed',
                                          type: SnackBarType.error);
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onAssignDriver;
  final VoidCallback onUnassignDriver;
  final VoidCallback onEdit;

  const _VehicleCard({
    required this.vehicle,
    required this.onAssignDriver,
    required this.onUnassignDriver,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = vehicle['approvalstatus'] ?? 'Pending';
    final hasDriver = vehicle['driver_name'] != null;

    Color statusColor;
    switch (status) {
      case 'Approved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'Rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.operatorPrimary.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.operatorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_bus,
                    color: AppColors.operatorPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['registrationnumber'] ?? '',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.operatorDark),
                    ),
                    Text(
                      '${vehicle['vehicletype'] ?? ''} · ${vehicle['seatingcapacity'] ?? 0} seats',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.operatorPrimary,
                onPressed: onEdit,
                tooltip: 'Edit vehicle',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person,
                  size: 16,
                  color: hasDriver ? AppColors.operatorPrimary : Colors.grey[400]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasDriver
                      ? 'Driver: ${vehicle['driver_name']}'
                      : 'No driver assigned',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasDriver ? AppColors.operatorDark : Colors.grey[500],
                  ),
                ),
              ),
              if (hasDriver)
                TextButton(
                  onPressed: onUnassignDriver,
                  child: const Text('Remove',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                )
              else
                TextButton(
                  onPressed: onAssignDriver,
                  child: const Text('Assign Driver',
                      style: TextStyle(color: AppColors.operatorPrimary, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

InputDecoration _dialogField(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400]),
    filled: true,
    fillColor: AppColors.operatorBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFBBDEFB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFBBDEFB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.operatorPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

Widget _dialogLabel(String text) {
  return Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.operatorDark));
}

class _PendingMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const _PendingMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Failed to load', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: AppColors.operatorPrimary)),
          ),
        ],
      ),
    );
  }
}
