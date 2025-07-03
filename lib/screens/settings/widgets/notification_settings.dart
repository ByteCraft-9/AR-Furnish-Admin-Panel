import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/user_model.dart';
import '../../../models/notification_model.dart';
import 'settings_card.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _isLoading = false;
  bool _isSaving = false;

  // App notifications
  bool _orderNotifications = true;
  bool _productUpdateNotifications = true;
  bool _promotionNotifications = true;
  bool _systemNotifications = true;

  // Email notifications
  bool _emailOrderNotifications = true;
  bool _emailNewProductNotifications = false;
  bool _emailPromotionNotifications = true;
  bool _emailNewsletterNotifications = false;

  // Push notification settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _notificationDisplayDuration = 5;

  final List<int> _durationOptions = [3, 5, 7, 10];

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null) {
        // Get notification preferences from Firestore
        final docRef = FirebaseFirestore.instance
            .collection('notificationPreferences')
            .doc(userData.id);

        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            setState(() {
              // App notifications
              _orderNotifications = data['orderNotifications'] ?? true;
              _productUpdateNotifications =
                  data['productUpdateNotifications'] ?? true;
              _promotionNotifications = data['promotionNotifications'] ?? true;
              _systemNotifications = data['systemNotifications'] ?? true;

              // Email notifications
              _emailOrderNotifications =
                  data['emailOrderNotifications'] ?? true;
              _emailNewProductNotifications =
                  data['emailNewProductNotifications'] ?? false;
              _emailPromotionNotifications =
                  data['emailPromotionNotifications'] ?? true;
              _emailNewsletterNotifications =
                  data['emailNewsletterNotifications'] ?? false;

              // Push notification settings
              _soundEnabled = data['soundEnabled'] ?? true;
              _vibrationEnabled = data['vibrationEnabled'] ?? true;
              _notificationDisplayDuration =
                  data['notificationDisplayDuration'] ?? 5;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notification preferences: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null) {
        // Create settings map
        final Map<String, dynamic> settings = {
          // App notifications
          'orderNotifications': _orderNotifications,
          'productUpdateNotifications': _productUpdateNotifications,
          'promotionNotifications': _promotionNotifications,
          'systemNotifications': _systemNotifications,

          // Email notifications
          'emailOrderNotifications': _emailOrderNotifications,
          'emailNewProductNotifications': _emailNewProductNotifications,
          'emailPromotionNotifications': _emailPromotionNotifications,
          'emailNewsletterNotifications': _emailNewsletterNotifications,

          // Push notification settings
          'soundEnabled': _soundEnabled,
          'vibrationEnabled': _vibrationEnabled,
          'notificationDisplayDuration': _notificationDisplayDuration,

          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Save notification preferences to Firestore through service
        await notificationProvider.notificationService
            .saveNotificationSettings(userData.id, settings);

        // Update notification provider settings
        notificationProvider.updateNotificationSettings(
          orderNotificationsEnabled: _orderNotifications,
          promotionNotificationsEnabled: _promotionNotifications,
          soundEnabled: _soundEnabled,
          vibrationEnabled: _vibrationEnabled,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification settings saved'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving notification preferences: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        // Save button at the top
        Align(
          alignment: Alignment.topRight,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveNotificationPreferences,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, size: 18),
            label: const Text('Save All Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // In-app notifications card
        SettingsCard(
          title: 'App Notifications',
          icon: Icons.notifications_active,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchOption(
                title: 'Order Updates',
                subtitle: 'Notifications about your orders and their status',
                value: _orderNotifications,
                onChanged: (value) {
                  setState(() {
                    _orderNotifications = value;
                  });
                },
                icon: Icons.shopping_cart,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Product Updates',
                subtitle:
                    'Notifications about inventory changes and product updates',
                value: _productUpdateNotifications,
                onChanged: (value) {
                  setState(() {
                    _productUpdateNotifications = value;
                  });
                },
                icon: Icons.inventory,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Promotions',
                subtitle:
                    'Notifications about sales, discounts and special offers',
                value: _promotionNotifications,
                onChanged: (value) {
                  setState(() {
                    _promotionNotifications = value;
                  });
                },
                icon: Icons.local_offer,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'System Updates',
                subtitle: 'Important system announcements and updates',
                value: _systemNotifications,
                onChanged: (value) {
                  setState(() {
                    _systemNotifications = value;
                  });
                },
                icon: Icons.system_update,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Email notifications card
        SettingsCard(
          title: 'Email Notifications',
          icon: Icons.email,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchOption(
                title: 'Order Confirmations',
                subtitle: 'Receive order confirmations and updates via email',
                value: _emailOrderNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailOrderNotifications = value;
                  });
                },
                icon: Icons.receipt_long,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'New Products',
                subtitle: 'Receive emails about new product releases',
                value: _emailNewProductNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNewProductNotifications = value;
                  });
                },
                icon: Icons.new_releases,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Promotions and Offers',
                subtitle: 'Receive emails about discounts and special offers',
                value: _emailPromotionNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailPromotionNotifications = value;
                  });
                },
                icon: Icons.discount,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Newsletter',
                subtitle: 'Receive monthly newsletter with tips and updates',
                value: _emailNewsletterNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNewsletterNotifications = value;
                  });
                },
                icon: Icons.mail_outline,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Push notification settings card
        SettingsCard(
          title: 'Notification Behavior',
          icon: Icons.settings_applications,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchOption(
                title: 'Sound',
                subtitle: 'Play sound when notifications arrive',
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                },
                icon: Icons.volume_up,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Vibration',
                subtitle: 'Vibrate when notifications arrive',
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                },
                icon: Icons.vibration,
              ),
              const Divider(),
              _buildDropdownOption(
                title: 'Display Duration',
                subtitle: 'How long notifications stay on screen',
                value: _notificationDisplayDuration,
                options: _durationOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _notificationDisplayDuration = value;
                    });
                  }
                },
                icon: Icons.timer,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Test notification button
        SettingsCard(
          title: 'Test Notifications',
          icon: Icons.send,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.notifications),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userData == null) {
        throw Exception('User not logged in');
      }

      // Create a test notification model
      final notification = NotificationModel(
        id: '', // ID will be set by Firestore
        userId: authProvider.userData!.id,
        title: 'Test Notification',
        message:
            'This is a test notification from settings. Your current settings: Sound: $_soundEnabled, Vibration: $_vibrationEnabled',
        isRead: false,
        type: 'test',
        timestamp: DateTime.now(),
      );

      // Add notification using the service
      await notificationProvider.notificationService
          .addNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // Helper method to build switch options
  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  // Helper method to build dropdown options
  Widget _buildDropdownOption({
    required String title,
    required String subtitle,
    required int value,
    required List<int> options,
    required ValueChanged<int?> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: value,
                  items: options.map((int option) {
                    return DropdownMenuItem<int>(
                      value: option,
                      child: Text('$option seconds'),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadiusS),
                      borderSide:
                          const BorderSide(color: AppColors.borderColor),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
