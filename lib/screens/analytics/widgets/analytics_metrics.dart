import 'package:flutter/material.dart';
import '../../../providers/analytics_provider.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';

class AnalyticsMetrics {
  static Widget buildMetricsTable(AnalyticsProvider provider) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 16,
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.primaryColor.withOpacity(0.1),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Metric',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Value',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Change',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: [
                          _buildMetricRow(
                            'Total Revenue',
                            provider.totalRevenue,
                            provider.revenueChange,
                            isCurrency: true,
                          ),
                          _buildMetricRow(
                            'Total Orders',
                            provider.totalOrders,
                            provider.ordersChange,
                          ),
                          _buildMetricRow(
                            'Average Order Value',
                            provider.averageOrderValue,
                            provider.aovChange,
                            isCurrency: true,
                          ),
                          _buildMetricRow(
                            'Conversion Rate',
                            provider.conversionRate,
                            provider.conversionChange,
                            isPercentage: true,
                          ),
                          _buildMetricRow(
                            'Customer Retention',
                            provider.customerRetention,
                            provider.retentionChange,
                            isPercentage: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static DataRow _buildMetricRow(
    String label,
    dynamic value,
    double change, {
    bool isCurrency = false,
    bool isPercentage = false,
  }) {
    final formatter = NumberFormat.currency(
      symbol: 'PKR ',
      decimalDigits: 0,
    );

    String formattedValue = value.toString();
    if (isCurrency) {
      formattedValue = formatter.format(value);
    } else if (isPercentage) {
      formattedValue = '${value.toStringAsFixed(1)}%';
    }

    return DataRow(
      cells: [
        DataCell(Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        )),
        DataCell(Text(
          formattedValue,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color:
                    change >= 0 ? AppColors.successColor : AppColors.errorColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${change.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: change >= 0
                      ? AppColors.successColor
                      : AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
