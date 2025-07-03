import 'package:flutter/material.dart';
import 'dart:math';

class PieChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const PieChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Get total for percentage calculation
    final total = data.values.fold(0, (sum, value) => sum + value);

    // Generate colors for each segment
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    // Sort data by value (descending)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: CustomPaint(
            size: Size.infinite,
            painter: _SimplePieChartPainter(
              data: sortedEntries,
              colors: colors,
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  sortedEntries.length,
                  (index) {
                    final entry = sortedEntries[index];
                    final color = colors[index % colors.length];
                    final percentage = total > 0
                        ? (entry.value / total * 100).toStringAsFixed(1)
                        : '0.0';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.key} (${entry.value})',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimplePieChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> data;
  final List<Color> colors;
  final int total;

  _SimplePieChartPainter({
    required this.data,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;

    double startAngle = -pi / 2; // Start from top (12 o'clock position)

    for (int i = 0; i < data.length; i++) {
      final value = data[i].value;
      final sweepAngle = 2 * pi * value / total;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw a border
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

      // Add percentage text in the middle of each arc
      if (sweepAngle > 0.4) {
        // Only add text if the segment is large enough
        final percentage = '${(value / total * 100).toStringAsFixed(0)}%';

        // Calculate position for the text (middle of the arc)
        final textAngle = startAngle + sweepAngle / 2;
        final textRadius = radius * 0.6;
        final x = center.dx + textRadius * cos(textAngle);
        final y = center.dy + textRadius * sin(textAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: percentage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x - textPainter.width / 2,
            y - textPainter.height / 2,
          ),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
