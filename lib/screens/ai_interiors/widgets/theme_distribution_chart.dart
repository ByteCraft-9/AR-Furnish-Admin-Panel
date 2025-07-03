import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../constants/app_constants.dart';

class ThemeDistributionChart extends StatelessWidget {
  final Map<String, int> themeDistribution;

  const ThemeDistributionChart({
    super.key,
    required this.themeDistribution,
  });

  @override
  Widget build(BuildContext context) {
    if (themeDistribution.isEmpty) {
      return const Card(
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No data available for theme distribution'),
          ),
        ),
      );
    }

    // Prepare data
    final data = themeDistribution.entries.map((entry) {
      return ThemeCount(entry.key, entry.value);
    }).toList();

    // Calculate total count for percentages
    final totalCount = data.fold(0, (sum, item) => sum + item.count);

    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theme Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  children: [
                    // Pie chart
                    Expanded(
                      flex: 2,
                      child: CustomPaint(
                        painter: PieChartPainter(
                          data: data,
                          totalCount: totalCount,
                        ),
                        child: Container(),
                      ),
                    ),

                    // Legend
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(data.length, (index) {
                              final item = data[index];
                              final color = getChartColor(index);
                              final percentage = totalCount > 0
                                  ? ((item.count / totalCount) * 100)
                                      .toStringAsFixed(1)
                                  : '0.0';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.theme,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.count} (${percentage}%)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getChartColor(int index) {
    final colors = [
      AppColors.primaryColor,
      AppColors.secondaryColor,
      AppColors.successColor,
      AppColors.warningColor,
      AppColors.errorColor,
      AppColors.infoColor,
    ];

    return colors[index % colors.length];
  }
}

class ThemeCount {
  final String theme;
  final int count;

  ThemeCount(this.theme, this.count);
}

class PieChartPainter extends CustomPainter {
  final List<ThemeCount> data;
  final int totalCount;

  PieChartPainter({
    required this.data,
    required this.totalCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || totalCount == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;

    double startAngle = -math.pi / 2; // Start from top (12 o'clock)

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = 2 * math.pi * data[i].count / totalCount;

      final paint = Paint()
        ..color = _getColor(i)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Add border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  Color _getColor(int index) {
    final colors = [
      AppColors.primaryColor,
      AppColors.secondaryColor,
      AppColors.successColor,
      AppColors.warningColor,
      AppColors.errorColor,
      AppColors.infoColor,
    ];

    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
