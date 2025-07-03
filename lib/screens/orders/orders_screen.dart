// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/sidebar.dart';
import 'order_details_screen.dart';
import '../../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _selectedIndex = 3; // Change based on sidebar position for Orders
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      Provider.of<OrderProvider>(context, listen: false)
          .loadOrders(notificationProvider: notificationProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _viewOrderDetails(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: orderId),
      ),
    ).then((_) {
      // Refresh orders when returning from details screen
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      Provider.of<OrderProvider>(context, listen: false)
          .loadOrders(notificationProvider: notificationProvider);
    });
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final success = await orderProvider.updateOrderStatus(orderId, status,
        notificationProvider: notificationProvider);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $status'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      orderProvider.loadOrders(
          notificationProvider: notificationProvider); // Refresh orders list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              orderProvider.errorMessage ?? 'Failed to update order status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      symbol: 'PKR ',
      decimalDigits: 2,
    ).format(value);
  }

  // Format date from Timestamp or DateTime
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is Map && date.containsKey('seconds')) {
      // Convert Firestore timestamp
      dateTime = DateTime.fromMillisecondsSinceEpoch(date['seconds'] * 1000);
    } else {
      return 'N/A';
    }

    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  // Get color based on order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Filter orders by status
  List<Map<String, dynamic>> _filterOrdersByStatus(
      List<Map<String, dynamic>> orders) {
    if (_selectedStatusFilter == 'All') {
      return orders;
    }

    return orders.where((order) {
      final status = order['status'] as String? ?? 'Pending';
      return status.toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();
  }

  // Filter orders by search text
  List<Map<String, dynamic>> _filterOrdersBySearch(
      List<Map<String, dynamic>> orders, String query) {
    if (query.isEmpty) {
      return orders;
    }

    return orders.where((order) {
      final orderId = order['id'] as String? ?? '';
      final userId = order['userId'] as String? ?? '';
      final userEmail = order['userEmail'] as String? ?? '';

      return orderId.toLowerCase().contains(query.toLowerCase()) ||
          userId.toLowerCase().contains(query.toLowerCase()) ||
          userEmail.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final orderProvider = Provider.of<OrderProvider>(context);
    var orders = orderProvider.orders;

    // Apply filters
    orders = _filterOrdersByStatus(orders);
    orders = _filterOrdersBySearch(orders, _searchController.text);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar for large screens
          if (!isMobile)
            Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                // Handle sidebar navigation
              },
            ),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (isMobile) const SizedBox(width: 8),
                          const Text(
                            AppStrings.orders,
                            style: TextStyle(
                              color: AppColors.textPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: isMobile ? 150 : 250,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search orders...',
                                prefixIcon: Icon(Icons.search, size: 18),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh',
                            onPressed: () {
                              final notificationProvider =
                                  Provider.of<NotificationProvider>(context,
                                      listen: false);
                              Provider.of<OrderProvider>(context, listen: false)
                                  .loadOrders(
                                      notificationProvider:
                                          notificationProvider);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statusFilters
                              .map((status) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(status),
                                      selected: _selectedStatusFilter == status,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedStatusFilter = status;
                                        });
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: status == 'All'
                                          ? AppColors.primaryColor
                                              .withOpacity(0.1)
                                          : _getStatusColor(status)
                                              .withOpacity(0.1),
                                      checkmarkColor: status == 'All'
                                          ? AppColors.primaryColor
                                          : _getStatusColor(status),
                                      labelStyle: TextStyle(
                                        color: _selectedStatusFilter == status
                                            ? (status == 'All'
                                                ? AppColors.primaryColor
                                                : _getStatusColor(status))
                                            : AppColors.textPrimaryColor,
                                        fontWeight:
                                            _selectedStatusFilter == status
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Orders content
                Expanded(
                  child: orderProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      : orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No orders found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchController.text.isNotEmpty ||
                                            _selectedStatusFilter != 'All'
                                        ? 'Try adjusting your filters'
                                        : 'Orders will appear here once customers place them',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_searchController.text.isNotEmpty ||
                                      _selectedStatusFilter != 'All')
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _selectedStatusFilter = 'All';
                                        });
                                      },
                                      icon: const Icon(Icons.filter_alt_off),
                                      label: const Text('Clear Filters'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                      ),
                                    ),
                                  if (_searchController.text.isEmpty &&
                                      _selectedStatusFilter == 'All')
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final orderProvider =
                                            Provider.of<OrderProvider>(context,
                                                listen: false);
                                        final orderService = OrderService();

                                        // Show loading indicator
                                        setState(() =>
                                            orderProvider.setLoading(true));

                                        // Create sample orders
                                        await orderService.createSampleOrders();

                                        // Refresh orders
                                        final notificationProvider =
                                            Provider.of<NotificationProvider>(
                                                context,
                                                listen: false);
                                        orderProvider.loadOrders(
                                            notificationProvider:
                                                notificationProvider);
                                      },
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: const Text('Create Sample Orders'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : isMobile
                              ? _buildMobileOrdersList(orders)
                              : Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildOrdersTable(orders),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOrdersList(List<Map<String, dynamic>> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final List<dynamic> items = order['items'] ?? [];
        final status = order['status'] as String? ?? 'Pending';
        final statusColor = _getStatusColor(status);
        final orderDate = order['orderDate'] ?? order['createdAt'];

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _viewOrderDetails(order['id']),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            order['userId'] ?? 'N/A',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(orderDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(order['total'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => _viewOrderDetails(order['id']),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      status != 'Delivered' && status != 'Cancelled'
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (String newStatus) {
                                _updateOrderStatus(order['id'], newStatus);
                              },
                              itemBuilder: (context) {
                                // Determine next logical statuses
                                List<String> nextStatuses = [];
                                switch (status.toLowerCase()) {
                                  case 'pending':
                                    nextStatuses = ['Confirmed', 'Cancelled'];
                                    break;
                                  case 'confirmed':
                                    nextStatuses = ['Processing', 'Cancelled'];
                                    break;
                                  case 'processing':
                                    nextStatuses = ['Shipped', 'Cancelled'];
                                    break;
                                  case 'shipped':
                                    nextStatuses = ['Delivered', 'Cancelled'];
                                    break;
                                  default:
                                    nextStatuses = ['Confirmed', 'Cancelled'];
                                }

                                return nextStatuses
                                    .map((s) => PopupMenuItem<String>(
                                          value: s,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(s),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text('Mark as $s'),
                                            ],
                                          ),
                                        ))
                                    .toList();
                              },
                            )
                          : const SizedBox(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTable(List<Map<String, dynamic>> orders) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width -
                (MediaQuery.of(context).size.width < 800 ? 32 : 260 + 32),
          ),
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(
              Colors.grey[100],
            ),
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(
                label: Text(
                  'Order ID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Customer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: orders.map((order) {
              final List<dynamic> items = order['items'] ?? [];
              final status = order['status'] as String? ?? 'Pending';
              final statusColor = _getStatusColor(status);
              final orderDate = order['orderDate'] ?? order['createdAt'];

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    onTap: () => _viewOrderDetails(order['id']),
                  ),
                  DataCell(
                    Text(_formatDate(orderDate)),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          order['userId'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (order['userEmail'] != null)
                          Text(
                            order['userEmail'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                        '${items.length} ${items.length == 1 ? 'item' : 'items'}'),
                  ),
                  DataCell(
                    Text(
                      _formatCurrency(order['total'] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: () => _viewOrderDetails(order['id']),
                          tooltip: 'View Details',
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          splashRadius: 24,
                        ),
                        if (status != 'Delivered' && status != 'Cancelled')
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey[700],
                            ),
                            onSelected: (String newStatus) {
                              _updateOrderStatus(order['id'], newStatus);
                            },
                            itemBuilder: (context) {
                              // Determine next logical statuses
                              List<String> nextStatuses = [];
                              switch (status.toLowerCase()) {
                                case 'pending':
                                  nextStatuses = ['Confirmed', 'Cancelled'];
                                  break;
                                case 'confirmed':
                                  nextStatuses = ['Processing', 'Cancelled'];
                                  break;
                                case 'processing':
                                  nextStatuses = ['Shipped', 'Cancelled'];
                                  break;
                                case 'shipped':
                                  nextStatuses = ['Delivered', 'Cancelled'];
                                  break;
                                default:
                                  nextStatuses = ['Confirmed', 'Cancelled'];
                              }

                              return nextStatuses
                                  .map((s) => PopupMenuItem<String>(
                                        value: s,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(s),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('Mark as $s'),
                                          ],
                                        ),
                                      ))
                                  .toList();
                            },
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            splashRadius: 24,
                            tooltip: 'Update Status',
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
