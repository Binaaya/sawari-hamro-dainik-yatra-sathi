import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'routes_screen.dart';

class RouteDetailsScreen extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onBack;

  const RouteDetailsScreen({
    super.key,
    required this.route,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.gray900 : AppColors.gray50;
    final textColor = isDark ? Colors.white : AppColors.gray900;
    final cardBg = isDark ? AppColors.gray800 : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Gradient Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), AppColors.emerald600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Back to Routes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  route.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${route.start} → ${route.end}',
                  style: const TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Base fare: ${route.baseFare} tokens',
                  style: const TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Stops List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Stops',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                      children: route.stops.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value;
                        final isFirst = index == 0;
                        final isLast = index == route.stops.length - 1;

                        Color iconBg;
                        Color iconColor;
                        if (isFirst) {
                          iconBg = isDark
                              ? AppColors.emerald900.withValues(alpha: 0.3)
                              : AppColors.emerald100;
                          iconColor = isDark
                              ? AppColors.emerald400
                              : AppColors.emerald600;
                        } else if (isLast) {
                          iconBg = isDark
                              ? const Color(0xFF1E3A5F)
                              : const Color(0xFFDBEAFE);
                          iconColor = isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB);
                        } else {
                          iconBg = isDark ? AppColors.gray700 : AppColors.gray100;
                          iconColor = isDark
                              ? AppColors.gray400
                              : AppColors.gray600;
                        }

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon with connector line
                                  SizedBox(
                                    width: 40,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: iconBg,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            size: 20,
                                            color: iconColor,
                                          ),
                                        ),
                                        if (!isLast)
                                          Positioned(
                                            left: 19,
                                            top: 40,
                                            child: Container(
                                              width: 2,
                                              height: 32,
                                              color: isDark
                                                  ? AppColors.gray700
                                                  : AppColors.gray200,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Stop info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stop.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                        if (isFirst)
                                          Text(
                                            'Starting point',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark
                                                  ? AppColors.emerald400
                                                  : AppColors.emerald600,
                                            ),
                                          ),
                                        if (isLast)
                                          Text(
                                            'Final destination',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark
                                                  ? const Color(0xFF60A5FA)
                                                  : const Color(0xFF2563EB),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Fare
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${stop.fare}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        'tokens',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.gray400
                                              : AppColors.gray500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                color: isDark
                                    ? AppColors.gray700
                                    : AppColors.gray100,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A5F).withValues(alpha: 0.2)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      'Note: Token costs are calculated from the starting point. Tap in when boarding and tap out when exiting.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
