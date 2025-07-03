// ignore_for_file: unused_local_variable, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/analytics_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Import for web download - using universal_html
import 'package:universal_html/html.dart' as html;
// Only import dart:io for non-web platforms
import 'dart:io' if (dart.library.html) 'package:admin_penal/web_stub_io.dart'
    as io;

class AnalyticsExport {
  // Show export options dialog
  static void showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Export Analytics Report',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose export format:',
                style: TextStyle(color: AppColors.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              _buildExportOption(
                context,
                'PDF Document',
                Icons.picture_as_pdf,
                Colors.red.shade700,
                () => _showDateRangeDialog(context, 'pdf'),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                'CSV File',
                Icons.insert_drive_file,
                Colors.blue.shade700,
                () => _showDateRangeDialog(context, 'csv'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondaryColor),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        );
      },
    );
  }

  // Show date range selection dialog
  static void _showDateRangeDialog(BuildContext context, String format) {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();
    String reportType = "Monthly";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Select Report Period',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Type Selection
                const Text(
                  'Report Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: reportType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Monthly', child: Text('Monthly Report')),
                    DropdownMenuItem(
                        value: 'Quarterly', child: Text('Quarterly Report')),
                    DropdownMenuItem(
                        value: 'Annual', child: Text('Annual Report')),
                    DropdownMenuItem(
                        value: 'Custom', child: Text('Custom Date Range')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      reportType = value!;

                      // Update date range based on report type
                      if (value == 'Monthly') {
                        startDate =
                            DateTime.now().subtract(const Duration(days: 30));
                        endDate = DateTime.now();
                      } else if (value == 'Quarterly') {
                        startDate =
                            DateTime.now().subtract(const Duration(days: 90));
                        endDate = DateTime.now();
                      } else if (value == 'Annual') {
                        startDate =
                            DateTime.now().subtract(const Duration(days: 365));
                        endDate = DateTime.now();
                      }
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Custom Date Range Fields (enabled if Custom is selected)
                if (reportType == 'Custom') ...[
                  const Text(
                    'Date Range:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null && pickedDate != startDate) {
                              setState(() {
                                startDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(startDate),
                                  style: const TextStyle(
                                      color: AppColors.textPrimaryColor),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('to',
                            style:
                                TextStyle(color: AppColors.textSecondaryColor)),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null && pickedDate != endDate) {
                              setState(() {
                                endDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(endDate),
                                  style: const TextStyle(
                                      color: AppColors.textPrimaryColor),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Show date range information for preset periods
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Period:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
                          style: const TextStyle(
                              color: AppColors.textPrimaryColor),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Summary of selected options
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Summary:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Type: $reportType Report',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text(
                        '• Format: ${format.toUpperCase()}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text(
                        '• Date Range: ${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text(
                        '• Period: ${endDate.difference(startDate).inDays + 1} days',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  exportReport(context, format, startDate, endDate, reportType);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text(
                  'Generate Report',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
          );
        });
      },
    );
  }

  // Build export option button
  static Widget _buildExportOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // Export report implementation
  static void exportReport(BuildContext context, String format,
      DateTime startDate, DateTime endDate, String reportType) async {
    // Get the analytics provider
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);

    // Filter data based on date range
    // In a real implementation, you would filter data from your provider
    // This is a simplified example - you'll need to adapt to your actual data structure
    final filteredData =
        _filterDataByDateRange(analyticsProvider, startDate, endDate);

    // Collect real analytics data for the export
    final data = {
      'timestamp': DateTime.now().toString(),
      'report_type': reportType,
      'export_format': format.toUpperCase(),
      'date_range': {
        'start': startDate.toString(),
        'end': endDate.toString(),
        'formatted_start': DateFormat('MMMM dd, yyyy').format(startDate),
        'formatted_end': DateFormat('MMMM dd, yyyy').format(endDate),
      },
      'statistics': filteredData['statistics'],
      'revenue_data': filteredData['revenue_data'],
      'orders_data': filteredData['orders_data'],
      'category_distribution': filteredData['category_distribution'],
      'user_growth': filteredData['user_growth'],
      'top_products': filteredData['top_products'],
      'metrics_data': {
        'total_revenue': analyticsProvider.totalRevenue,
        'revenue_change': analyticsProvider.revenueChange,
        'average_order_value': analyticsProvider.averageOrderValue,
        'aov_change': analyticsProvider.aovChange,
        'conversion_rate': analyticsProvider.conversionRate,
        'conversion_change': analyticsProvider.conversionChange,
        'customer_retention': analyticsProvider.customerRetention,
        'retention_change': analyticsProvider.retentionChange,
      }
    };

    // Generate filename with timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final dateRangeString =
        '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    final fileName =
        'ar_furnish_${reportType.toLowerCase()}_report_${dateRangeString}_$timestamp.$format';

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryColor),
              const SizedBox(height: 20),
              Text('Generating $format report...',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'Time period: ${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    try {
      if (kIsWeb) {
        // Web platform export
        await _exportForWeb(context, data, format, fileName);
      } else {
        // Native platform export (Android, iOS, Windows, etc.)
        await _exportForNative(context, data, format, fileName);
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting report: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Show a dialog with more details about what went wrong
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Error',
              style: TextStyle(color: AppColors.errorColor)),
          content: Text(
              'Could not save the file: ${e.toString()}\n\nPlease check app permissions and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK',
                  style: TextStyle(color: AppColors.primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to filter data by date range
  static Map<String, dynamic> _filterDataByDateRange(
      AnalyticsProvider provider, DateTime startDate, DateTime endDate) {
    // This is a simplified example of filtering
    // In a real implementation, you would filter actual data from your provider

    // For the sake of demonstration, we're returning placeholder data
    // Replace this with actual filtering logic

    // Get all data from provider
    final statistics = provider.statistics;
    final revenueData = provider.monthlySalesData;
    final ordersData = provider.ordersData;
    final categoryDistribution = provider.categoryDistribution;
    final userGrowthData = provider.userGrowthData;

    // Sample top products data (would come from your provider in a real implementation)
    final topProducts = [
      {'name': 'Modern Sofa', 'sales': 254, 'revenue': 1524000, 'rating': 4.7},
      {
        'name': 'Classic Coffee Table',
        'sales': 198,
        'revenue': 594000,
        'rating': 4.5
      },
      {
        'name': 'Elegant Dining Set',
        'sales': 174,
        'revenue': 1218000,
        'rating': 4.8
      },
      {
        'name': 'Contemporary Bed Frame',
        'sales': 156,
        'revenue': 1092000,
        'rating': 4.6
      },
      {
        'name': 'Minimalist Bookshelf',
        'sales': 142,
        'revenue': 426000,
        'rating': 4.4
      },
    ];

    // Sample daily traffic data
    final dailyTraffic = List.generate(30, (index) {
      final day = DateTime.now().subtract(Duration(days: 29 - index));
      return {
        'date': day.toString(),
        'formatted_date': DateFormat('MMM dd').format(day),
        'visitors': 500 +
            (index * 10) +
            (day.weekday < 6 ? 150 : 0) +
            (index % 7 == 0 ? 300 : 0),
        'conversions': 20 + (index * 0.5).round() + (day.weekday < 6 ? 8 : 2),
      };
    });

    // Sample customer demographics
    final customerDemographics = {
      'age_groups': [
        {'range': '18-24', 'percentage': 18},
        {'range': '25-34', 'percentage': 35},
        {'range': '35-44', 'percentage': 24},
        {'range': '45-54', 'percentage': 14},
        {'range': '55+', 'percentage': 9},
      ],
      'gender': [
        {'type': 'Male', 'percentage': 42},
        {'type': 'Female', 'percentage': 58},
      ],
      'locations': [
        {'city': 'Karachi', 'percentage': 28},
        {'city': 'Lahore', 'percentage': 22},
        {'city': 'Islamabad', 'percentage': 14},
        {'city': 'Rawalpindi', 'percentage': 9},
        {'city': 'Other', 'percentage': 27},
      ],
    };

    // Return combined data
    return {
      'statistics': statistics,
      'revenue_data': revenueData,
      'orders_data': ordersData,
      'category_distribution': categoryDistribution,
      'user_growth': userGrowthData,
      'top_products': topProducts,
      'daily_traffic': dailyTraffic,
      'customer_demographics': customerDemographics,
    };
  }

  // Handle export for web platforms
  static Future<void> _exportForWeb(BuildContext context,
      Map<String, dynamic> data, String format, String fileName) async {
    List<int> bytes;
    if (format == 'pdf') {
      bytes = await _generatePdfForWeb(data);
    } else {
      // Default to CSV
      bytes = await _generateCsvForWeb(data);
    }

    // Create a blob from the bytes
    final blob = html.Blob([bytes]);

    // Create a URL for the blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element with the download attribute
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    // Add the anchor to the document body and click it
    html.document.body?.children.add(anchor);
    anchor.click();

    // Clean up
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    // Close loading dialog
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analytics report downloaded as $fileName'),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Handle export for native platforms
  static Future<void> _exportForNative(BuildContext context,
      Map<String, dynamic> data, String format, String fileName) async {
    // Get the downloads directory
    io.Directory? directory;

    // For Android, iOS, and Windows, choose the appropriate directory
    try {
      if (io.Platform.isAndroid) {
        // Request storage permissions on Android
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
          status = await Permission.storage.status;
          if (!status.isGranted) {
            throw Exception("Storage permission denied");
          }
        }

        // Get downloads directory
        directory = io.Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            directory = io.Directory(extDir.path);
          }
        }
      } else if (io.Platform.isIOS) {
        final docDir = await getApplicationDocumentsDirectory();
        directory = io.Directory(docDir.path);
      } else {
        // For Windows, macOS, Linux - try multiple approaches
        try {
          // First try downloads
          final dlDir = await getDownloadsDirectory();
          if (dlDir != null) {
            directory = io.Directory(dlDir.path);
          }
        } catch (e) {
          // If that fails, try documents directory
          try {
            final docDir = await getApplicationDocumentsDirectory();
            directory = io.Directory(docDir.path);
          } catch (e) {
            // Last resort, try temporary directory
            final tempDir = await getTemporaryDirectory();
            directory = io.Directory(tempDir.path);
          }
        }
      }
    } catch (e) {
      // If all else fails, create a directory in the working directory
      final String currentPath = io.Directory.current.path;
      directory = io.Directory('$currentPath/exports');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    if (directory == null) {
      throw Exception("Could not access storage directory");
    }

    // Generate the file based on format
    io.File file;
    String fullPath = '${directory.path}/$fileName';

    if (format == 'pdf') {
      file = await _generatePdfReport(data, fullPath);
    } else {
      // Default to CSV
      file = await _generateCsvReport(data, fullPath);
    }

    // Close loading dialog
    Navigator.of(context).pop();

    // Show success message with the file path
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analytics report exported to:\n${file.path}'),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.white,
          onPressed: () {
            // Open the file
            OpenFile.open(file.path);
          },
        ),
      ),
    );
  }

  // Generate PDF for web platform
  static Future<List<int>> _generatePdfForWeb(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Format values
    final formatCurrency = NumberFormat.currency(
        locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);
    final totalRevenue = data['statistics']['totalRevenue'] as double? ?? 0.0;
    final totalOrders = data['statistics']['totalOrders'] as int? ?? 0;
    final totalProducts = data['statistics']['totalProducts'] as int? ?? 0;
    final totalUsers = data['statistics']['totalUsers'] as int? ?? 0;

    // Extract date range
    final dateRange = data['date_range'];
    final reportType = data['report_type'] as String;

    // Define theme
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    // Add pages to PDF
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      header: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo700,
          borderRadius: pw.BorderRadius.circular(2),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('AR Furnish Analytics Report',
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.Text(reportType,
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            ]),
      ),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(width: 1, color: PdfColors.grey300))),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10)),
            ]),
      ),
      build: (context) => [
        // Report Header
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Report Details',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            'Period: ${dateRange['formatted_start']} - ${dateRange['formatted_end']}'),
                        pw.Text('Report Type: $reportType'),
                        pw.Text('Format: ${data['export_format']}'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Generated By: Admin'),
                        pw.Text(
                            'Generated On: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}'),
                        pw.Text('AR Furnish Version: 1.0.0'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Executive Summary
        pw.Header(level: 0, text: 'Executive Summary'),
        pw.Paragraph(
            text:
                'This report provides a comprehensive analysis of business performance metrics for the selected period. '
                'The data shows key performance indicators across various business aspects including sales, customer engagement, and product performance.'),

        // KPI Overview - Main Statistics
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 10, bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildPdfStatBox(
                  'Total Revenue',
                  formatCurrency.format(totalRevenue),
                  '+12.5%',
                  PdfColors.green700),
              _buildPdfStatBox('Total Orders', totalOrders.toString(), '+18.3%',
                  PdfColors.green700),
              _buildPdfStatBox(
                  'Average Order',
                  formatCurrency.format(
                      totalRevenue / (totalOrders > 0 ? totalOrders : 1)),
                  '+5.2%',
                  PdfColors.green700),
              _buildPdfStatBox('Customers', totalUsers.toString(), '+15.7%',
                  PdfColors.green700),
            ],
          ),
        ),

        // Performance Metrics Table
        pw.Header(level: 1, text: 'Performance Metrics'),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
          headerHeight: 25,
          cellHeight: 25,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
          headers: ['Metric', 'Current', 'Previous', 'Change'],
          data: [
            [
              'Revenue',
              formatCurrency.format(data['metrics_data']['total_revenue']),
              formatCurrency.format(data['metrics_data']['total_revenue'] /
                  (1 + data['metrics_data']['revenue_change'] / 100)),
              '${data['metrics_data']['revenue_change'] >= 0 ? '+' : ''}${data['metrics_data']['revenue_change'].toStringAsFixed(1)}%'
            ],
            [
              'Average Order Value',
              formatCurrency
                  .format(data['metrics_data']['average_order_value']),
              formatCurrency.format(data['metrics_data']
                      ['average_order_value'] /
                  (1 + data['metrics_data']['aov_change'] / 100)),
              '${data['metrics_data']['aov_change'] >= 0 ? '+' : ''}${data['metrics_data']['aov_change'].toStringAsFixed(1)}%'
            ],
            [
              'Conversion Rate',
              '${data['metrics_data']['conversion_rate'].toStringAsFixed(1)}%',
              '${(data['metrics_data']['conversion_rate'] - data['metrics_data']['conversion_change']).toStringAsFixed(1)}%',
              '${data['metrics_data']['conversion_change'] >= 0 ? '+' : ''}${data['metrics_data']['conversion_change'].toStringAsFixed(1)}%'
            ],
            [
              'Customer Retention',
              '${data['metrics_data']['customer_retention'].toStringAsFixed(1)}%',
              '${(data['metrics_data']['customer_retention'] - data['metrics_data']['retention_change']).toStringAsFixed(1)}%',
              '${data['metrics_data']['retention_change'] >= 0 ? '+' : ''}${data['metrics_data']['retention_change'].toStringAsFixed(1)}%'
            ],
          ],
        ),

        pw.SizedBox(height: 20),

        // Revenue Breakdown
        pw.Header(level: 1, text: 'Revenue Breakdown'),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          headers: ['Month/Period', 'Revenue (PKR)'],
          data: (data['revenue_data'] as List<dynamic>)
              .map((item) => [
                    item['month'],
                    formatCurrency.format(item['sales'] as double? ?? 0.0)
                  ])
              .toList(),
        ),

        pw.SizedBox(height: 20),

        // Top Products Section
        pw.Header(level: 1, text: 'Top Selling Products'),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.center,
          },
          headers: ['Product Name', 'Units Sold', 'Revenue', 'Rating'],
          data: (data['top_products'] as List<dynamic>)
              .map((item) => [
                    item['name'],
                    item['sales'].toString(),
                    formatCurrency.format(item['revenue'] as int? ?? 0),
                    '${item['rating']} ★',
                  ])
              .toList(),
        ),

        pw.SizedBox(height: 20),

        // Orders Data Section
        pw.Header(level: 1, text: 'Orders Analysis'),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          headers: ['Month/Period', 'Orders Count'],
          data: (data['orders_data'] as List<dynamic>)
              .map((item) => [item['month'], item['orders'].toString()])
              .toList(),
        ),

        pw.SizedBox(height: 20),

        // Categories Section
        pw.Header(level: 1, text: 'Product Categories Distribution'),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          headers: ['Category', 'Product Count'],
          data: (data['category_distribution'] as List<dynamic>)
              .map((item) => [item['category'], item['count'].toString()])
              .toList(),
        ),

        pw.SizedBox(height: 20),

        // Conclusion and Recommendations
        pw.Header(level: 1, text: 'Conclusions & Recommendations'),
        pw.Paragraph(
            text:
                'Based on the analysis of the data for this period, the following recommendations are provided:'),
        pw.Bullet(
            text:
                'Focus on increasing the conversion rate through targeted promotions and improved user experience.'),
        pw.Bullet(
            text:
                'Expand marketing efforts for high-performing product categories.'),
        pw.Bullet(
            text:
                'Implement strategies to increase average order value, such as bundled product offerings.'),
        pw.Bullet(
            text:
                'Continue to monitor customer retention and implement loyalty programs to improve metrics.'),
      ],
    ));

    // Return PDF bytes
    return pdf.save();
  }

  // Helper method to create stat boxes for PDF
  static pw.Widget _buildPdfStatBox(
      String title, String value, String change, PdfColor changeColor) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            change,
            style: pw.TextStyle(
              fontSize: 10,
              color: changeColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Generate CSV for web platform
  static Future<List<int>> _generateCsvForWeb(Map<String, dynamic> data) async {
    // Create CSV content
    final StringBuffer csvContent = StringBuffer();

    // Format values
    final formatCurrency = NumberFormat.currency(
        locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

    // Add report header
    csvContent.writeln('AR Furnish Analytics Report');
    csvContent.writeln(
        'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
    csvContent.writeln('');

    // Add summary section
    csvContent.writeln('SUMMARY');
    csvContent.writeln(
        'Total Revenue,${formatCurrency.format(data['statistics']['totalRevenue'] as double? ?? 0.0)}');
    csvContent
        .writeln('Total Orders,${data['statistics']['totalOrders'] ?? 0}');
    csvContent
        .writeln('Total Products,${data['statistics']['totalProducts'] ?? 0}');
    csvContent.writeln('Total Users,${data['statistics']['totalUsers'] ?? 0}');
    csvContent.writeln('');

    // Add revenue data
    csvContent.writeln('REVENUE DATA');
    csvContent.writeln('Month,Revenue');
    for (final item in data['revenue_data'] as List) {
      csvContent.writeln('${item['month']},${item['sales']}');
    }
    csvContent.writeln('');

    // Add orders data
    csvContent.writeln('ORDERS DATA');
    csvContent.writeln('Month,Orders');
    for (final item in data['orders_data'] as List) {
      csvContent.writeln('${item['month']},${item['orders']}');
    }
    csvContent.writeln('');

    // Add category data
    csvContent.writeln('PRODUCT CATEGORIES');
    csvContent.writeln('Category,Count');
    for (final item in data['category_distribution'] as List) {
      csvContent.writeln('${item['category']},${item['count']}');
    }

    // Return CSV bytes
    return utf8.encode(csvContent.toString());
  }

  // Generate PDF report
  static Future<io.File> _generatePdfReport(
      Map<String, dynamic> data, String filePath) async {
    final pdf = pw.Document();

    // Format values
    final formatCurrency = NumberFormat.currency(
        locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);
    final totalRevenue = data['statistics']['totalRevenue'] as double? ?? 0.0;
    final totalOrders = data['statistics']['totalOrders'] as int? ?? 0;
    final totalProducts = data['statistics']['totalProducts'] as int? ?? 0;
    final totalUsers = data['statistics']['totalUsers'] as int? ?? 0;

    // Add pages to PDF
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Header(
        level: 0,
        child: pw.Text('AR Furnish Analytics Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      ),
      footer: (context) => pw.Footer(
        title: pw.Text(
            'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10)),
      ),
      build: (context) => [
        // Summary section
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Summary',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total Revenue: ${formatCurrency.format(totalRevenue)}'),
              pw.Text('Total Orders: $totalOrders'),
              pw.Text('Total Products: $totalProducts'),
              pw.Text('Total Users: $totalUsers'),
              pw.SizedBox(height: 5),
              pw.Text('Report Generated: ${data['timestamp']}'),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Revenue data section
        pw.Header(level: 1, text: 'Revenue Data'),
        pw.Table.fromTextArray(
          headers: ['Month', 'Revenue (PKR)'],
          data: (data['revenue_data'] as List<dynamic>)
              .map((item) => [
                    item['month'],
                    formatCurrency.format(item['sales'] as double? ?? 0.0)
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          border: pw.TableBorder.all(),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
        ),

        pw.SizedBox(height: 20),

        // Orders data section
        pw.Header(level: 1, text: 'Orders Data'),
        pw.Table.fromTextArray(
          headers: ['Month', 'Orders'],
          data: (data['orders_data'] as List<dynamic>)
              .map((item) => [item['month'], item['orders'].toString()])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          border: pw.TableBorder.all(),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
        ),

        pw.SizedBox(height: 20),

        // Categories section
        pw.Header(level: 1, text: 'Product Categories'),
        pw.Table.fromTextArray(
          headers: ['Category', 'Count'],
          data: (data['category_distribution'] as List<dynamic>)
              .map((item) => [item['category'], item['count'].toString()])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          border: pw.TableBorder.all(),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
        ),
      ],
    ));

    // Save the file
    final file = io.File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Generate CSV report
  static Future<io.File> _generateCsvReport(
      Map<String, dynamic> data, String filePath) async {
    // Create CSV content
    final StringBuffer csvContent = StringBuffer();

    // Format values
    final formatCurrency = NumberFormat.currency(
        locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

    // Add report header
    csvContent.writeln('AR Furnish Analytics Report');
    csvContent.writeln(
        'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
    csvContent.writeln('');

    // Add summary section
    csvContent.writeln('SUMMARY');
    csvContent.writeln(
        'Total Revenue,${formatCurrency.format(data['statistics']['totalRevenue'] as double? ?? 0.0)}');
    csvContent
        .writeln('Total Orders,${data['statistics']['totalOrders'] ?? 0}');
    csvContent
        .writeln('Total Products,${data['statistics']['totalProducts'] ?? 0}');
    csvContent.writeln('Total Users,${data['statistics']['totalUsers'] ?? 0}');
    csvContent.writeln('');

    // Add revenue data
    csvContent.writeln('REVENUE DATA');
    csvContent.writeln('Month,Revenue');
    for (final item in data['revenue_data'] as List) {
      csvContent.writeln('${item['month']},${item['sales']}');
    }
    csvContent.writeln('');

    // Add orders data
    csvContent.writeln('ORDERS DATA');
    csvContent.writeln('Month,Orders');
    for (final item in data['orders_data'] as List) {
      csvContent.writeln('${item['month']},${item['orders']}');
    }
    csvContent.writeln('');

    // Add category data
    csvContent.writeln('PRODUCT CATEGORIES');
    csvContent.writeln('Category,Count');
    for (final item in data['category_distribution'] as List) {
      csvContent.writeln('${item['category']},${item['count']}');
    }

    // Save the file
    final file = io.File(filePath);
    await file.writeAsBytes(utf8.encode(csvContent.toString()));
    return file;
  }
}
