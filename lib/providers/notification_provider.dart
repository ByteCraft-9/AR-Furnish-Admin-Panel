import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final OrderService _orderService = OrderService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  int _pendingOrdersCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Notification settings
  bool _orderNotificationsEnabled = true;
  bool _promotionNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get pendingOrdersCount => _pendingOrdersCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get orderNotificationsEnabled => _orderNotificationsEnabled;
  bool get promotionNotificationsEnabled => _promotionNotificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  NotificationService get notificationService => _notificationService;

  // Initialize notifications for a user
  void initNotifications(String userId) {
    _loadNotifications(userId);
    _loadPendingOrdersCount();
    _loadNotificationSettings(userId);
  }

  // Load notification settings
  Future<void> _loadNotificationSettings(String userId) async {
    try {
      final settings =
          await _notificationService.getNotificationSettings(userId);
      if (settings != null) {
        _orderNotificationsEnabled = settings['orderNotifications'] ?? true;
        _promotionNotificationsEnabled =
            settings['promotionNotifications'] ?? true;
        _soundEnabled = settings['soundEnabled'] ?? true;
        _vibrationEnabled = settings['vibrationEnabled'] ?? true;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load notification settings: $e');
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    required bool orderNotificationsEnabled,
    required bool promotionNotificationsEnabled,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    _orderNotificationsEnabled = orderNotificationsEnabled;
    _promotionNotificationsEnabled = promotionNotificationsEnabled;
    _soundEnabled = soundEnabled;
    _vibrationEnabled = vibrationEnabled;
    notifyListeners();
  }

  // Add a new notification
  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    required DateTime timestamp,
  }) async {
    try {
      // Only show notification if the relevant setting is enabled
      if ((type == 'order' && !_orderNotificationsEnabled) ||
          (type == 'promotion' && !_promotionNotificationsEnabled)) {
        return;
      }

      // Create a notification object
      final notification = NotificationModel(
        id: '', // ID will be set by Firebase
        userId: userId,
        title: title,
        message: message,
        isRead: false,
        type: type,
        timestamp: timestamp,
      );

      // Save to Firestore through the service
      await _notificationService.addNotification(notification);

      // Play sound/vibration if enabled
      if (_soundEnabled) {
        // In a real app, we would play a sound here
        // SoundService.playNotificationSound();
      }

      if (_vibrationEnabled) {
        // In a real app, we would vibrate here
        // HapticFeedback.mediumImpact();
      }

      // Refresh notifications
      _loadNotifications(userId);
    } catch (e) {
      _setError('Failed to add notification: $e');
    }
  }

  // Load all notifications for a user
  void _loadNotifications(String userId) {
    _setLoading(true);
    _clearError();

    _notificationService.getNotifications(userId).listen(
      (notifications) {
        _notifications = notifications;
        _updateUnreadCount(userId);
        _setLoading(false);
      },
      onError: (e) {
        _setError('Failed to load notifications: $e');
        _setLoading(false);
      },
    );
  }

  // Update unread count
  Future<void> _updateUnreadCount(String userId) async {
    _unreadCount = await _notificationService.getUnreadCount(userId);
    notifyListeners();
  }

  // Load pending orders count
  Future<void> _loadPendingOrdersCount() async {
    _pendingOrdersCount = await _orderService.getNewOrdersCount();
    notifyListeners();
  }

  // Refresh pending orders count
  Future<void> refreshPendingOrdersCount() async {
    await _loadPendingOrdersCount();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _updateUnreadCount(userId);
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.markAllAsRead(userId);
      await _updateUnreadCount(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
      _setLoading(false);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId, String userId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      await _updateUnreadCount(userId);

      // Remove from local list
      _notifications
          .removeWhere((notification) => notification.id == notificationId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete notification: $e');
    }
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
