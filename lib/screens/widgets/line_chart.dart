import 'package:flutter/material.dart';
import 'dart:math';

class LineChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const LineChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Sort data by date
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Find max value for scaling
    final maxValue =
        data.values.fold(0, (max, value) => value > max ? value : max);

    // If few data points, show a bar chart instead
    if (sortedEntries.length < 3) {
      return _buildBarChart(sortedEntries, maxValue);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: max(sortedEntries.length * 60.0,
            MediaQuery.of(context).size.width - 40),
        padding:
            const EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _SimpleLineChartPainter(
                  data: sortedEntries,
                  maxValue: maxValue,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < sortedEntries.length; i++)
                  SizedBox(
                    width: 60,
                    child: Text(
                      sortedEntries[i].key,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<String, int>> data, int maxValue) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((entry) {
          final percentage = maxValue > 0 ? entry.value / maxValue : 0;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Container(
                  height: (200 * percentage).toDouble(),
                  width: 30,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> data;
  final int maxValue;

  _SimpleLineChartPainter({
    required this.data,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;
    const bottomPadding = 10.0;
    final chartHeight = height - bottomPadding;

    // Calculate segment width based on available space
    final segmentWidth = width / (data.length - 1 > 0 ? data.length - 1 : 1);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (1 - i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        gridPaint,
      );

      // Draw y-axis labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: ((maxValue * i / 4).round()).toString(),
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(-textPainter.width - 5, y - textPainter.height / 2));
    }

    // Draw the line connecting points
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final value = data[i].value;
      final x = i * segmentWidth;
      final y = chartHeight - (value / maxValue * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Draw points and values
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final value = data[i].value;
      final x = i * segmentWidth;
      final y = chartHeight - (value / maxValue * chartHeight);

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, pointPaint);

      // Draw value above point
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toString(),
          style: const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height - 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
