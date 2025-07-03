import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/analytics_provider.dart';
import '../../widgets/line_chart.dart';
import '../../widgets/pie_chart.dart';

class AnalyticsCharts {
  static Widget buildChart(AnalyticsProvider provider, bool isRevenue) {
    // Convert provider data to format needed by chart widgets
    Map<String, int> chartData = {};

    // Use real provider data
    final data = isRevenue ? provider.salesData : provider.ordersData;
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    for (var item in data) {
      // Handle different key names for daily vs monthly data
      final String key;
      final dynamic value;

      if (item.containsKey('month')) {
        // Monthly data format
        key = item['month'] as String;
        value = isRevenue
            ? (item['sales'] as double).round()
            : (item['orders'] as int);
      } else if (item.containsKey('label')) {
        // Daily data format
        key = item['label'] as String;
        value = (item['amount'] as double).round();
      } else {
        // Skip invalid data
        continue;
      }

      chartData[key] = value;
    }

    // Different styling from dashboard with white background
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: LineChartWidget(data: chartData),
    );
  }

  static Widget buildUserGrowth(AnalyticsProvider provider) {
    // Fetch real user growth data from the provider
    final userData = provider.userGrowthData;
    Map<String, int> chartData = {};

    for (var item in userData) {
      chartData[item['month'] as String] = (item['count'] as int);
    }

    // Different card styling from dashboard
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'User Growth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                // Add a refresh button
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    provider.loadUserGrowthData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Different visualization - use area chart instead of line chart
            SizedBox(
              height: 300,
              child: chartData.isNotEmpty
                  ? AreaChartWidget(data: chartData)
                  : const Center(child: Text('No user growth data available')),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildCategoryDistribution(AnalyticsProvider provider) {
    // Use real data from provider
    final data = provider.categoryDistribution;
    Map<String, int> chartData = {};

    for (var item in data) {
      chartData[item['category'] as String] = (item['count'] as int);
    }

    // Different styling from dashboard
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pie_chart,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Product Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                // Add a refresh button
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    provider.loadCategoryDistribution();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chartData.isNotEmpty
                  ? PieChartWidget(data: chartData)
                  : const Center(child: Text('No category data available')),
            ),
          ],
        ),
      ),
    );
  }
}

// New area chart widget for user growth
class AreaChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const AreaChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: LineChartWidget(
            data: data,
            // We're reusing LineChartWidget but with different styling
            // In a real app, you'd create a dedicated AreaChartWidget
          ),
        );
      },
    );
  }
}
