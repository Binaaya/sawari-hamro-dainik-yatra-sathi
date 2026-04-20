import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class OperatorRoutesScreen extends StatefulWidget {
  const OperatorRoutesScreen({super.key});

  @override
  State<OperatorRoutesScreen> createState() => _OperatorRoutesScreenState();
}

class _OperatorRoutesScreenState extends State<OperatorRoutesScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _vehicles = [];
  final Map<int, List<Map<String, dynamic>>> _vehicleRoutes = {};
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
    if (!mounted) return;

    if (res.success && res.data != null) {
      final vehicles = List<Map<String, dynamic>>.from(
          res.data!['data']?['vehicles'] ?? []);

      // Fetch routes for each vehicle
      final routesMap = <int, List<Map<String, dynamic>>>{};
      for (final v in vehicles) {
        final vehicleId = v['vehicleid'] as int;
        final routesRes = await _api.getVehicleRoutes(vehicleId);
        if (routesRes.success && routesRes.data != null) {
          routesMap[vehicleId] = List<Map<String, dynamic>>.from(
              routesRes.data!['data']?['routes'] ?? []);
        } else {
          routesMap[vehicleId] = [];
        }
      }

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _vehicleRoutes.clear();
          _vehicleRoutes.addAll(routesMap);
          _loading = false;
        });
      }
    } else {
      setState(() {
        _error = res.error;
        _loading = false;
      });
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
        title: const Text('Routes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.operatorPrimary))
          : !isApproved
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Route information is available after admin approves your account.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Failed to load routes',
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry',
                                style: TextStyle(
                                    color: AppColors.operatorPrimary)),
                          ),
                        ],
                      ),
                    )
                  : _vehicles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.route,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'No vehicles yet.\nAdd vehicles first to see assigned routes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.operatorPrimary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: _vehicles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final vehicle = _vehicles[i];
                              final vehicleId = vehicle['vehicleid'] as int;
                              final routes = _vehicleRoutes[vehicleId] ?? [];
                              return _VehicleRoutesCard(
                                vehicle: vehicle,
                                routes: routes,
                              );
                            },
                          ),
                        ),
    );
  }
}

class _VehicleRoutesCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final List<Map<String, dynamic>> routes;

  const _VehicleRoutesCard({
    required this.vehicle,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Vehicle header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.operatorDark,
                        ),
                      ),
                      Text(
                        '${vehicle['vehicletype'] ?? ''} · ${routes.length} route${routes.length == 1 ? '' : 's'}',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (routes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No routes assigned to this vehicle',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            const Divider(height: 1),
            ...routes.map((route) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.route,
                            size: 16, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route['routename'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.operatorDark,
                              ),
                            ),
                            if (route['routecode'] != null)
                              Text(
                                'Code: ${route['routecode']}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
