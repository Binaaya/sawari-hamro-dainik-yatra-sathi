import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';

class OperatorDriversScreen extends StatefulWidget {
  const OperatorDriversScreen({super.key});

  @override
  State<OperatorDriversScreen> createState() => _OperatorDriversScreenState();
}

class _OperatorDriversScreenState extends State<OperatorDriversScreen> {
  final ApiService _api = ApiService();
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
    final res = await _api.getOperatorDrivers();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.success && res.data != null) {
          _drivers = List<Map<String, dynamic>>.from(
              res.data!['data']?['drivers'] ?? []);
        } else {
          _error = res.error;
        }
      });
    }
  }

  void _showAddDriverDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    DateTime? expiryDate;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Driver',
              style: TextStyle(color: AppColors.operatorDark, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogLabel('Full Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _dialogField("Driver's full name"),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('Phone Number'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dialogField('e.g. 9800000000'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 10) return 'Enter a valid phone';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('License Number'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: licenseCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _dialogField('e.g. 0101234560'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _dialogLabel('License Expiry Date'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2040),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.operatorPrimary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => expiryDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.operatorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: expiryDate == null
                              ? const Color(0xFFBBDEFB)
                              : AppColors.operatorPrimary,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18,
                              color: expiryDate == null
                                  ? Colors.grey[400]
                                  : AppColors.operatorPrimary),
                          const SizedBox(width: 10),
                          Text(
                            expiryDate == null
                                ? 'Select expiry date'
                                : '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: expiryDate == null
                                  ? Colors.grey[400]
                                  : AppColors.operatorDark,
                            ),
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
                if (expiryDate == null) {
                  AppSnackBar.show(ctx,
                      message: 'Please select license expiry date',
                      type: SnackBarType.warning);
                  return;
                }
                Navigator.pop(ctx);
                final expiryStr =
                    '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}';
                final res = await _api.createDriver(
                  driversName: nameCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim(),
                  licenseNumber: licenseCtrl.text.trim().toUpperCase(),
                  licenseExpiryDate: expiryStr,
                );
                if (mounted) {
                  if (res.success) {
                    AppSnackBar.show(context,
                        message: 'Driver added successfully',
                        type: SnackBarType.success);
                    _load();
                  } else {
                    AppSnackBar.show(context,
                        message: res.error ?? 'Failed to add driver',
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDriverDialog(Map<String, dynamic> driver) {
    final nameCtrl =
        TextEditingController(text: driver['driversname'] ?? '');
    final phoneCtrl =
        TextEditingController(text: driver['phonenumber'] ?? '');
    final licenseCtrl =
        TextEditingController(text: driver['licensenumber'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Driver',
            style: TextStyle(
                color: AppColors.operatorDark, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogLabel('Full Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  decoration: _dialogField("Driver's full name"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _dialogLabel('Phone Number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dialogField('e.g. 9800000000'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 10) return 'Enter a valid phone';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _dialogLabel('License Number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: licenseCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _dialogField('e.g. 0101234560'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
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
              Navigator.pop(ctx);
              final res = await _api.updateDriver(
                driver['driverid'] as int,
                driversName: nameCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
                licenseNumber: licenseCtrl.text.trim().toUpperCase(),
              );
              if (mounted) {
                if (res.success) {
                  AppSnackBar.show(context,
                      message: 'Driver updated successfully',
                      type: SnackBarType.success);
                  _load();
                } else {
                  AppSnackBar.show(context,
                      message: res.error ?? 'Failed to update driver',
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
    );
  }

  Future<void> _deleteDriver(Map<String, dynamic> driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Driver'),
        content: Text(
            'Remove ${driver['driversname']}? They will be unassigned from any vehicle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _api.deleteDriver(driver['driverid'] as int);
      if (mounted) {
        if (res.success) {
          AppSnackBar.show(context,
              message: 'Driver removed', type: SnackBarType.success);
          _load();
        } else {
          AppSnackBar.show(context,
              message: res.error ?? 'Failed to remove driver',
              type: SnackBarType.error);
        }
      }
    }
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
        title: const Text('Drivers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: isApproved
          ? FloatingActionButton(
              backgroundColor: AppColors.operatorPrimary,
              foregroundColor: Colors.white,
              onPressed: _showAddDriverDialog,
              child: const Icon(Icons.person_add),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.operatorPrimary))
          : !isApproved
              ? _centeredMessage(
                  Icons.badge_outlined,
                  'Driver management is available after admin approves your account.',
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Failed to load drivers',
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry',
                                style: TextStyle(color: AppColors.operatorPrimary)),
                          ),
                        ],
                      ),
                    )
                  : _drivers.isEmpty
                      ? _centeredMessage(
                          Icons.badge_outlined,
                          'No drivers yet.\nTap + to add your first driver.',
                        )
                      : RefreshIndicator(
                          color: AppColors.operatorPrimary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _drivers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final d = _drivers[i];
                              return _DriverCard(
                                driver: d,
                                onEdit: () => _showEditDriverDialog(d),
                                onDelete: () => _deleteDriver(d),
                              );
                            },
                          ),
                        ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _DriverCard({
    required this.driver,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final assignedVehicle = driver['assigned_vehicle'];

    // License expiry logic
    DateTime? expiryDate;
    bool isExpired = false;
    bool isExpiringSoon = false;
    if (driver['licenseexpirydate'] != null) {
      try {
        expiryDate = DateTime.parse(driver['licenseexpirydate'].toString());
        final now = DateTime.now();
        isExpired = expiryDate.isBefore(now);
        isExpiringSoon =
            !isExpired && expiryDate.isBefore(now.add(const Duration(days: 30)));
      } catch (_) {}
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.operatorLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: AppColors.operatorPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver['driversname'] ?? '',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.operatorDark),
                ),
                const SizedBox(height: 3),
                Text(
                  driver['phonenumber'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
                Text(
                  'License: ${driver['licensenumber'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (expiryDate != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        isExpired
                            ? Icons.error
                            : isExpiringSoon
                                ? Icons.warning_amber
                                : Icons.calendar_today,
                        size: 12,
                        color: isExpired
                            ? const Color(0xFFEF4444)
                            : isExpiringSoon
                                ? const Color(0xFFF59E0B)
                                : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpired
                            ? 'Expired: ${_formatDate(expiryDate)}'
                            : 'Expires: ${_formatDate(expiryDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              (isExpired || isExpiringSoon) ? FontWeight.w600 : FontWeight.normal,
                          color: isExpired
                              ? const Color(0xFFEF4444)
                              : isExpiringSoon
                                  ? const Color(0xFFF59E0B)
                                  : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
                if (assignedVehicle != null && assignedVehicle != '') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          size: 14, color: AppColors.operatorPrimary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Assigned: $assignedVehicle',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.operatorPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.operatorPrimary,
            onPressed: onEdit,
            tooltip: 'Edit driver',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: onDelete,
            tooltip: 'Remove driver',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

Widget _centeredMessage(IconData icon, String message) {
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
