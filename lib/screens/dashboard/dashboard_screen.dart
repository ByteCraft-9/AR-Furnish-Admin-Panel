// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../constants/routes.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/sidebar.dart';
import '../widgets/pie_chart.dart';
import '../widgets/line_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
// Dashboard is the first item in sidebar

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load analytics data
      Provider.of<AnalyticsProvider>(context, listen: false).loadAllData();

      // Load products data (for latest products)
      Provider.of<ProductProvider>(context, listen: false).loadProducts();

      // Load promotions data (for latest promotions)
      Provider.of<PromotionProvider>(context, listen: false).loadPromotions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    // Access providers
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final promotionProvider = Provider.of<PromotionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: 0,
            onItemSelected: (index) {
              // Handle navigation here if needed
              if (index != 0) {
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
            child: Column(
              children: [
                // App bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.notifications);
                            },
                            tooltip: 'Notifications',
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Consumer<NotificationProvider>(
                              builder: (context, notificationProvider, child) {
                                final unreadCount =
                                    notificationProvider.unreadCount;
                                if (unreadCount > 0) {
                                  return Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      unreadCount > 9
                                          ? '9+'
                                          : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics cards
                        _buildStatisticsCards(analyticsProvider, isMobile),
                        const SizedBox(height: 24),

                        // Sales chart with prominent dropdown
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 1,
                          shadowColor: Colors.black12,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Sales Overview',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildTimeRangeSelector(analyticsProvider),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildSalesChart(analyticsProvider),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Category distribution and Latest items
                        isMobile
                            ? Column(
                                children: [
                                  _buildCategoryDistributionChart(
                                      analyticsProvider, isMobile),
                                  const SizedBox(height: 24),
                                  _buildLatestProducts(productProvider),
                                  const SizedBox(height: 24),
                                  _buildLatestPromotions(promotionProvider),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildCategoryDistributionChart(
                                        analyticsProvider, isMobile),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _buildLatestProducts(productProvider),
                                        const SizedBox(height: 24),
                                        _buildLatestPromotions(
                                            promotionProvider),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),

                        // Charts
                        _buildCharts(context, userProvider, isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(AnalyticsProvider analyticsProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Time Range:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: analyticsProvider.selectedMonths,
            underline: const SizedBox(), // Remove the underline
            icon: const Icon(Icons.keyboard_arrow_down),
            items: List.generate(6, (index) {
              final months = index + 1;
              return DropdownMenuItem<int>(
                value: months,
                child: Text(
                  months == 1 && analyticsProvider.showDailyData
                      ? 'Last $months Month (Daily)'
                      : 'Last $months Month${months > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }),
            onChanged: (int? value) {
              if (value != null) {
                analyticsProvider.setSelectedMonths(value);
              }
            },
          ),
          if (analyticsProvider.selectedMonths == 1) ...[
            const SizedBox(width: 16),
            const Text(
              'Daily:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Switch(
              value: analyticsProvider.showDailyData,
              onChanged: (value) {
                analyticsProvider.setShowDailyData(value);
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(
      AnalyticsProvider analyticsProvider, bool isMobile) {
    final stats = analyticsProvider.statistics;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            stats['totalRevenue'] != null
                ? 'PKR ${(stats['totalRevenue'] as double).toStringAsFixed(0)}'
                : 'PKR 0',
            Icons.attach_money,
            const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Orders',
            stats['totalOrders']?.toString() ?? '0',
            Icons.shopping_cart_outlined,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Products',
            stats['totalProducts']?.toString() ?? '0',
            Icons.inventory_2_outlined,
            const Color(0xFFFFC107),
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Promotions',
              stats['totalPromotions']?.toString() ?? '0',
              Icons.local_offer_outlined,
              const Color(0xFFE91E63),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(AnalyticsProvider analyticsProvider) {
    final data = analyticsProvider.salesData;

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No sales data available',
          style: TextStyle(
            color: Color(0xFF757575),
          ),
        ),
      );
    }

    // Find max value for chart scale
    final maxSale = data
        .map((e) => (analyticsProvider.showDailyData &&
                analyticsProvider.selectedMonths == 1)
            ? (e['amount'] as double).toDouble()
            : (e['sales'] as double).toDouble())
        .reduce((value, element) => value > element ? value : element);

    // Dynamic scaling based on the maximum value
    final yAxisMax = _calculateYAxisMax(maxSale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main chart area
        SizedBox(
          height: 250, // Further reduced height to prevent overflow
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Y-axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(yAxisMax),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Text(
                      _formatCurrency(yAxisMax * 0.75),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Text(
                      _formatCurrency(yAxisMax * 0.5),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Text(
                      _formatCurrency(yAxisMax * 0.25),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Text(
                      _formatCurrency(0),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Chart content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Grid lines
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (index) {
                            return Container(
                              height: 1,
                              color: Colors.grey[200],
                            );
                          }),
                        ),
                        // Line chart
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LineChartPainter(
                              data: data,
                              maxY: yAxisMax,
                              color: AppColors.primaryColor,
                              isDaily: analyticsProvider.showDailyData &&
                                  analyticsProvider.selectedMonths == 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // X-axis labels (in a separate container with fixed height)
        Container(
          height: 20,
          margin: const EdgeInsets.only(top: 8, left: 40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              return Stack(
                children: List.generate(data.length, (index) {
                  // Skip some labels when there are too many
                  if (data.length > 15) {
                    if (data.length > 30) {
                      // For daily view with many points
                      if (index % 5 != 0 && index != data.length - 1) {
                        return const SizedBox.shrink();
                      }
                    } else {
                      // For weekly view
                      if (index % 3 != 0 && index != data.length - 1) {
                        return const SizedBox.shrink();
                      }
                    }
                  }

                  final label = analyticsProvider.showDailyData &&
                          analyticsProvider.selectedMonths == 1
                      ? data[index]['label']
                      : data[index]['month'];

                  // Calculate the exact position for each label
                  final xPosition =
                      index * (availableWidth / (data.length - 1)) - 30;

                  return Positioned(
                    left: xPosition,
                    child: SizedBox(
                      width: 60,
                      child: Text(
                        label as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF757575),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to calculate appropriate Y-axis maximum value based on data
  double _calculateYAxisMax(double maxValue) {
    if (maxValue <= 0) return 100; // Default for no data

    // Ensure we have some headroom above the max value (add 10%)
    final targetMax = maxValue * 1.1;

    // For smaller values, use simple rounding
    if (targetMax < 100) {
      return ((targetMax / 10).ceil()) * 10;
    }

    // For medium values
    if (targetMax < 1000) {
      return ((targetMax / 100).ceil()) * 100;
    }

    // For larger values
    if (targetMax < 10000) {
      return ((targetMax / 1000).ceil()) * 1000;
    }

    // For very large values, round to significant digits
    final magnitude =
        math.pow(10, (math.log(targetMax) / math.log(10)).floor()).toDouble();
    return ((targetMax / magnitude).ceil()) * magnitude;
  }

  // Helper method to format currency values
  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      symbol: 'PKR ',
      decimalDigits: 0,
    );

    if (value >= 1000000) {
      return 'PKR ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'PKR ${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return formatter.format(value);
    }
  }

  Widget _buildCategoryDistributionChart(
      AnalyticsProvider analyticsProvider, bool isMobile) {
    final data = analyticsProvider.categoryDistribution;

    if (data.isEmpty) {
      return const SizedBox();
    }

    // Calculate max value for chart scale
    final maxCount = data
        .map((e) => (e['count'] as int).toDouble())
        .reduce((value, element) => value > element ? value : element);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Distribution by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  // Grid lines
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      return Container(
                        height: 1,
                        color: Colors.grey[200],
                      );
                    }),
                  ),
                  // Bar chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(data.length, (index) {
                      final item = data[index];
                      final count = item['count'] as int;
                      final barHeight = (count / maxCount) * 100;

                      return Tooltip(
                        message: '${item['category']}: $count',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 30,
                              height: (barHeight * 2.2).clamp(0, 220),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(index),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['category'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF757575),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppColors.primaryColor,
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF2196F3),
    ];
    return colors[index % colors.length];
  }

  Widget _buildLatestProducts(ProductProvider productProvider) {
    final products = productProvider.products;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (productProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (products.isEmpty)
              const Center(
                child: Text(
                  'No products found',
                  style: TextStyle(
                    color: Color(0xFF757575),
                  ),
                ),
              )
            else
              Column(
                children: products
                    .take(5)
                    .map(
                      (product) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            product.featuredImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 20,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        trailing: Text(
                          'PKR ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestPromotions(PromotionProvider promotionProvider) {
    final promotions = promotionProvider.promotions;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Promotions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (promotionProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (promotions.isEmpty)
              const Center(
                child: Text(
                  'No promotions found',
                  style: TextStyle(
                    color: Color(0xFF757575),
                  ),
                ),
              )
            else
              Column(
                children: promotions
                    .take(5)
                    .map(
                      (promotion) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: promotion.imageUrls.isNotEmpty
                              ? Image.network(
                                  promotion.imageUrls[0],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[100],
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 20,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.local_offer_outlined,
                                    size: 20,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                        ),
                        title: Text(
                          promotion.promotionName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          promotion.duration,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${promotion.discount.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(
      BuildContext context, UserProvider userProvider, bool isMobile) {
    return Column(
      children: [
        // Charts header
        Row(
          children: [
            const Text(
              'Analytics Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: 'This Month',
              underline: const SizedBox(),
              items: [
                'This Week',
                'This Month',
                'This Quarter',
                'This Year',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Charts
        if (isMobile)
          Column(
            children: [
              _buildChartCard(
                context,
                title: 'User Registrations',
                chart: SizedBox(
                  height: 300,
                  child: userProvider.userRegistrationsByMonth.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : LineChartWidget(
                          data: userProvider.userRegistrationsByMonth),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                context,
                title: 'User Distribution by Role',
                chart: SizedBox(
                  height: 300,
                  child: userProvider.userRoleDistribution.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : PieChartWidget(data: userProvider.userRoleDistribution),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildChartCard(
                  context,
                  title: 'User Registrations',
                  chart: SizedBox(
                    height: 300,
                    child: userProvider.userRegistrationsByMonth.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : LineChartWidget(
                            data: userProvider.userRegistrationsByMonth),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  context,
                  title: 'User Distribution by Role',
                  chart: SizedBox(
                    height: 300,
                    child: userProvider.userRoleDistribution.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : PieChartWidget(
                            data: userProvider.userRoleDistribution),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required Widget chart,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }
}

// Custom painter for line chart
class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxY;
  final Color color;
  final bool isDaily;

  _LineChartPainter({
    required this.data,
    required this.maxY,
    required this.color,
    required this.isDaily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height -
          (size.height *
              (isDaily
                  ? (data[i]['amount'] as double)
                  : (data[i]['sales'] as double)) /
              maxY);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Create a smooth curve
        if (i < data.length - 1) {
          final x1 = x;
          final y1 = y;
          final x2 = size.width * (i + 1) / (data.length - 1);
          final y2 = size.height -
              (size.height *
                  (isDaily
                      ? (data[i + 1]['amount'] as double)
                      : (data[i + 1]['sales'] as double)) /
                  maxY);

          final xc = (x1 + x2) / 2;
          final yc = (y1 + y2) / 2;

          path.quadraticBezierTo(x1, y1, xc, yc);
          fillPath.quadraticBezierTo(x1, y1, xc, yc);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
    }

    // Complete the fill path
    final lastX = size.width * (data.length - 1) / (data.length - 1);
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    // Draw the fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height -
          (size.height *
              (isDaily
                  ? (data[i]['amount'] as double)
                  : (data[i]['sales'] as double)) /
              maxY);

      // Draw fewer points if there are too many data points
      if (data.length <= 10 || i % 3 == 0 || i == data.length - 1) {
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
        canvas.drawCircle(Offset(x, y), 4, pointStrokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxY != maxY ||
        oldDelegate.color != color ||
        oldDelegate.isDaily != isDaily;
  }
}
