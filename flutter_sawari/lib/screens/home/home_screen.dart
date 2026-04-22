import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_state.dart';
import '../notifications/notifications_screen.dart';
import 'buy_tokens_modal.dart';
import 'active_ride_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    // Load recent rides and active ride when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.isAuthenticated) {
        appState.loadRecentRides();
        appState.loadActiveRide();
        _loadUnreadCount();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    final response = await Provider.of<AppState>(context, listen: false)
        .apiService
        .getNotifications(page: 1, limit: 1);
    if (response.success && response.data != null && mounted) {
      setState(() {
        _unreadNotifications = response.data!['data']?['unread'] ?? 0;
      });
    }
  }

  void _showBuyTokensModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BuyTokensModal(),
    );
  }

  Future<void> _handleRefresh() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await Future.wait([
      appState.refreshBalance(),
      appState.loadRecentRides(),
      appState.loadActiveRide(),
      _loadUnreadCount(),
    ]);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy-MM-dd • hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? AppColors.gray900 : AppColors.gray50;
        final textColor = isDark ? Colors.white : AppColors.gray900;
        final subtitleColor = isDark ? AppColors.gray400 : AppColors.gray600;
        final cardBg = isDark ? AppColors.gray800 : Colors.white;
        final rideItemBg = isDark ? AppColors.gray700 : AppColors.gray50;

        final balance = appState.balance.toInt();
        final recentRides = appState.recentRides;
        final isLoading = appState.ridesLoading;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.emerald500,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Header with Logo and Notification Bell
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.emerald500, Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald500.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sawari',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const Text(
                                'Hamro dainik yatra sathi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.emerald600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification Bell
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                            _loadUnreadCount();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.gray800 : AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  size: 24,
                                  color: isDark ? AppColors.gray300 : AppColors.gray600,
                                ),
                                if (_unreadNotifications > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark ? AppColors.gray800 : AppColors.gray100,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Manage your bus tokens',
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                    const SizedBox(height: 16),

                    // Token Balance Card - gradient from emerald to blue
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.emerald500, Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald500.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Token Balance',
                            style: TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$balance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tokens',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _showBuyTokensModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.emerald600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Buy Tokens',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Ride Widget (if user has an ongoing ride)
                    if (appState.hasActiveRide && appState.activeRide != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ActiveRideWidget(
                          ride: appState.activeRide!,
                          isDark: isDark,
                        ),
                      ),

                    // Recent Rides Card
                    Container(
                      padding: const EdgeInsets.all(16),
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Rides',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? AppColors.emerald500
                                            : AppColors.emerald600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: isDark
                                          ? AppColors.emerald500
                                          : AppColors.emerald600,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Show loading indicator or rides
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (recentRides.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.directions_bus_outlined,
                                      size: 48,
                                      color: isDark ? AppColors.gray600 : AppColors.gray300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No recent rides',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your ride history will appear here',
                                      style: TextStyle(
                                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...recentRides.take(4).map((ride) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _RideItem(
                                    route: ride.routeName ?? '${ride.entryStopName ?? "?"} - ${ride.exitStopName ?? "?"}',
                                    dateTime: _formatDateTime(ride.entryTime),
                                    tokens: ride.fare?.toInt() ?? 0,
                                    bgColor: rideItemBg,
                                    textColor: textColor,
                                    isDark: isDark,
                                  ),
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RideItem extends StatelessWidget {
  final String route;
  final String dateTime;
  final int tokens;
  final Color bgColor;
  final Color textColor;
  final bool isDark;

  const _RideItem({
    required this.route,
    required this.dateTime,
    required this.tokens,
    required this.bgColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.emerald900.withValues(alpha: 0.3)
                  : AppColors.emerald100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_bus,
              color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.gray400 : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-$tokens',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                ),
              ),
              Text(
                'tokens',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.gray400 : AppColors.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
