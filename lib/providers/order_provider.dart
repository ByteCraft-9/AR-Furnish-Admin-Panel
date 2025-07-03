import 'package:flutter/material.dart';
import '../services/order_service.dart';
import 'notification_provider.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all orders
  void loadOrders({NotificationProvider? notificationProvider}) {
    _setLoading(true);
    _clearError();

    _orderService.getOrders().listen(
      (orders) {
        _orders = orders;
        _setLoading(false);

        // Refresh the pending orders count if notificationProvider is provided
        notificationProvider?.refreshPendingOrdersCount();
      },
      onError: (e) {
        _setError('Failed to load orders: $e');
        _setLoading(false);
      },
    );
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    try {
      return await _orderService.getOrderById(id);
    } catch (e) {
      _setError('Failed to get order: $e');
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String id, String status,
      {NotificationProvider? notificationProvider}) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _orderService.updateOrderStatus(id, status);

      // Refresh the pending orders count if notificationProvider is provided
      if (success && notificationProvider != null) {
        notificationProvider.refreshPendingOrdersCount();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Failed to update order status: $e');
      _setLoading(false);
      return false;
    }
  }

  // Public method to set loading state (for use in UI)
  void setLoading(bool value) {
    _setLoading(value);
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
