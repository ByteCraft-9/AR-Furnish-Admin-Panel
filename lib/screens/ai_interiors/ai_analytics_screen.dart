import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/ai_provider.dart';
import '../../widgets/sidebar.dart';
import 'widgets/theme_processing_time_chart.dart';
import 'widgets/theme_distribution_chart.dart';

class AIAnalyticsScreen extends StatefulWidget {
  const AIAnalyticsScreen({super.key});

  @override
  State<AIAnalyticsScreen> createState() => _AIAnalyticsScreenState();
}

class _AIAnalyticsScreenState extends State<AIAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> fixedThemes = [
    'Modern',
    'Contemporary',
    'Minimalist',
    'Traditional',
    'Industrial',
    'Scandinavian',
    'All Themes',
  ];
  String _selectedTheme = 'All Themes';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = Provider.of<AIProvider>(context, listen: false);
      aiProvider.loadAIModels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: 7, // AI Interiors index
            onItemSelected: (index) {
              if (index != 7) {
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
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        'AI Interior Design Analytics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildFilterDropdown(),
                      const SizedBox(width: 12),
                      _buildDateRangeSelector(),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Consumer<AIProvider>(
                      builder: (context, aiProvider, child) {
                        if (aiProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (aiProvider.errorMessage != null) {
                          return Center(
                            child: Text(
                              'Error: ${aiProvider.errorMessage}',
                              style:
                                  const TextStyle(color: AppColors.errorColor),
                            ),
                          );
                        }

                        if (aiProvider.filteredModels.isEmpty) {
                          return const Center(
                            child: Text('No AI model data available'),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Statistics cards
                            _buildStatisticsCards(aiProvider, isMobile),
                            const SizedBox(height: 12),

                            // Charts
                            isMobile
                                ? Column(
                                    children: [
                                      SizedBox(
                                        height: 350,
                                        child: ThemeProcessingTimeChart(
                                          themeProcessingTimes: aiProvider
                                              .getAverageProcessingTimeByTheme(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 350,
                                        child: ThemeDistributionChart(
                                          themeDistribution:
                                              aiProvider.getThemeDistribution(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTimeSeriesChart(aiProvider),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      SizedBox(
                                        height: 350,
                                        child: IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: ThemeProcessingTimeChart(
                                                  themeProcessingTimes: aiProvider
                                                      .getAverageProcessingTimeByTheme(),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 2,
                                                child: ThemeDistributionChart(
                                                  themeDistribution: aiProvider
                                                      .getThemeDistribution(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTimeSeriesChart(aiProvider),
                                    ],
                                  ),

                            const SizedBox(height: 12),

                            // Data table
                            _buildDataTable(aiProvider),
                          ],
                        );
                      },
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

  Widget _buildFilterDropdown() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, child) {
        return DropdownButton<String>(
          hint: const Text('Filter by Theme'),
          value: _selectedTheme,
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                _selectedTheme = value;
              });

              if (value == 'All Themes') {
                aiProvider.clearFilters();
              } else {
                aiProvider.filterByTheme(value);
              }
            }
          },
          items: fixedThemes
              .map<DropdownMenuItem<String>>(
                (String theme) => DropdownMenuItem<String>(
                  value: theme,
                  child: Text(theme),
                ),
              )
              .toList(),
          underline: Container(
            height: 1,
            color: AppColors.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, child) {
        final startText = _startDate != null
            ? DateFormat('MM/dd/yy').format(_startDate!)
            : 'Start';
        final endText =
            _endDate != null ? DateFormat('MM/dd/yy').format(_endDate!) : 'End';

        return Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 14),
              label: Text(
                '$startText - $endText',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () async {
                final dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _startDate != null && _endDate != null
                      ? DateTimeRange(start: _startDate!, end: _endDate!)
                      : null,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (dateRange != null) {
                  setState(() {
                    _startDate = dateRange.start;
                    _endDate = dateRange.end;
                    aiProvider.filterByDateRange(_startDate!, _endDate!);
                  });
                }
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
              ),
            ),
            if (_startDate != null && _endDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    aiProvider.clearDateFilter();
                  });
                },
                tooltip: 'Clear date filter',
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimeSeriesChart(AIProvider aiProvider) {
    final processingTimeTrends = aiProvider.getProcessingTimeTrends();

    if (processingTimeTrends.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: Text('No data available for processing time trends'),
          ),
        ),
      );
    }

    final sortedEntries = processingTimeTrends.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Calculate the maximum value to prevent overflow
    double maxValue = 0;
    for (var entry in sortedEntries) {
      if (entry.value > maxValue) {
        maxValue = entry.value;
      }
    }

    // Calculate the safe height multiplier
    final scaleFactor = maxValue > 0 ? 180 / maxValue : 10;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Processing Time Trends (seconds)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final date = entry.key;
                  final value = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 16,
                          height: value *
                              scaleFactor, // Use calculated scale factor
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(AIProvider aiProvider, bool isMobile) {
    final totalModels = aiProvider.filteredModels.length;

    // Calculate average processing time
    double avgProcessingTime = 0;
    if (totalModels > 0) {
      final sum = aiProvider.filteredModels
          .map((model) => model.processingTimeInSeconds)
          .reduce((a, b) => a + b);
      avgProcessingTime = sum / totalModels;
    }

    // Find fastest and slowest times
    double? fastestTime;
    double? slowestTime;
    String? fastestTheme;
    String? slowestTheme;

    if (totalModels > 0) {
      for (final model in aiProvider.filteredModels) {
        if (fastestTime == null ||
            model.processingTimeInSeconds < fastestTime) {
          fastestTime = model.processingTimeInSeconds;
          fastestTheme = model.theme;
        }

        if (slowestTime == null ||
            model.processingTimeInSeconds > slowestTime) {
          slowestTime = model.processingTimeInSeconds;
          slowestTheme = model.theme;
        }
      }
    }

    // Count unique themes and users
    final uniqueThemes =
        aiProvider.filteredModels.map((model) => model.theme).toSet().length;

    final uniqueUsers =
        aiProvider.filteredModels.map((model) => model.userId).toSet().length;

    final statItems = [
      _buildStatItem(
        title: 'Total Renders',
        value: totalModels.toString(),
        icon: Icons.photo_library,
        color: AppColors.primaryColor,
      ),
      _buildStatItem(
        title: 'Avg. Processing',
        value: '${avgProcessingTime.toStringAsFixed(1)}s',
        icon: Icons.timer,
        color: AppColors.secondaryColor,
      ),
      _buildStatItem(
        title: 'Themes',
        value: uniqueThemes.toString(),
        icon: Icons.category,
        color: AppColors.successColor,
      ),
      _buildStatItem(
        title: 'Users',
        value: uniqueUsers.toString(),
        icon: Icons.people,
        color: AppColors.warningColor,
      ),
      _buildStatItem(
        title: 'Fastest',
        value: '${fastestTime?.toStringAsFixed(1) ?? "N/A"}s',
        subtitle: fastestTheme ?? '',
        icon: Icons.speed,
        color: AppColors.successColor,
      ),
      _buildStatItem(
        title: 'Slowest',
        value: '${slowestTime?.toStringAsFixed(1) ?? "N/A"}s',
        subtitle: slowestTheme ?? '',
        icon: Icons.hourglass_bottom,
        color: AppColors.errorColor,
      ),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: isMobile
            ? GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: statItems,
              )
            : GridView.count(
                crossAxisCount: 6,
                childAspectRatio: 1.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: statItems,
              ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondaryColor,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable(AIProvider aiProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'AI Interior Render Records',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: tableWidth),
                    child: DataTable(
                      headingRowHeight: 50,
                      dataRowHeight: 60,
                      columnSpacing: 20,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(
                            label: Text('Date',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Theme',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('User',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Time (s)',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Preview',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Prompt',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                      ],
                      rows: aiProvider.filteredModels.map((model) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormat('MM/dd/yy')
                                    .format(model.createdAt.toDate()),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            DataCell(Text(model.theme,
                                style: const TextStyle(fontSize: 14))),
                            DataCell(Text(model.userName ?? 'Unknown',
                                style: const TextStyle(fontSize: 14))),
                            DataCell(Text(
                                model.processingTimeInSeconds
                                    .toStringAsFixed(1),
                                style: const TextStyle(fontSize: 14))),
                            DataCell(
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppBar(
                                            title: const Text('Image Preview'),
                                            automaticallyImplyLeading: false,
                                            actions: [
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Image.network(
                                              model.outputImageUrl,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            (loadingProgress
                                                                    .expectedTotalBytes ??
                                                                1)
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.error_outline,
                                                    color: AppColors.errorColor,
                                                    size: 48,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Text(
                                              model.prompt,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    model.outputImageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: AppColors.errorColor,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Tooltip(
                                message: model.prompt,
                                child: Text(
                                  model.prompt.length > 30
                                      ? '${model.prompt.substring(0, 30)}...'
                                      : model.prompt,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
}
