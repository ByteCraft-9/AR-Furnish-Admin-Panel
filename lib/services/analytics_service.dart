// ignore_for_file: avoid_types_as_parameter_names, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final math.Random _random = math.Random();

  // Get total products count
  Future<int> getTotalProductsCount() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('products').get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  // Get total promotions count
  Future<int> getTotalPromotionsCount() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('promotion').get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  // Get total orders count
  Future<int> getTotalOrdersCount() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('orders').get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  // Get monthly sales data from orders collection
  Future<List<Map<String, dynamic>>> getMonthlySalesData() async {
    try {
      // Get all orders sorted by date
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .orderBy('orderDate', descending: false)
          .get();

      // Process orders to get monthly data
      Map<String, double> monthlyTotals = {};

      // Current date for calculating last 12 months
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, now.month, 1);

      // Initialize all months with zero to ensure complete data
      for (int i = 0; i < 12; i++) {
        final month = DateTime(startDate.year, startDate.month + i, 1);
        final key = DateFormat('MMM yyyy').format(month);
        monthlyTotals[key] = 0.0;
      }

      // Sum up order amounts by month
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Debug print to see order data

        // Try different possible field names for price
        num price = 0;
        if (data.containsKey('price')) {
          price = data['price'] as num? ?? 0;
        } else if (data.containsKey('total')) {
          price = data['total'] as num? ?? 0;
        } else if (data.containsKey('totalAmount')) {
          price = data['totalAmount'] as num? ?? 0;
        } else if (data.containsKey('amount')) {
          price = data['amount'] as num? ?? 0;
        }

        if (data['orderDate'] != null) {
          // Convert Firestore timestamp to DateTime
          final DateTime orderDate;
          if (data['orderDate'] is Timestamp) {
            orderDate = (data['orderDate'] as Timestamp).toDate();
          } else if (data['orderDate'] is String) {
            // Try to parse string date
            try {
              orderDate = DateTime.parse(data['orderDate'] as String);
            } catch (e) {
              continue;
            }
          } else {
            continue;
          }

          // Only include orders in the last 12 months
          if (orderDate.isAfter(startDate)) {
            final String monthKey = DateFormat('MMM yyyy').format(orderDate);
            monthlyTotals[monthKey] =
                (monthlyTotals[monthKey] ?? 0) + price.toDouble();

            // Debug print month and amount
          }
        }
      }

      // Convert to list format sorted by date
      List<Map<String, dynamic>> result = [];

      monthlyTotals.forEach((month, sales) {
        result.add({
          'month': month,
          'sales': sales,
        });
      });

      // Sort by date (month + year)
      result.sort((a, b) {
        final aDate = DateFormat('MMM yyyy').parse(a['month'] as String);
        final bDate = DateFormat('MMM yyyy').parse(b['month'] as String);
        return aDate.compareTo(bDate);
      });

      // If no real data was found, generate sample data for testing
      if (snapshot.docs.isEmpty ||
          result.every((element) => (element['sales'] as double) == 0)) {
        return _generateSampleSalesData();
      }

      return result;
    } catch (e) {
      // Return sample data on error
      return _generateSampleSalesData();
    }
  }

  // Generate sample data for testing if no real data is available
  List<Map<String, dynamic>> _generateSampleSalesData() {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    // Generate data for the last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(month);

      // Random amount between 10,000 and 100,000
      final amount = 10000.0 + (90000.0 * _random.nextDouble());

      result.add({
        'month': monthKey,
        'sales': amount,
      });
    }

    return result;
  }

  // Get daily sales data for selected month
  Future<List<Map<String, dynamic>>> getDailySalesData(int monthsAgo) async {
    try {
      // Calculate start and end dates
      final now = DateTime.now();

      // For the current month (monthsAgo = 0), use 1st of current month to today
      // For previous months, use the entire month
      final DateTime startDate;
      final DateTime endDate;

      if (monthsAgo == 0) {
        // Current month: from 1st to today
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day + 1); // Include today
      } else {
        // Previous month: entire month
        startDate = DateTime(now.year, now.month - monthsAgo, 1);
        // End date is the 1st of the next month
        endDate = DateTime(now.year, now.month - monthsAgo + 1, 1);
      }

      // Get orders within date range
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('orderDate', descending: false)
          .get();

      // Process orders to get daily data
      Map<String, double> dailyTotals = {};

      // Initialize all days with zero to ensure complete data
      final daysInMonth = monthsAgo == 0
          ? now.day // Current month: days up to today
          : DateTime(now.year, now.month - monthsAgo + 1, 0)
              .day; // Previous month: all days

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(startDate.year, startDate.month, day);
        final key = DateFormat('d MMM').format(date);
        dailyTotals[key] = 0.0;
      }

      // Sum up order amounts by day
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Try different possible field names for price
        num price = 0;
        if (data.containsKey('price')) {
          price = data['price'] as num? ?? 0;
        } else if (data.containsKey('total')) {
          price = data['total'] as num? ?? 0;
        } else if (data.containsKey('totalAmount')) {
          price = data['totalAmount'] as num? ?? 0;
        } else if (data.containsKey('amount')) {
          price = data['amount'] as num? ?? 0;
        }

        if (data['orderDate'] != null) {
          DateTime orderDate;
          if (data['orderDate'] is Timestamp) {
            orderDate = (data['orderDate'] as Timestamp).toDate();
          } else if (data['orderDate'] is String) {
            try {
              orderDate = DateTime.parse(data['orderDate'] as String);
            } catch (e) {
              continue;
            }
          } else {
            continue;
          }

          final String dayKey = DateFormat('d MMM').format(orderDate);
          dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + price.toDouble();

          // Debug print day and amount
        }
      }

      // Convert to list format
      List<Map<String, dynamic>> result = [];

      dailyTotals.forEach((day, amount) {
        result.add({
          'label': day,
          'amount': amount,
        });
      });

      // Sort by date (day of month)
      result.sort((a, b) {
        final aDate = DateFormat('d MMM').parse(a['label'] as String);
        final bDate = DateFormat('d MMM').parse(b['label'] as String);
        return aDate.compareTo(bDate);
      });

      // If no real data was found, generate sample data for testing
      if (snapshot.docs.isEmpty ||
          result.every((element) => (element['amount'] as double) == 0)) {
        return _generateSampleDailyData(startDate, daysInMonth);
      }

      return result;
    } catch (e) {
      // Generate sample data on error
      final daysInMonth = monthsAgo == 0
          ? DateTime.now().day
          : DateTime(
                  DateTime.now().year, DateTime.now().month - monthsAgo + 1, 0)
              .day;

      final startDate = monthsAgo == 0
          ? DateTime(DateTime.now().year, DateTime.now().month, 1)
          : DateTime(DateTime.now().year, DateTime.now().month - monthsAgo, 1);

      return _generateSampleDailyData(startDate, daysInMonth);
    }
  }

  // Generate sample daily data for testing if no real data is available
  List<Map<String, dynamic>> _generateSampleDailyData(
      DateTime startDate, int daysInMonth) {
    final result = <Map<String, dynamic>>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(startDate.year, startDate.month, day);
      final dayKey = DateFormat('d MMM').format(date);

      // Random amount between 1,000 and 10,000
      final amount = 1000.0 + (9000.0 * _random.nextDouble());

      result.add({
        'label': dayKey,
        'amount': amount,
      });
    }

    return result;
  }

  // Get product distribution by category
  Future<List<Map<String, dynamic>>> getProductDistributionByCategory() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('products').get();

      // Count products by category
      Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String? ?? 'Uncategorized';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      // Convert to list format
      List<Map<String, dynamic>> result = [];
      categoryCounts.forEach((category, count) {
        result.add({
          'category': category,
          'count': count,
        });
      });

      // Sort by count (descending)
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return result;
    } catch (e) {
      return [];
    }
  }

  // Get sales data for a specific time period (months or days)
  Future<List<Map<String, dynamic>>> getSalesData({
    int months = 6,
    bool dailyData = false,
  }) async {
    try {
      // Get real order data from Firestore
      try {
        final QuerySnapshot snapshot =
            await _firestore.collection('orders').orderBy('orderDate').get();

        final now = DateTime.now();
        final DateTime startDate;

        // Determine the start date based on the requested time period
        if (dailyData) {
          // If daily data requested, start from the 1st day of the previous month
          final previousMonth = DateTime(now.year, now.month - 1, 1);
          startDate = previousMonth;
        } else {
          // If monthly data requested, go back 'months' months
          startDate = DateTime(now.year, now.month - months, 1);
        }

        // Prepare the data structure
        Map<String, double> salesData = {};

        if (dailyData) {
          // For daily data, initialize all days in the requested period
          final endDate =
              DateTime(now.year, now.month, 0); // Last day of previous month
          final daysInMonth = endDate.day;

          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(endDate.year, endDate.month, day);
            final key = _formatDayKey(date);
            salesData[key] = 0.0;
          }
        } else {
          // For monthly data, initialize the requested months
          for (int i = 0; i < months; i++) {
            final month = DateTime(now.year, now.month - i, 1);
            final key = _formatMonthKey(month);
            salesData[key] = 0.0;
          }
        }

        // Sum up the order prices by time period
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Extract date and price from the document
          DateTime orderDate;
          if (data['orderDate'] is Timestamp) {
            orderDate = (data['orderDate'] as Timestamp).toDate();
          } else {
            // Skip if no valid date
            continue;
          }

          // Skip orders before our start date
          if (orderDate.isBefore(startDate)) continue;

          // Extract price
          final price =
              (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;

          // Create the appropriate key for this date
          final key =
              dailyData ? _formatDayKey(orderDate) : _formatMonthKey(orderDate);

          // Add to the appropriate bucket if it exists
          if (salesData.containsKey(key)) {
            salesData[key] = salesData[key]! + price;
          }
        }

        // Convert to list of maps for the chart
        final List<Map<String, dynamic>> result = [];

        // Sort keys by date
        final sortedKeys = salesData.keys.toList()..sort();

        for (final key in sortedKeys) {
          if (dailyData) {
            // For daily data, extract day
            final parts = key.split('-');
            final day = int.parse(parts[2]);

            result.add({
              'month': day
                  .toString(), // Using "month" key for consistency with chart
              'sales': salesData[key] ?? 0.0,
            });
          } else {
            // For monthly data, extract month name
            final parts = key.split('-');
            int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final monthName = _getMonthName(month);

            result.add({
              'month': monthName,
              'sales': salesData[key] ?? 0.0,
            });
          }
        }

        return result;
      } catch (e) {
        return _generateSampleSalesData();
      }
    } catch (e) {
      throw Exception('Failed to get sales data: $e');
    }
  }

  // Helper method to format month key (YYYY-MM)
  String _formatMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Helper method to format day key (YYYY-MM-DD)
  String _formatDayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return monthNames[month - 1];
  }

  // Helper method to get month index for sorting
  int _getMonthIndex(String monthName) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return monthNames.indexOf(monthName);
  }

  // Get monthly orders data
  Future<List<Map<String, dynamic>>> getMonthlyOrdersData() async {
    try {
      // Get all orders sorted by date
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .orderBy('orderDate', descending: false)
          .get();

      // Process orders to get monthly data
      Map<String, int> monthlyOrders = {};

      // Current date for calculating last 12 months
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, now.month, 1);

      // Initialize all months with zero to ensure complete data
      for (int i = 0; i < 12; i++) {
        final month = DateTime(startDate.year, startDate.month + i, 1);
        final key = DateFormat('MMM yyyy').format(month);
        monthlyOrders[key] = 0;
      }

      // Count orders by month
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['orderDate'] != null) {
          // Convert Firestore timestamp to DateTime
          final DateTime orderDate;
          if (data['orderDate'] is Timestamp) {
            orderDate = (data['orderDate'] as Timestamp).toDate();
          } else if (data['orderDate'] is String) {
            // Try to parse string date
            try {
              orderDate = DateTime.parse(data['orderDate'] as String);
            } catch (e) {
              continue;
            }
          } else {
            continue;
          }

          // Only include orders in the last 12 months
          if (orderDate.isAfter(startDate)) {
            final String monthKey = DateFormat('MMM yyyy').format(orderDate);
            monthlyOrders[monthKey] = (monthlyOrders[monthKey] ?? 0) + 1;
          }
        }
      }

      // Convert to list format sorted by date
      List<Map<String, dynamic>> result = [];

      monthlyOrders.forEach((month, orders) {
        result.add({
          'month': month,
          'orders': orders,
        });
      });

      // Sort by date (month + year)
      result.sort((a, b) {
        final aDate = DateFormat('MMM yyyy').parse(a['month'] as String);
        final bDate = DateFormat('MMM yyyy').parse(b['month'] as String);
        return aDate.compareTo(bDate);
      });

      // If no real data was found, generate sample data for testing
      if (snapshot.docs.isEmpty ||
          result.every((element) => (element['orders'] as int) == 0)) {
        return _generateSampleOrdersData();
      }

      return result;
    } catch (e) {
      // Return sample data on error
      return _generateSampleOrdersData();
    }
  }

  // Generate sample order data for testing
  List<Map<String, dynamic>> _generateSampleOrdersData() {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    // Generate data for the last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(month);

      // Random orders between 10 and 100
      final orders = 10 + _random.nextInt(90);

      result.add({
        'month': monthKey,
        'orders': orders,
      });
    }

    return result;
  }

  // Get user growth data
  Future<List<Map<String, dynamic>>> getUserGrowthData() async {
    try {
      // Get all users sorted by creation date
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: false)
          .get();

      // Process users to get monthly growth data
      Map<String, int> monthlyNewUsers = {};
      Map<String, int> monthlyCumulativeUsers = {};

      // Current date for calculating last 12 months
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, now.month, 1);

      // Initialize all months with zero to ensure complete data
      for (int i = 0; i < 12; i++) {
        final month = DateTime(startDate.year, startDate.month + i, 1);
        final key = DateFormat('MMM yyyy').format(month);
        monthlyNewUsers[key] = 0;
      }

      // Count new users by month
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Try different field names for creation date
        DateTime? creationDate;
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            creationDate = (data['createdAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is String) {
            try {
              creationDate = DateTime.parse(data['createdAt'] as String);
            } catch (e) {
              // Ignore parsing errors
            }
          }
        } else if (data['created'] != null) {
          if (data['created'] is Timestamp) {
            creationDate = (data['created'] as Timestamp).toDate();
          } else if (data['created'] is String) {
            try {
              creationDate = DateTime.parse(data['created'] as String);
            } catch (e) {
              // Ignore parsing errors
            }
          }
        } else if (data['joinDate'] != null) {
          if (data['joinDate'] is Timestamp) {
            creationDate = (data['joinDate'] as Timestamp).toDate();
          } else if (data['joinDate'] is String) {
            try {
              creationDate = DateTime.parse(data['joinDate'] as String);
            } catch (e) {
              // Ignore parsing errors
            }
          }
        }

        if (creationDate != null) {
          // Only include users created in the last 12 months
          if (creationDate.isAfter(startDate)) {
            final String monthKey = DateFormat('MMM yyyy').format(creationDate);
            monthlyNewUsers[monthKey] = (monthlyNewUsers[monthKey] ?? 0) + 1;
          }
        }
      }

      // Calculate cumulative users
      int cumulativeCount = 0;
      List<String> sortedMonths = monthlyNewUsers.keys.toList()
        ..sort((a, b) {
          final aDate = DateFormat('MMM yyyy').parse(a);
          final bDate = DateFormat('MMM yyyy').parse(b);
          return aDate.compareTo(bDate);
        });

      for (var month in sortedMonths) {
        cumulativeCount += monthlyNewUsers[month] ?? 0;
        monthlyCumulativeUsers[month] = cumulativeCount;
      }

      // Convert to list format
      List<Map<String, dynamic>> result = [];

      for (var month in sortedMonths) {
        result.add({
          'month': month,
          'count': monthlyCumulativeUsers[month] ?? 0,
        });
      }

      // If no real data was found, generate sample data for testing
      if (snapshot.docs.isEmpty ||
          result.every((element) => (element['count'] as int) == 0)) {
        return _generateSampleUserGrowthData();
      }

      return result;
    } catch (e) {
      // Return sample data on error
      return _generateSampleUserGrowthData();
    }
  }

  // Generate sample user growth data for testing
  List<Map<String, dynamic>> _generateSampleUserGrowthData() {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    // Start with a base number of users
    int cumulativeUsers = 80 + _random.nextInt(100); // Between 80 and 179

    // Generate data for the last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(month);

      // Add between 5 and 30 new users each month
      final newUsers = 5 + _random.nextInt(25);
      cumulativeUsers += newUsers;

      result.add({
        'month': monthKey,
        'count': cumulativeUsers,
      });
    }

    return result;
  }
}
