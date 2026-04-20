import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'operator_dashboard_screen.dart';
import 'operator_vehicles_screen.dart';
import 'operator_drivers_screen.dart';
import 'operator_routes_screen.dart';
import 'operator_profile_screen.dart';

class OperatorApp extends StatefulWidget {
  final VoidCallback onLogout;

  const OperatorApp({super.key, required this.onLogout});

  @override
  State<OperatorApp> createState() => _OperatorAppState();
}

class _OperatorAppState extends State<OperatorApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      OperatorDashboardScreen(onSwitchTab: (i) => setState(() => _currentIndex = i)),
      const OperatorVehiclesScreen(),
      const OperatorDriversScreen(),
      const OperatorRoutesScreen(),
      OperatorProfileScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.operatorLight, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.operatorPrimary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.directions_bus_outlined,
                  activeIcon: Icons.directions_bus,
                  label: 'Vehicles',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.badge_outlined,
                  activeIcon: Icons.badge,
                  label: 'Drivers',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.route_outlined,
                  activeIcon: Icons.route,
                  label: 'Routes',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.operatorLight,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.operatorPrimary : Colors.grey[500],
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.operatorPrimary : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
