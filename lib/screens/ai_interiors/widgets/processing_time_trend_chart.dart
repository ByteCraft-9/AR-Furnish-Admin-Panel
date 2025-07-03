import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../constants/app_constants.dart';

class ProcessingTimeTrendChart extends StatelessWidget {
  final Map<DateTime, double> processingTimeTrends;

  const ProcessingTimeTrendChart({
    super.key,
    required this.processingTimeTrends,
  });

  @override
  Widget build(BuildContext context) {
    if (processingTimeTrends.isEmpty) {
      return const Card(
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No data available for processing time trends'),
          ),
        ),
      );
    }

    final sortedEntries = processingTimeTrends.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Find min/max values
    final values = sortedEntries.map((e) => e.value).toList();
    final minValue =
        values.reduce((min, value) => min < value ? min : value) * 0.8;
    final maxValue =
        values.reduce((max, value) => max > value ? max : value) * 1.2;

    // Limit the number of data points to prevent overflow
    final maxDataPoints = 10;
    final limitedEntries = sortedEntries.length > maxDataPoints
        ? _limitDataPoints(sortedEntries, maxDataPoints)
        : sortedEntries;

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 280,
            maxWidth: constraints.maxWidth,
          ),
          child: Card(
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Processing Time Trends (seconds)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200, // Fixed height instead of AspectRatio
                    child: CustomLineChart(
                      data: limitedEntries,
                      minValue: minValue,
                      maxValue: maxValue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Helper method to limit the number of data points while maintaining trends
  List<MapEntry<DateTime, double>> _limitDataPoints(
      List<MapEntry<DateTime, double>> entries, int maxCount) {
    if (entries.length <= maxCount) return entries;

    final result = <MapEntry<DateTime, double>>[];
    final step = entries.length / maxCount;

    // Always include first and last points
    result.add(entries.first);

    // Add evenly spaced points in the middle
    for (int i = 1; i < maxCount - 1; i++) {
      final index = (i * step).round();
      if (index < entries.length) {
        result.add(entries[index]);
      }
    }

    result.add(entries.last);
    return result;
  }
}

class CustomLineChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  final double minValue;
  final double maxValue;

  const CustomLineChart({
    super.key,
    required this.data,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Calculate scale factors
        final xAxisLength = width - 60; // Leaving space for Y-axis labels
        final yAxisLength = height - 30; // Leaving space for X-axis labels

        final xScale = xAxisLength / (data.length > 1 ? data.length - 1 : 1);
        final yScale = yAxisLength / (maxValue - minValue);

        // Generate points for the line
        final points = <Offset>[];
        for (int i = 0; i < data.length; i++) {
          final x = 60 + i * xScale;
          final y = height - 30 - (data[i].value - minValue) * yScale;
          points.add(Offset(x, y));
        }

        // Calculate how many labels we can fit
        final labelFrequency = math.max(1, (data.length / 5).ceil());

        return Stack(
          children: [
            // Y-axis labels
            Positioned(
              left: 0,
              top: 0,
              bottom: 30, // Space for X-axis labels
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final value = minValue + (maxValue - minValue) / 5 * index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).reversed.toList(),
              ),
            ),

            // X-axis labels - Fixed positioning approach
            Positioned(
              left: 60,
              right: 0,
              bottom: 0,
              height: 20,
              child: Stack(
                children: [
                  for (int i = 0; i < data.length; i += labelFrequency)
                    if (i < data.length)
                      Positioned(
                        left: i * xScale - 15,
                        width: 30,
                        child: Text(
                          DateFormat('MM/dd').format(data[i].key),
                          style: const TextStyle(
                            color: AppColors.textSecondaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
              ),
            ),

            // Grid lines
            CustomPaint(
              size: Size(width, height),
              painter: GridPainter(yAxisLength: yAxisLength),
            ),

            // Line chart
            CustomPaint(
              size: Size(width, height),
              painter: LineChartPainter(
                points: points,
                lineColor: AppColors.primaryColor,
                fillColor: AppColors.primaryColor.withOpacity(0.1),
              ),
            ),

            // Data points with tooltips - only show a reasonable number
            for (int i = 0; i < data.length; i += labelFrequency)
              Positioned(
                left: 60 + i * xScale - 5,
                top: height - 30 - (data[i].value - minValue) * yScale - 5,
                width: 10,
                height: 10,
                child: Tooltip(
                  message:
                      '${DateFormat('MMM dd, yyyy').format(data[i].key)}: ${data[i].value.toStringAsFixed(2)} sec',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final double yAxisLength;

  GridPainter({required this.yAxisLength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderColor.withOpacity(0.3)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = size.height - 30 - (yAxisLength / 5 * i);
      canvas.drawLine(
        Offset(60, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final List<Offset> points;
  final Color lineColor;
  final Color fillColor;

  LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    // Draw area fill
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height - 30); // Bottom left
    fillPath.lineTo(points.first.dx, points.first.dy); // Top left

    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(points.last.dx, size.height - 30); // Bottom right
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
