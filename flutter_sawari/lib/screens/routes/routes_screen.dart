import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart' as api;
import '../../services/api_service.dart';
import 'route_details_screen.dart';
import 'trip_planner_widget.dart';

// Local route model used by UI widgets
class RouteModel {
  final int id;
  final String name;
  final String start;
  final String end;
  final int baseFare;
  final List<StopModel> stops;

  const RouteModel({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.baseFare,
    required this.stops,
  });

  // Convert from API RouteModel
  factory RouteModel.fromApiRoute(api.RouteModel route) {
    return RouteModel(
      id: route.id,
      name: route.code,
      start: route.firstStop ?? 'N/A',
      end: route.lastStop ?? 'N/A',
      baseFare: (route.maxFare ?? 0).toInt(),
      stops: route.stops
          .map((s) => StopModel(name: s.name, fare: s.sequence ?? 0))
          .toList(),
    );
  }
}

class StopModel {
  final String name;
  final int fare;

  const StopModel({required this.name, required this.fare});
}

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  String _searchQuery = '';
  RouteModel? _selectedRoute;
  bool _isLoading = false;
  List<api.RouteModel> _apiRoutes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getRoutes();

      if (response.success && response.data != null) {
        final routesData = response.data!['data']?['routes'] as List?;
        if (routesData != null) {
          setState(() {
            _apiRoutes =
                routesData.map((r) => api.RouteModel.fromJson(r)).toList();
          });
        }
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load routes';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Make sure backend is running.';
      });
      debugPrint('Error loading routes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRouteDetails(api.RouteModel route) async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.getRouteById(route.id);

      if (response.success && response.data != null) {
        final routeData = response.data!['data']?['route'];
        final stopsData = response.data!['data']?['stops'] as List?;

        if (routeData != null) {
          final detailedRoute = api.RouteModel.fromJson(routeData);
          final stops =
              stopsData?.map((s) => api.StopModel.fromJson(s)).toList() ?? [];

          final routeWithStops = detailedRoute.copyWithStops(stops);
          setState(() {
            _selectedRoute = RouteModel.fromApiRoute(routeWithStops);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading route details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<api.RouteModel> get _filteredRoutes {
    if (_searchQuery.isEmpty) return _apiRoutes;
    final q = _searchQuery.toLowerCase();
    return _apiRoutes.where((route) {
      return route.name.toLowerCase().contains(q) ||
          route.code.toLowerCase().contains(q) ||
          (route.firstStop?.toLowerCase().contains(q) ?? false) ||
          (route.lastStop?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // If a route is selected, show its details
    if (_selectedRoute != null) {
      return RouteDetailsScreen(
        route: _selectedRoute!,
        onBack: () => setState(() => _selectedRoute = null),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.gray900 : AppColors.gray50;
    final textColor = isDark ? Colors.white : AppColors.gray900;
    final subtitleColor = isDark ? AppColors.gray400 : AppColors.gray600;
    final cardBg = isDark ? AppColors.gray800 : Colors.white;

    // Convert for trip planner widget
    final legacyRoutes =
        _apiRoutes.map((r) => RouteModel.fromApiRoute(r)).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRoutes,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 16),
                Text(
                  'Bus Routes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan your trip and view routes',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                                color: isDark ? Colors.orange[200] : Colors.orange[800],
                                fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.orange, size: 20),
                          onPressed: _loadRoutes,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Trip Planner
                if (legacyRoutes.isNotEmpty) TripPlannerWidget(routes: legacyRoutes),
                const SizedBox(height: 16),

                // Browse All Routes
                Text(
                  'Browse All Routes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray800 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.gray600 : AppColors.gray300,
                    ),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search routes or stops',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Routes List
                else if (_filteredRoutes.isNotEmpty)
                  ..._filteredRoutes.map((route) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _loadRouteDetails(route),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(13),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E3A5F)
                                        : const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.directions_bus,
                                    color: isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF2563EB),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        route.code,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        route.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${route.firstStop ?? "?"} → ${route.lastStop ?? "?"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 14,
                                              color: isDark
                                                  ? AppColors.emerald400
                                                  : AppColors.emerald600),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${route.stopCount} stops',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.emerald400
                                                  : AppColors.emerald600,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.payments,
                                              size: 14,
                                              color: isDark
                                                  ? AppColors.emerald400
                                                  : AppColors.emerald600),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Max NPR ${route.maxFare?.toStringAsFixed(0) ?? "?"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.emerald400
                                                  : AppColors.emerald600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: isDark
                                      ? AppColors.gray500
                                      : AppColors.gray400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))
                else if (!_isLoading && _apiRoutes.isEmpty && _error == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_bus,
                            size: 48,
                            color:
                                isDark ? AppColors.gray600 : AppColors.gray300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No routes available',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.gray500
                                  : AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredRoutes.isEmpty && _searchQuery.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color:
                                isDark ? AppColors.gray600 : AppColors.gray300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No routes match "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.gray500
                                  : AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
