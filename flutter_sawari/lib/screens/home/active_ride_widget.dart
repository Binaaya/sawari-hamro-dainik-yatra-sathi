import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';

/// Widget to display the current active/ongoing ride
class ActiveRideWidget extends StatelessWidget {
  final RideModel ride;
  final bool isDark;

  const ActiveRideWidget({
    super.key,
    required this.ride,
    required this.isDark,
  });

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _calculateDuration(DateTime? entryTime) {
    if (entryTime == null) return 'N/A';
    final duration = DateTime.now().difference(entryTime);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF065F46) : AppColors.emerald50,
            isDark ? const Color(0xFF064E3B) : AppColors.emerald100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.emerald700 : AppColors.emerald200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald500.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.emerald500.withValues(alpha: 0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Ride',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.emerald900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.routeName ?? 'Route information loading...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.emerald200 : AppColors.emerald700,
                      ),
                    ),
                  ],
                ),
              ),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.red[300] : Colors.red[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Journey details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Entry Stop
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.emerald500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald500.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Boarded at',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.gray400 : AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.entryStopName ?? 'Unknown Stop',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(ride.entryTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.emerald300 : AppColors.emerald700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dotted line
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Column(
                      children: List.generate(
                        3,
                        (index) => Container(
                          width: 2,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.gray600 : AppColors.gray300,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.emerald900.withValues(alpha: 0.3)
                              : AppColors.emerald50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Duration: ${_calculateDuration(ride.entryTime)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.emerald300 : AppColors.emerald700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Exit (Destination placeholder)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.gray500 : AppColors.gray400,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exit at',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.gray400 : AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap RFID card to exit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.gray400 : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.nfc,
                      size: 20,
                      color: isDark ? AppColors.gray500 : AppColors.gray400,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Reminder
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: isDark ? AppColors.emerald300 : AppColors.emerald600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Remember to tap your card when exiting the bus',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.emerald200 : AppColors.emerald700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
