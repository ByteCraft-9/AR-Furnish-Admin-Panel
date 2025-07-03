// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  bool _isUpdating = false;

  // Possible order statuses
  final List<String> _orderStatuses = [
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
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final orderData = await orderProvider.getOrderById(widget.orderId);
    setState(() {
      _orderData = orderData;
      _isLoading = false;
    });
  }

  Future<void> _updateOrderStatus(String status) async {
    setState(() => _isUpdating = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final success = await orderProvider.updateOrderStatus(
        widget.orderId, status,
        notificationProvider: notificationProvider);

    setState(() => _isUpdating = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrderDetails(); // Reload to show updated data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              orderProvider.errorMessage ?? 'Failed to update order status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(symbol: 'PKR ', decimalDigits: 2)
        .format(value);
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

    return DateFormat('MMM dd, yyyy, hh:mm a').format(dateTime);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Order Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_orderData != null && !_isLoading)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: _updateOrderStatus,
              itemBuilder: (context) {
                return _orderStatuses.map((status) {
                  return PopupMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _orderData == null
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Order not found',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12)),
                      child: const Text('Go Back'),
                    )
                  ],
                ))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderHeader(),
                          const SizedBox(height: 16),
                          _buildOrderItems(),
                          const SizedBox(height: 16),
                          _buildOrderSummary(),
                          const SizedBox(height: 16),
                          _buildShippingDetails(),
                          const SizedBox(
                              height: 80), // Space for bottom buttons
                        ],
                      ),
                    ),
                    if (_isUpdating)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
      bottomNavigationBar: _orderData == null || _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.1),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateOrderStatus('Cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final currentStatus =
                            _orderData!['status'] ?? 'Pending';
                        String nextStatus;

                        switch (currentStatus.toLowerCase()) {
                          case 'pending':
                            nextStatus = 'Confirmed';
                            break;
                          case 'confirmed':
                            nextStatus = 'Processing';
                            break;
                          case 'processing':
                            nextStatus = 'Shipped';
                            break;
                          case 'shipped':
                            nextStatus = 'Delivered';
                            break;
                          default:
                            nextStatus = 'Confirmed';
                        }

                        _updateOrderStatus(nextStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Process Order'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderHeader() {
    final status = _orderData!['status'] ?? 'Pending';
    final statusColor = _getStatusColor(status);
    final orderDate = _orderData!['orderDate'] ?? _orderData!['createdAt'];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${widget.orderId.substring(0, 8)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Placed on: ${_formatDate(orderDate)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
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
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(
              Icons.person_outline, 'Customer', _orderData!['userId'] ?? 'N/A'),
          _buildInfoRow(
              Icons.email_outlined, 'Email', _orderData!['userEmail'] ?? 'N/A'),
          _buildInfoRow(
              Icons.phone_outlined, 'Phone', _orderData!['userPhone'] ?? 'N/A'),
          _buildInfoRow(Icons.payment, 'Payment', _getPaymentMethodText()),
        ],
      ),
    );
  }

  String _getPaymentMethodText() {
    final paymentMethod = _orderData!['paymentMethod'];
    if (paymentMethod == null) return 'N/A';

    if (paymentMethod is Map) {
      final type = paymentMethod['type'] ?? 'N/A';
      if (type == 'card' && paymentMethod.containsKey('last4')) {
        return 'Card ending in ${paymentMethod['last4']}';
      }
      return type;
    }

    return paymentMethod.toString();
  }

  Widget _buildOrderItems() {
    final List<dynamic> items = _orderData!['items'] ?? [];
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemImage(item['image']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['productName'] ?? 'Unknown Product',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${item['quantity']} x ${_formatCurrency(item['price'] ?? 0)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(
                        (item['price'] ?? 0) * (item['quantity'] ?? 0)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'Subtotal', _formatCurrency(_orderData!['subtotal'] ?? 0)),
          _buildSummaryRow(
              'Shipping', _formatCurrency(_orderData!['shipping'] ?? 0)),
          _buildSummaryRow('Tax', _formatCurrency(_orderData!['tax'] ?? 0)),
          if (_orderData!.containsKey('discount') &&
              _orderData!['discount'] != null)
            _buildSummaryRow(
                'Discount', '-${_formatCurrency(_orderData!['discount'])}'),
          const Divider(height: 24),
          _buildSummaryRow('Total', _formatCurrency(_orderData!['total'] ?? 0),
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildShippingDetails() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shipping Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _orderData!['shippingAddress'] ??
                        'No shipping address provided',
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
                color: isBold ? AppColors.primaryColor : null,
              )),
        ],
      ),
    );
  }

  Widget _buildItemImage(dynamic url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url?.toString() ?? '',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child:
              Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
        ),
      ),
    );
  }
}
