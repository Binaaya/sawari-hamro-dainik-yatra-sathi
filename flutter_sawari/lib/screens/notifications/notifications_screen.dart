import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }

    final response = await _apiService.getNotifications(
      page: _currentPage,
      limit: 20,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'];
      final list = (data['notifications'] as List?)
              ?.map((n) => Map<String, dynamic>.from(n))
              .toList() ??
          [];

      setState(() {
        if (refresh || _currentPage == 1) {
          _notifications = list;
        } else {
          _notifications.addAll(list);
        }
        _unreadCount = data['unread'] ?? 0;
        _totalPages = data['pagination']?['pages'] ?? 1;
        _isLoading = false;
        _loadingMore = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _totalPages) return;
    setState(() => _loadingMore = true);
    _currentPage++;
    await _loadNotifications();
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    if (_notifications[index]['isread'] == true) return;

    final response = await _apiService.markNotificationRead(notificationId);
    if (response.success) {
      setState(() {
        _notifications[index]['isread'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      });
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications
        .where((n) => n['isread'] != true)
        .toList();

    for (final n in unread) {
      await _apiService.markNotificationRead(n['notificationid']);
    }

    setState(() {
      for (var n in _notifications) {
        n['isread'] = true;
      }
      _unreadCount = 0;
    });
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'complaint':
        return Icons.report_outlined;
      case 'payment':
      case 'topup':
        return Icons.account_balance_wallet_outlined;
      case 'ride':
        return Icons.directions_bus_outlined;
      case 'approval':
        return Icons.check_circle_outline;
      case 'account':
        return Icons.person_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor(String? type, bool isDark) {
    switch (type) {
      case 'complaint':
        return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
      case 'payment':
      case 'topup':
        return isDark ? AppColors.emerald400 : AppColors.emerald600;
      case 'approval':
        return isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
      default:
        return isDark ? AppColors.gray400 : AppColors.gray600;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.gray900 : AppColors.gray50;
    final cardBg = isDark ? AppColors.gray800 : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.gray900;
    final subtitleColor = isDark ? AppColors.gray400 : AppColors.gray600;
    final unreadBg = isDark
        ? AppColors.emerald900.withValues(alpha: 0.2)
        : const Color(0xFFF0FDF4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.emerald500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald500))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: isDark ? AppColors.gray600 : AppColors.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see updates about your rides,\npayments, and account here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.gray500 : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(refresh: true),
                  color: AppColors.emerald500,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification) {
                        final metrics = notification.metrics;
                        if (metrics.pixels >= metrics.maxScrollExtent - 100) {
                          _loadMore();
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notifications.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.emerald500,
                                ),
                              ),
                            ),
                          );
                        }

                        final notif = _notifications[index];
                        final isRead = notif['isread'] == true;
                        final type = notif['type'] as String?;

                        return GestureDetector(
                          onTap: () => _markAsRead(
                            notif['notificationid'],
                            index,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead ? cardBg : unreadBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead
                                    ? (isDark ? AppColors.gray700 : AppColors.gray100)
                                    : (isDark
                                        ? AppColors.emerald800
                                        : AppColors.emerald100),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(type, isDark)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getTypeIcon(type),
                                    size: 20,
                                    color: _getTypeColor(type, isDark),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif['title'] ?? 'Notification',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.emerald500,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['message'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: subtitleColor,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatTime(notif['createdat']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.gray500
                                              : AppColors.gray400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}
