import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

class ThemeProcessingTimeChart extends StatelessWidget {
  final Map<String, double> themeProcessingTimes;

  const ThemeProcessingTimeChart({
    super.key,
    required this.themeProcessingTimes,
  });

  @override
  Widget build(BuildContext context) {
    if (themeProcessingTimes.isEmpty) {
      return const Card(
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No data available'),
          ),
        ),
      );
    }

    final sortedEntries = themeProcessingTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Calculate the maximum value for scaling
    final maxValue =
        sortedEntries.isNotEmpty ? sortedEntries.last.value * 1.2 : 10.0;

    return AspectRatio(
      aspectRatio: 1.8,
      child: Card(
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Average Processing Time by Theme (seconds)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Y-axis labels
                        SizedBox(
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(6, (index) {
                              final value =
                                  (maxValue / 5 * (5 - index)).toInt();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  value.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Bar chart content
                        Expanded(
                          child: Stack(
                            children: [
                              // Horizontal grid lines
                              ...List.generate(6, (index) {
                                final top = constraints.maxHeight / 5 * index;
                                return Positioned(
                                  left: 0,
                                  right: 0,
                                  top: top,
                                  child: Container(
                                    height: 1,
                                    color:
                                        AppColors.borderColor.withOpacity(0.5),
                                  ),
                                );
                              }),

                              // Bars
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: sortedEntries.map((entry) {
                                  final barHeight = (entry.value / maxValue) *
                                      constraints.maxHeight;
                                  return Tooltip(
                                    message:
                                        '${entry.key}: ${entry.value.toStringAsFixed(2)} sec',
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: constraints.maxWidth /
                                              (sortedEntries.length * 2),
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryColor
                                                    .withOpacity(0.3),
                                                offset: const Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: constraints.maxWidth /
                                              (sortedEntries.length * 1.5),
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppColors.textSecondaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
