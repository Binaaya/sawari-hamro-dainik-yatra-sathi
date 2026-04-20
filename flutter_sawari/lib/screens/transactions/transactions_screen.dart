import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiService _apiService = ApiService();

  int _selectedTab = 0; // 0 = Rides (RidePayment), 1 = Token Purchases (TopUp)
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> _rideTransactions = [];
  List<TransactionModel> _topUpTransactions = [];

  // Pagination
  int _ridePage = 1;
  int _topUpPage = 1;
  bool _hasMoreRides = true;
  bool _hasMoreTopUps = true;

  // Date filter
  bool _isFiltered = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both types in parallel
      final results = await Future.wait([
        _apiService.getTransactions(page: 1, limit: 20, type: 'RidePayment'),
        _apiService.getTransactions(page: 1, limit: 20, type: 'TopUp'),
      ]);

      final rideResponse = results[0];
      final topUpResponse = results[1];

      if (rideResponse.success && rideResponse.data != null) {
        final transactionsData = rideResponse.data!['data']?['transactions'] as List?;
        if (transactionsData != null) {
          _rideTransactions = transactionsData
              .map((t) => TransactionModel.fromJson(t))
              .toList();
          final pagination = rideResponse.data!['data']?['pagination'];
          _hasMoreRides = pagination?['hasNext'] ?? false;
        }
      }

      if (topUpResponse.success && topUpResponse.data != null) {
        final transactionsData = topUpResponse.data!['data']?['transactions'] as List?;
        if (transactionsData != null) {
          _topUpTransactions = transactionsData
              .map((t) => TransactionModel.fromJson(t))
              .toList();
          final pagination = topUpResponse.data!['data']?['pagination'];
          _hasMoreTopUps = pagination?['hasNext'] ?? false;
        }
      }

      _ridePage = 1;
      _topUpPage = 1;
    } catch (e) {
      _error = 'Couldn\u0027t load your transactions. Pull down to refresh or tap retry.';
      debugPrint('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreRides() async {
    if (!_hasMoreRides || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getTransactions(
        page: _ridePage + 1,
        limit: 20,
        type: 'RidePayment',
      );

      if (response.success && response.data != null) {
        final transactionsData = response.data!['data']?['transactions'] as List?;
        if (transactionsData != null) {
          _rideTransactions.addAll(
            transactionsData.map((t) => TransactionModel.fromJson(t)),
          );
          final pagination = response.data!['data']?['pagination'];
          _hasMoreRides = pagination?['hasNext'] ?? false;
          _ridePage++;
        }
      }
    } catch (e) {
      debugPrint('Error loading more rides: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreTopUps() async {
    if (!_hasMoreTopUps || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getTransactions(
        page: _topUpPage + 1,
        limit: 20,
        type: 'TopUp',
      );

      if (response.success && response.data != null) {
        final transactionsData = response.data!['data']?['transactions'] as List?;
        if (transactionsData != null) {
          _topUpTransactions.addAll(
            transactionsData.map((t) => TransactionModel.fromJson(t)),
          );
          final pagination = response.data!['data']?['pagination'];
          _hasMoreTopUps = pagination?['hasNext'] ?? false;
          _topUpPage++;
        }
      }
    } catch (e) {
      debugPrint('Error loading more top-ups: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<TransactionModel> _filterByDate(List<TransactionModel> items) {
    if (!_isFiltered || (_startDate == null && _endDate == null)) {
      return items;
    }
    return items.where((item) {
      final itemDate = item.transactionTime;
      if (itemDate == null) return true;
      if (_startDate != null && _endDate != null) {
        return !itemDate.isBefore(_startDate!) && !itemDate.isAfter(_endDate!.add(const Duration(days: 1)));
      } else if (_startDate != null) {
        return !itemDate.isBefore(_startDate!);
      } else if (_endDate != null) {
        return !itemDate.isAfter(_endDate!.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy-MM-dd • hh:mm a').format(dateTime);
  }

  void _showFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bgColor = isDark ? AppColors.gray800 : Colors.white;
            final textColor = isDark ? Colors.white : AppColors.gray900;
            final subtitleColor = isDark ? AppColors.gray400 : AppColors.gray600;

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Date',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                isDark ? AppColors.gray700 : AppColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color:
                                isDark ? AppColors.gray400 : AppColors.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Start Date
                  Text(
                    'Start Date',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStart ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => tempStart = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.gray600 : AppColors.gray300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? AppColors.gray700 : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 20,
                              color: isDark
                                  ? AppColors.gray500
                                  : AppColors.gray400),
                          const SizedBox(width: 12),
                          Text(
                            tempStart != null
                                ? DateFormat('yyyy-MM-dd').format(tempStart!)
                                : 'Select start date',
                            style: TextStyle(
                              fontSize: 14,
                              color: tempStart != null
                                  ? textColor
                                  : (isDark
                                      ? AppColors.gray500
                                      : AppColors.gray400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // End Date
                  Text(
                    'End Date',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEnd ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => tempEnd = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.gray600 : AppColors.gray300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? AppColors.gray700 : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 20,
                              color: isDark
                                  ? AppColors.gray500
                                  : AppColors.gray400),
                          const SizedBox(width: 12),
                          Text(
                            tempEnd != null
                                ? DateFormat('yyyy-MM-dd').format(tempEnd!)
                                : 'Select end date',
                            style: TextStyle(
                              fontSize: 14,
                              color: tempEnd != null
                                  ? textColor
                                  : (isDark
                                      ? AppColors.gray500
                                      : AppColors.gray400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                              _isFiltered = false;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.gray600
                                  : AppColors.gray300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Clear Filter',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.gray300
                                  : AppColors.gray700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _startDate = tempStart;
                              _endDate = tempEnd;
                              _isFiltered = true;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.emerald500
                                : AppColors.emerald600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Apply Filter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.gray900 : AppColors.gray50;
    final textColor = isDark ? Colors.white : AppColors.gray900;
    final subtitleColor = isDark ? AppColors.gray400 : AppColors.gray600;
    final cardBg = isDark ? AppColors.gray800 : Colors.white;
    final tabBg = isDark ? AppColors.gray800 : Colors.white;

    final filteredRides = _filterByDate(_rideTransactions);
    final filteredTopUps = _filterByDate(_topUpTransactions);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View your transaction history',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showFilterModal,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isFiltered
                            ? (isDark ? AppColors.emerald900 : AppColors.emerald50)
                            : cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isFiltered
                              ? (isDark ? AppColors.emerald500 : AppColors.emerald300)
                              : (isDark ? AppColors.gray600 : AppColors.gray300),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 16,
                            color: _isFiltered
                                ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                                : (isDark ? AppColors.gray400 : AppColors.gray600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFiltered ? 'Filtered' : 'Filter by date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isFiltered
                                  ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                                  : (isDark ? AppColors.gray300 : AppColors.gray700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Refresh button
                  GestureDetector(
                    onTap: _loadTransactions,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.gray600 : AppColors.gray300,
                        ),
                      ),
                      child: Icon(
                        Icons.refresh,
                        size: 20,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tabBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? (isDark
                                    ? AppColors.emerald500
                                    : AppColors.emerald600)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Rides',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.gray400
                                        : AppColors.gray600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? (isDark
                                    ? AppColors.emerald500
                                    : AppColors.emerald600)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Token Purchases',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.gray400
                                        : AppColors.gray600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: isDark ? Colors.orange[200] : Colors.orange[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange, size: 20),
                        onPressed: _loadTransactions,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),

            // Transaction List
            Expanded(
              child: _isLoading && (_selectedTab == 0 ? _rideTransactions.isEmpty : _topUpTransactions.isEmpty)
                  ? const Center(child: CircularProgressIndicator())
                  : (_selectedTab == 0 ? filteredRides.isEmpty : filteredTopUps.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 0 ? Icons.directions_bus_outlined : Icons.account_balance_wallet_outlined,
                                size: 48,
                                color: isDark ? AppColors.gray600 : AppColors.gray300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 0 ? 'No ride transactions' : 'No token purchases',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your transactions will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.gray500 : AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification) {
                              final metrics = notification.metrics;
                              if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                                if (_selectedTab == 0) {
                                  _loadMoreRides();
                                } else {
                                  _loadMoreTopUps();
                                }
                              }
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _selectedTab == 0
                                ? filteredRides.length + (_hasMoreRides ? 1 : 0)
                                : filteredTopUps.length + (_hasMoreTopUps ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_selectedTab == 0) {
                                if (index >= filteredRides.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final transaction = filteredRides[index];
                                return _RideTransactionCard(
                                  transaction: transaction,
                                  isDark: isDark,
                                  cardBg: cardBg,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                  formatDateTime: _formatDateTime,
                                );
                              } else {
                                if (index >= filteredTopUps.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final transaction = filteredTopUps[index];
                                return _TopUpTransactionCard(
                                  transaction: transaction,
                                  isDark: isDark,
                                  cardBg: cardBg,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                  formatDateTime: _formatDateTime,
                                );
                              }
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideTransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subtitleColor;
  final String Function(DateTime?) formatDateTime;

  const _RideTransactionCard({
    required this.transaction,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subtitleColor,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride Payment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(transaction.transactionTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${transaction.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                        Text(
                          'tokens',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.gray400
                                : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color:
                            isDark ? AppColors.gray700 : AppColors.gray100,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance after:',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                      Text(
                        '${transaction.balanceAfter.toStringAsFixed(0)} tokens',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpTransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subtitleColor;
  final String Function(DateTime?) formatDateTime;

  const _TopUpTransactionCard({
    required this.transaction,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subtitleColor,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Icons.add_circle_outline,
              color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Token Top-Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(transaction.transactionTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${transaction.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.emerald400
                                : AppColors.emerald600,
                          ),
                        ),
                        Text(
                          'tokens',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.gray400
                                : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color:
                            isDark ? AppColors.gray700 : AppColors.gray100,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment method:',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                          Text(
                            transaction.paymentMethod,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Balance after:',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                          Text(
                            '${transaction.balanceAfter.toStringAsFixed(0)} tokens',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
