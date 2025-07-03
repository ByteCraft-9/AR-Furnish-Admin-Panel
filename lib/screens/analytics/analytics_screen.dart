// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/sidebar.dart';
// Import the extracted widgets
import 'widgets/analytics_charts.dart';
import 'widgets/analytics_metrics.dart';
import 'widgets/analytics_export.dart'; // Import the new export widget

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isRevenue = true;
  bool _isMonthly = true;
  int _timeRangeMonths = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analyticsProvider =
          Provider.of<AnalyticsProvider>(context, listen: false);
      analyticsProvider.loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    // Access providers
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: 6, // Analytics is index 6 in the sidebar
            onItemSelected: (index) {
              // Handle navigation here
              if (index != 6) {
                // Navigate to other screens based on index
                final routes = [
                  '/', // Dashboard
                  '/products',
                  '/categories',
                  '/orders',
                  '/users',
                  '/managers',
                  '/analytics',
                  '/ai-interiors',
                  '/settings',
                  '/promotions',
                ];
                if (index < routes.length) {
                  Navigator.pushReplacementNamed(context, routes[index]);
                }
              }
            },
          ),

          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF1F5F9), // Light blue-gray background
              child: Column(
                children: [
                  // App bar
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: AppColors
                          .primaryColor, // Use primary color from constants
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Export report button
                        ElevatedButton.icon(
                          onPressed: () {
                            AnalyticsExport.showExportOptions(context);
                          },
                          icon: const Icon(Icons.file_download,
                              color: Colors.white),
                          label: const Text('Export Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColorLight,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content area
                  Expanded(
                    child: analyticsProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors
                                  .primaryColor, // Use primary color for loading indicator
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title with refresh button
                                Row(
                                  children: [
                                    const Text(
                                      'Business Performance Overview',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        analyticsProvider.loadAllData();
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Refresh Data'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryColor,
                                        side: const BorderSide(
                                            color: AppColors.primaryColor),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Statistics cards
                                _buildStatisticsCards(
                                    analyticsProvider, isMobile),
                                const SizedBox(height: 24),

                                // Insights section
                                _buildInsightsSection(
                                    analyticsProvider, isMobile),
                                const SizedBox(height: 24),

                                // Data visualization section title
                                const Text(
                                  'Data Visualization',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Category distribution and User growth
                                isMobile
                                    ? Column(
                                        children: [
                                          _buildCategoryDistribution(
                                              analyticsProvider),
                                          const SizedBox(height: 24),
                                          _buildUserGrowth(analyticsProvider),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _buildCategoryDistribution(
                                                analyticsProvider),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: _buildUserGrowth(
                                                analyticsProvider),
                                          ),
                                        ],
                                      ),

                                const SizedBox(height: 24),

                                // Performance metrics title
                                const Text(
                                  'Key Performance Indicators',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Performance metrics
                                _buildPerformanceMetrics(analyticsProvider),

                                const SizedBox(height: 40),
                              ],
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

  Widget _buildInsightsSection(AnalyticsProvider provider, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tabs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Revenue & Orders Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Toggle revenue/orders view
                ToggleButtons(
                  isSelected: [_isRevenue, !_isRevenue],
                  onPressed: (index) {
                    setState(() {
                      _isRevenue = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: AppColors.primaryColorLight,
                  color: Colors.white70,
                  constraints: const BoxConstraints(
                    minWidth: 100,
                    minHeight: 40,
                  ),
                  borderColor: Colors.white30,
                  selectedBorderColor: Colors.white,
                  children: const [
                    Text('Revenue'),
                    Text('Orders'),
                  ],
                ),
              ],
            ),
          ),
          // Controls and chart area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time frame selector
                Row(
                  children: [
                    const Text(
                      'Time Frame:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Monthly/Daily toggle
                    ToggleButtons(
                      isSelected: [_isMonthly, !_isMonthly],
                      onPressed: (index) {
                        setState(() {
                          _isMonthly = index == 0;
                          // Update provider with showDailyData value
                          Provider.of<AnalyticsProvider>(context, listen: false)
                              .setShowDailyData(!_isMonthly);
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: AppColors.primaryColor,
                      color: const Color(0xFF64748B),
                      constraints: const BoxConstraints(
                        minWidth: 80,
                        minHeight: 36,
                      ),
                      children: const [
                        Text('Monthly'),
                        Text('Daily'),
                      ],
                    ),
                    const Spacer(),
                    // Time range dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<int>(
                        value: _timeRangeMonths,
                        underline: Container(),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF64748B)),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _timeRangeMonths = value;
                            });

                            // Update provider with new time range
                            Provider.of<AnalyticsProvider>(context,
                                    listen: false)
                                .setSelectedMonths(value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Last 1 month'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('Last 3 months'),
                          ),
                          DropdownMenuItem(
                            value: 6,
                            child: Text('Last 6 months'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats summary
                isMobile
                    ? Column(
                        children: _buildStatsSummary(_isRevenue),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _buildStatsSummary(_isRevenue),
                      ),

                const SizedBox(height: 24),

                // Chart
                SizedBox(
                  height: 350,
                  child: _buildChart(provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatsSummary(bool isRevenue) {
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);

    // Get real data from analytics provider
    final totalRevenue =
        analyticsProvider.statistics['totalRevenue'] as double? ?? 0.0;
    final totalOrders =
        analyticsProvider.statistics['totalOrders'] as int? ?? 0;

    // Get monthly data
    final revenueData = analyticsProvider.monthlySalesData;
    final ordersData = analyticsProvider.ordersData;

    // Calculate real metrics
    double avgRevenue = 0.0;
    String highestRevenueMonth = '';
    double highestRevenueAmount = 0.0;

    int avgOrders = 0;
    String highestOrdersMonth = '';
    int highestOrdersCount = 0;

    // Process revenue data
    if (revenueData.isNotEmpty) {
      // Calculate average revenue
      double totalRevenueSum = 0;
      for (var item in revenueData) {
        final amount = item['sales'] as double? ?? 0.0;
        totalRevenueSum += amount;

        // Track highest month
        if (amount > highestRevenueAmount) {
          highestRevenueAmount = amount;
          highestRevenueMonth = item['month'] as String? ?? '';
        }
      }
      avgRevenue = totalRevenueSum / revenueData.length;
    }

    // Process orders data
    if (ordersData.isNotEmpty) {
      // Calculate average orders
      int totalOrdersSum = 0;
      for (var item in ordersData) {
        final count = item['orders'] as int? ?? 0;
        totalOrdersSum += count;

        // Track highest month
        if (count > highestOrdersCount) {
          highestOrdersCount = count;
          highestOrdersMonth = item['month'] as String? ?? '';
        }
      }
      avgOrders = totalOrdersSum ~/ ordersData.length;
    }

    // Create formatted values
    final formatCurrency = NumberFormat.currency(
        locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);
    final formatCompact = NumberFormat.compact(locale: 'en');

    // Format revenue metrics
    final formattedTotalRevenue = formatCurrency.format(totalRevenue);
    final formattedAvgRevenue = formatCurrency.format(avgRevenue);
    final formattedHighestRevenue = formatCurrency.format(highestRevenueAmount);

    // Calculate growth percentages (example comparison to previous period)
    // In a real implementation, you would compare to actual previous period data
    const revenueGrowth = '+12.5%'; // This would be calculated from real data
    const avgRevenueGrowth = '+8.2%'; // This would be calculated from real data

    // Create metric data
    final metrics = isRevenue
        ? [
            {
              'label': 'Total Revenue',
              'value': formattedTotalRevenue,
              'change': revenueGrowth,
              'isPositive': true
            },
            {
              'label': 'Average Monthly Revenue',
              'value': formattedAvgRevenue,
              'change': avgRevenueGrowth,
              'isPositive': true
            },
            {
              'label': 'Highest Month',
              'value': highestRevenueMonth,
              'change': formattedHighestRevenue,
              'isPositive': true
            },
          ]
        : [
            {
              'label': 'Total Orders',
              'value': formatCompact.format(totalOrders),
              'change': '+18.3%', // This would be calculated from real data
              'isPositive': true
            },
            {
              'label': 'Average Monthly Orders',
              'value': '$avgOrders',
              'change': '+5.1%', // This would be calculated from real data
              'isPositive': true
            },
            {
              'label': 'Highest Month',
              'value': highestOrdersMonth,
              'change': '$highestOrdersCount orders',
              'isPositive': true
            },
          ];

    return metrics.map((metric) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric['label'] as String,
              style: const TextStyle(
                color: AppColors.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              metric['value'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  (metric['isPositive'] as bool)
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 14,
                  color: (metric['isPositive'] as bool)
                      ? AppColors.successColor
                      : AppColors.errorColor,
                ),
                const SizedBox(width: 4),
                Text(
                  metric['change'] as String,
                  style: TextStyle(
                    color: (metric['isPositive'] as bool)
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatisticsCards(AnalyticsProvider provider, bool isMobile) {
    final stats = provider.statistics;
    final formatter = NumberFormat.compact();

    // Refresh data when loading completes
    if (provider.isLoading == false && provider.errorMessage == null) {
      // Data is loaded and there are no errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // This forces a redraw with the latest data
        if (mounted) setState(() {});
      });
    }

    final cards = [
      _buildStatCard(
        'Total Products',
        '${stats['totalProducts'] ?? 0}',
        Icons.shopping_bag,
        AppColors.primaryColor,
        AppColors.primaryColor.withOpacity(0.1),
      ),
      _buildStatCard(
        'Total Orders',
        '${stats['totalOrders'] ?? 0}',
        Icons.shopping_cart,
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
      ),
      _buildStatCard(
        'Total Users',
        '${stats['totalUsers'] ?? 0}',
        Icons.people,
        const Color(0xFFF59E0B),
        const Color(0xFFFFFBEB),
      ),
      _buildStatCard(
        'Revenue',
        'PKR ${formatter.format(stats['totalRevenue'] ?? 0)}',
        Icons.attach_money,
        const Color(0xFF8B5CF6),
        const Color(0xFFF5F3FF),
      ),
    ];

    return isMobile
        ? Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  ),
                )
                .toList(),
          )
        : Row(
            children: cards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: card,
                    ),
                  ),
                )
                .toList()
              ..removeLast()
              ..add(
                Expanded(child: cards.last),
              ),
          );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: AppColors.successColor,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '4.5%',
                      style: TextStyle(
                        color: AppColors.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(AnalyticsProvider provider) {
    return AnalyticsCharts.buildChart(provider, _isRevenue);
  }

  Widget _buildUserGrowth(AnalyticsProvider provider) {
    return AnalyticsCharts.buildUserGrowth(provider);
  }

  Widget _buildCategoryDistribution(AnalyticsProvider provider) {
    return AnalyticsCharts.buildCategoryDistribution(provider);
  }

  Widget _buildPerformanceMetrics(AnalyticsProvider provider) {
    return AnalyticsMetrics.buildMetricsTable(provider);
  }
}
