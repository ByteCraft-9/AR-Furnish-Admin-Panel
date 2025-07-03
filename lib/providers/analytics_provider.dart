import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  int _totalProducts = 0;
  int _totalPromotions = 0;
  int _totalOrders = 0;
  int _totalUsers = 0;
  List<Map<String, dynamic>> _monthlySalesData = [];
  List<Map<String, dynamic>> _dailySalesData = [];
  List<Map<String, dynamic>> _monthlyOrdersData = [];
  List<Map<String, dynamic>> _userGrowthData = [];
  List<Map<String, dynamic>> _categoryDistribution = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Time range selection properties
  int _selectedMonths = 3;
  bool _showDailyData = false;

  // Computed statistics for dashboard
  Map<String, dynamic> _statistics = {};

  // Performance metrics
  double _totalRevenue = 0;
  double _revenueChange = 0;
  double _ordersChange = 0;
  double _averageOrderValue = 0;
  double _aovChange = 0;
  double _conversionRate = 0;
  double _conversionChange = 0;
  double _customerRetention = 0;
  double _retentionChange = 0;

  // Getters
  int get totalProducts => _totalProducts;
  int get totalPromotions => _totalPromotions;
  int get totalOrders => _totalOrders;
  int get totalUsers => _totalUsers;
  List<Map<String, dynamic>> get monthlySalesData => _monthlySalesData;
  List<Map<String, dynamic>> get categoryDistribution => _categoryDistribution;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Performance metrics getters
  double get totalRevenue => _totalRevenue;
  double get revenueChange => _revenueChange;
  double get ordersChange => _ordersChange;
  double get averageOrderValue => _averageOrderValue;
  double get aovChange => _aovChange;
  double get conversionRate => _conversionRate;
  double get conversionChange => _conversionChange;
  double get customerRetention => _customerRetention;
  double get retentionChange => _retentionChange;

  // New getters for orders and user growth
  List<Map<String, dynamic>> get ordersData => _monthlyOrdersData;
  List<Map<String, dynamic>> get userGrowthData => _userGrowthData;

  // Time range getters
  int get selectedMonths => _selectedMonths;
  bool get showDailyData => _showDailyData;

  // Computed sales data based on time range
  List<Map<String, dynamic>> get salesData {
    if (_selectedMonths == 1 && _showDailyData) {
      return _dailySalesData;
    } else {
      // Return the last N months of data
      return _monthlySalesData.length <= _selectedMonths
          ? _monthlySalesData
          : _monthlySalesData
              .sublist(_monthlySalesData.length - _selectedMonths);
    }
  }

  // Statistics getter
  Map<String, dynamic> get statistics => _statistics;

  // Load all analytics data
  Future<void> loadAllData() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadTotalProducts(),
        loadTotalPromotions(),
        loadTotalOrders(),
        loadTotalUsers(),
        loadMonthlySalesData(),
        loadCategoryDistribution(),
        loadMonthlyOrdersData(),
        loadUserGrowthData(),
      ]);

      // Also load daily data if showing daily view
      if (_selectedMonths == 1 && _showDailyData) {
        await loadDailySalesData();
      }

      // Update statistics map for the dashboard
      _updateStatistics();
      _updatePerformanceMetrics();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load analytics data: $e');
      _setLoading(false);
    }
  }

  // Load total products count
  Future<void> loadTotalProducts() async {
    try {
      _totalProducts = await _analyticsService.getTotalProductsCount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load products count: $e');
    }
  }

  // Load total promotions count
  Future<void> loadTotalPromotions() async {
    try {
      _totalPromotions = await _analyticsService.getTotalPromotionsCount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load promotions count: $e');
    }
  }

  // Load total orders count
  Future<void> loadTotalOrders() async {
    try {
      _totalOrders = await _analyticsService.getTotalOrdersCount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load orders count: $e');
    }
  }

  // Load total users count
  Future<void> loadTotalUsers() async {
    try {
      _totalUsers = await _analyticsService.getTotalUsersCount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load users count: $e');
    }
  }

  // Load monthly sales data
  Future<void> loadMonthlySalesData() async {
    try {
      final data = await _analyticsService.getMonthlySalesData();
      _monthlySalesData = data;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load monthly sales data: $e');
    }
  }

  // Load monthly orders data
  Future<void> loadMonthlyOrdersData() async {
    try {
      final data = await _analyticsService.getMonthlyOrdersData();
      _monthlyOrdersData = data;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load monthly orders data: $e');
    }
  }

  // Load user growth data
  Future<void> loadUserGrowthData() async {
    try {
      final data = await _analyticsService.getUserGrowthData();
      _userGrowthData = data;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user growth data: $e');
    }
  }

  // Load daily sales data for the selected month
  Future<void> loadDailySalesData() async {
    try {
      // Use 0 for current month, or appropriate value for previous months
      int monthsAgo = 0;

      if (_selectedMonths > 1) {
        // If user selected more than 1 month ago, use that value
        monthsAgo = _selectedMonths - 1;
      }

      _dailySalesData = await _analyticsService.getDailySalesData(monthsAgo);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load daily sales data: $e');
    }
  }

  // Load category distribution data
  Future<void> loadCategoryDistribution() async {
    try {
      _categoryDistribution =
          await _analyticsService.getProductDistributionByCategory();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load category distribution data: $e');
    }
  }

  // Time range selection methods
  void setSelectedMonths(int months) {
    if (months >= 1 && months <= 6) {
      _selectedMonths = months;

      // If switching to 1 month and showing daily data, fetch daily data
      if (months == 1 && _showDailyData) {
        loadDailySalesData();
      }

      notifyListeners();
    }
  }

  void setShowDailyData(bool value) {
    _showDailyData = value;

    // If enabling daily data for 1 month view, fetch daily data
    if (value && _selectedMonths == 1) {
      loadDailySalesData();
    }

    notifyListeners();
  }

  // Update the statistics map for the dashboard
  void _updateStatistics() {
    double totalRevenue = 0;

    // Calculate total revenue from monthly sales data
    for (var item in _monthlySalesData) {
      totalRevenue += item['sales'] as double;
    }

    _statistics = {
      'totalProducts': _totalProducts,
      'totalPromotions': _totalPromotions,
      'totalOrders': _totalOrders,
      'totalUsers': _totalUsers,
      'totalRevenue': totalRevenue,
    };
  }

  // Update performance metrics
  void _updatePerformanceMetrics() {
    // Calculate total revenue and change
    double previousRevenue = 0;
    _totalRevenue = 0;

    for (var item in _monthlySalesData) {
      _totalRevenue += item['sales'] as double;
    }

    // Calculate revenue change (example: compare with previous period)
    if (_monthlySalesData.length >= 2) {
      previousRevenue =
          _monthlySalesData[_monthlySalesData.length - 2]['sales'] as double;
      _revenueChange =
          ((_totalRevenue - previousRevenue) / previousRevenue) * 100;
    }

    // Calculate orders change
    if (_monthlyOrdersData.length >= 2) {
      final currentMonthOrders = _monthlyOrdersData.last['orders'] as int;
      final previousMonthOrders =
          _monthlyOrdersData[_monthlyOrdersData.length - 2]['orders'] as int;

      if (previousMonthOrders > 0) {
        _ordersChange =
            ((currentMonthOrders - previousMonthOrders) / previousMonthOrders) *
                100;
      }
    }

    // Calculate average order value and change
    if (_totalOrders > 0) {
      _averageOrderValue = _totalRevenue / _totalOrders;
      // Example AOV change calculation
      _aovChange = 5.2; // This would be calculated from real data
    }

    // Example conversion rate and change
    _conversionRate = 5.8; // This would be calculated from real data
    _conversionChange = 0.5; // This would be calculated from real data

    // Example customer retention and change
    _customerRetention = 85.0; // This would be calculated from real data
    _retentionChange = 2.5; // This would be calculated from real data

    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
