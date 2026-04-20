import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class OperatorDashboardScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;

  const OperatorDashboardScreen({super.key, this.onSwitchTab});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.getOperatorDashboard();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.success && res.data != null) {
          _stats = res.data!['data'];
        } else {
          _error = res.error;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser;
    final isPending = user?.approvalStatus == 'Pending';
    final isRejected = user?.approvalStatus == 'Rejected';

    return Scaffold(
      backgroundColor: AppColors.operatorBg,
      appBar: AppBar(
        backgroundColor: AppColors.operatorPrimary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              user?.operatorName ?? user?.email ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.operatorPrimary,
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Approval status banner
              if (isPending) const _ApprovalBanner(
                icon: Icons.hourglass_top,
                color: Color(0xFFF59E0B),
                bgColor: Color(0xFFFFFBEB),
                title: 'Account Pending Approval',
                subtitle: 'Admin is reviewing your application. You cannot manage vehicles or drivers until approved.',
              ),
              if (isRejected) const _ApprovalBanner(
                icon: Icons.cancel_outlined,
                color: Color(0xFFEF4444),
                bgColor: Color(0xFFFEF2F2),
                title: 'Application Rejected',
                subtitle: 'Your operator application was rejected. Please contact admin for details.',
              ),
              if (!isPending && !isRejected) const _ApprovalBanner(
                icon: Icons.verified,
                color: Color(0xFF10B981),
                bgColor: Color(0xFFECFDF5),
                title: 'Account Approved',
                subtitle: 'Your account is active. You can manage vehicles and drivers.',
              ),
              const SizedBox(height: 20),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.operatorPrimary),
                  ),
                )
              else if (_error != null && isPending)
                // Unapproved operators see a placeholder instead of stats
                _PendingPlaceholder()
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('Could not load stats', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadDashboard,
                          child: const Text('Retry', style: TextStyle(color: AppColors.operatorPrimary)),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Stats cards row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.directions_bus,
                        label: 'Total Vehicles',
                        value: _stats?['vehicles']?['total']?.toString() ?? '0',
                        color: AppColors.operatorPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline,
                        label: 'Approved',
                        value: _stats?['vehicles']?['approved']?.toString() ?? '0',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.badge,
                        label: 'Drivers',
                        value: _stats?['drivers']?.toString() ?? '0',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.directions_run,
                        label: "Today's Rides",
                        value: _stats?['todayRides']?.toString() ?? '0',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.account_balance_wallet,
                  label: "Today's Revenue",
                  value: 'Rs. ${(_stats?['todayRevenue'] ?? 0).toStringAsFixed(0)}',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 20),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.operatorDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add_box_outlined,
                        label: 'Add Vehicle',
                        color: AppColors.operatorPrimary,
                        onTap: () {
                          widget.onSwitchTab?.call(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.person_add_outlined,
                        label: 'Add Driver',
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          widget.onSwitchTab?.call(2);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;

  const _ApprovalBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_top, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Stats will be available after your account is approved by admin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
