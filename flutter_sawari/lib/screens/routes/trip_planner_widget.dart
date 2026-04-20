import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'routes_screen.dart';

class JourneySegment {
  final RouteModel route;
  final String fromStop;
  final String toStop;
  final int fare;

  const JourneySegment({
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.fare,
  });
}

class TripPlannerWidget extends StatefulWidget {
  final List<RouteModel> routes;

  const TripPlannerWidget({super.key, required this.routes});

  @override
  State<TripPlannerWidget> createState() => _TripPlannerWidgetState();
}

class _TripPlannerWidgetState extends State<TripPlannerWidget> {
  String? _fromLocation;
  String? _toLocation;
  List<JourneySegment>? _journey;
  bool _noRouteFound = false;

  List<String> get _allStops {
    final stops = <String>{};
    for (final route in widget.routes) {
      for (final stop in route.stops) {
        stops.add(stop.name);
      }
    }
    final list = stops.toList();
    list.sort();
    return list;
  }

  void _findJourney() {
    if (_fromLocation == null || _toLocation == null) return;
    if (_fromLocation == _toLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting point and destination cannot be the same.'),
        ),
      );
      return;
    }

    setState(() {
      _noRouteFound = false;
      _journey = null;
    });

    // Try direct route
    for (final route in widget.routes) {
      final fromIndex =
          route.stops.indexWhere((s) => s.name == _fromLocation);
      final toIndex = route.stops.indexWhere((s) => s.name == _toLocation);

      if (fromIndex != -1 && toIndex != -1 && fromIndex < toIndex) {
        final fare = route.stops[toIndex].fare - route.stops[fromIndex].fare;
        setState(() {
          _journey = [
            JourneySegment(
              route: route,
              fromStop: _fromLocation!,
              toStop: _toLocation!,
              fare: fare,
            ),
          ];
        });
        return;
      }
    }

    // Try one transfer
    for (final route1 in widget.routes) {
      final fromIndex1 =
          route1.stops.indexWhere((s) => s.name == _fromLocation);
      if (fromIndex1 == -1) continue;

      for (int i = fromIndex1 + 1; i < route1.stops.length; i++) {
        final transferStop = route1.stops[i].name;

        for (final route2 in widget.routes) {
          if (route2.id == route1.id) continue;

          final transferIndex =
              route2.stops.indexWhere((s) => s.name == transferStop);
          final toIndex2 =
              route2.stops.indexWhere((s) => s.name == _toLocation);

          if (transferIndex != -1 &&
              toIndex2 != -1 &&
              transferIndex < toIndex2) {
            final fare1 =
                route1.stops[i].fare - route1.stops[fromIndex1].fare;
            final fare2 =
                route2.stops[toIndex2].fare - route2.stops[transferIndex].fare;

            setState(() {
              _journey = [
                JourneySegment(
                  route: route1,
                  fromStop: _fromLocation!,
                  toStop: transferStop,
                  fare: fare1,
                ),
                JourneySegment(
                  route: route2,
                  fromStop: transferStop,
                  toStop: _toLocation!,
                  fare: fare2,
                ),
              ];
            });
            return;
          }
        }
      }
    }

    setState(() => _noRouteFound = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.gray800 : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.gray900;
    final subtitleColor = isDark ? AppColors.gray400 : AppColors.gray600;
    final dropdownBg = isDark ? AppColors.gray700 : Colors.white;
    final borderColor = isDark ? AppColors.gray600 : AppColors.gray300;

    final totalFare =
        _journey?.fold<int>(0, (sum, s) => sum + s.fare) ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 16,
                color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              ),
              const SizedBox(width: 8),
              Text(
                'Plan Your Trip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdowns
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: dropdownBg,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _fromLocation,
                      hint: Text(
                        'From',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                      ),
                      isExpanded: true,
                      dropdownColor: dropdownBg,
                      style: TextStyle(fontSize: 14, color: textColor),
                      items: _allStops
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _fromLocation = val;
                          _journey = null;
                          _noRouteFound = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: dropdownBg,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _toLocation,
                      hint: Text(
                        'To',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                      ),
                      isExpanded: true,
                      dropdownColor: dropdownBg,
                      style: TextStyle(fontSize: 14, color: textColor),
                      items: _allStops
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _toLocation = val;
                          _journey = null;
                          _noRouteFound = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Find Route Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_fromLocation != null && _toLocation != null)
                      ? _findJourney
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.emerald500 : AppColors.emerald600,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDark ? AppColors.gray600 : AppColors.gray300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              child: const Text(
                'Find Route',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Journey Results
          if (_journey != null && _journey!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
                color: isDark ? AppColors.gray700 : AppColors.gray200,
                height: 1),
            const SizedBox(height: 12),

            // Total Fare
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.emerald900.withValues(alpha: 0.3)
                    : AppColors.emerald50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Fare:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.gray300 : AppColors.gray700,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$totalFare',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.emerald400
                              : AppColors.emerald600,
                        ),
                      ),
                      Text(
                        ' tokens',
                        style: TextStyle(
                          fontSize: 14,
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

            // Transfer warning
            if (_journey!.length > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.2)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: isDark
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transfer at ${_journey![0].toStop}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Segments
            const SizedBox(height: 8),
            ..._journey!.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray700 : AppColors.gray50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 12,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                segment.route.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${segment.fromStop} → ${segment.toStop}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${segment.fare} tokens',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.emerald400
                                : AppColors.emerald600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < _journey!.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                      ),
                    ),
                ],
              );
            }),
          ],

          // No route found
          if (_noRouteFound) ...[
            const SizedBox(height: 12),
            Divider(
                color: isDark ? AppColors.gray700 : AppColors.gray200,
                height: 1),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: isDark
                        ? const Color(0xFFF87171)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No route found between these locations.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF7F1D1D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
