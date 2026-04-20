import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final ApiService _api = ApiService();
  final _complaintController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  bool get _isOperator =>
      Provider.of<AppState>(context, listen: false).currentUser?.isOperator ??
      false;

  Color get _primaryColor =>
      _isOperator ? AppColors.operatorPrimary : AppColors.emerald600;

  Color get _bgColor =>
      _isOperator ? AppColors.operatorBg : AppColors.gray50;

  Color get _lightColor =>
      _isOperator ? AppColors.operatorLight : const Color(0xFFECFDF5);

  Color get _darkColor =>
      _isOperator ? AppColors.operatorDark : AppColors.emerald800;

  Future<void> _loadComplaints() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.getComplaints();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.success && res.data != null) {
          final list = res.data!['data']?['complaints'] as List? ?? [];
          _complaints = list
              .map((c) =>
                  ComplaintModel.fromJson(Map<String, dynamic>.from(c)))
              .toList();
        } else {
          _error = res.error;
        }
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final res = await _api.createComplaint(
      complaintText: _complaintController.text.trim(),
    );

    if (mounted) {
      setState(() => _submitting = false);

      if (res.success) {
        _complaintController.clear();
        AppSnackBar.show(context,
            message: 'Complaint submitted successfully',
            type: SnackBarType.success);
        _loadComplaints();
      } else {
        AppSnackBar.show(context,
            message: res.error ?? 'Failed to submit complaint',
            type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Complaints'),
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _loadComplaints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File a complaint form
              _buildComplaintForm(),
              const SizedBox(height: 24),

              // Complaints list
              Text(
                'Your Complaints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildComplaintsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: _primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'File a Complaint',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _complaintController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe your complaint...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: _lightColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please describe your complaint';
                }
                if (v.trim().length < 10) {
                  return 'Complaint must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitComplaint,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_submitting ? 'Submitting...' : 'Submit Complaint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsList() {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('Failed to load complaints',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadComplaints,
                child: Text('Retry',
                    style: TextStyle(color: _primaryColor)),
              ),
            ],
          ),
        ),
      );
    }

    if (_complaints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No complaints filed yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _complaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ComplaintCard(
        complaint: _complaints[i],
        primaryColor: _primaryColor,
        darkColor: _darkColor,
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final Color primaryColor;
  final Color darkColor;

  const _ComplaintCard({
    required this.complaint,
    required this.primaryColor,
    required this.darkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.complaintText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: darkColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: complaint.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                _formatDate(complaint.complaintDate),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              if (complaint.routeName != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.route, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    complaint.routeName!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ],
            ],
          ),
          if (complaint.resolutionNotes != null &&
              complaint.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resolution',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaint.resolutionNotes!,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Pending':
        color = const Color(0xFFF59E0B);
        break;
      case 'InProgress':
        color = const Color(0xFF3B82F6);
        break;
      case 'Resolved':
        color = const Color(0xFF10B981);
        break;
      case 'Rejected':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
