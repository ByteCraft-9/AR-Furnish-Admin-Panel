import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import 'settings_card.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  bool _isLoading = false;
  bool _isSaving = false;

  // System settings
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _enableAnalytics = true;
  int _maxFailedLoginAttempts = 5;
  int _sessionTimeout = 30;

  // Feature toggles
  bool _enablePromotions = true;
  bool _enableAIFeatures = true;
  bool _enableChatSupport = false;
  bool _enableReviews = true;

  // Admin users
  List<UserModel> _adminUsers = [];
  bool _loadingUsers = false;

  final List<int> _timeoutOptions = [15, 30, 60, 120, 240];
  final List<int> _loginAttemptsOptions = [3, 5, 7, 10];

  @override
  void initState() {
    super.initState();
    _loadAdminSettings();
    _loadAdminUsers();
  }

  Future<void> _loadAdminSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get global settings from Firestore
      final docRef =
          FirebaseFirestore.instance.collection('settings').doc('global');

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          setState(() {
            // System settings
            _maintenanceMode = data['maintenanceMode'] ?? false;
            _allowNewRegistrations = data['allowNewRegistrations'] ?? true;
            _enableAnalytics = data['enableAnalytics'] ?? true;
            _maxFailedLoginAttempts = data['maxFailedLoginAttempts'] ?? 5;
            _sessionTimeout = data['sessionTimeout'] ?? 30;

            // Feature toggles
            _enablePromotions = data['enablePromotions'] ?? true;
            _enableAIFeatures = data['enableAIFeatures'] ?? true;
            _enableChatSupport = data['enableChatSupport'] ?? false;
            _enableReviews = data['enableReviews'] ?? true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading admin settings: $e'),
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

  Future<void> _loadAdminUsers() async {
    setState(() {
      _loadingUsers = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      setState(() {
        _adminUsers = querySnapshot.docs
            .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading admin users: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingUsers = false;
        });
      }
    }
  }

  Future<void> _saveAdminSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null && userData.role == 'admin') {
        // Prepare settings map
        final Map<String, dynamic> settings = {
          // System settings
          'maintenanceMode': _maintenanceMode,
          'allowNewRegistrations': _allowNewRegistrations,
          'enableAnalytics': _enableAnalytics,
          'maxFailedLoginAttempts': _maxFailedLoginAttempts,
          'sessionTimeout': _sessionTimeout,

          // Feature toggles
          'enablePromotions': _enablePromotions,
          'enableAIFeatures': _enableAIFeatures,
          'enableChatSupport': _enableChatSupport,
          'enableReviews': _enableReviews,

          // Metadata
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': userData.id,
        };

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('global')
            .set(settings, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin settings saved successfully'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      } else {
        throw Exception('Unauthorized: Only admins can save these settings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving admin settings: $e'),
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
            onPressed: _isSaving ? null : _saveAdminSettings,
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
            label: const Text('Save Admin Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Maintenance Banner
        if (_maintenanceMode)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maintenance Mode is Active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Users will see a maintenance message when they try to log in.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // System settings card
        SettingsCard(
          title: 'System Settings',
          icon: Icons.settings_applications,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchOption(
                title: 'Maintenance Mode',
                subtitle: 'Temporarily disable access to the application',
                value: _maintenanceMode,
                onChanged: (value) {
                  setState(() {
                    _maintenanceMode = value;
                  });
                },
                icon: Icons.build,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Allow New Registrations',
                subtitle: 'Enable/disable new user registrations',
                value: _allowNewRegistrations,
                onChanged: (value) {
                  setState(() {
                    _allowNewRegistrations = value;
                  });
                },
                icon: Icons.person_add,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Enable Analytics',
                subtitle: 'Collect anonymous usage data for analytics',
                value: _enableAnalytics,
                onChanged: (value) {
                  setState(() {
                    _enableAnalytics = value;
                  });
                },
                icon: Icons.analytics,
              ),
              const Divider(),
              _buildDropdownOption(
                title: 'Max Failed Login Attempts',
                subtitle: 'Number of login attempts before temporary lockout',
                value: _maxFailedLoginAttempts,
                options: _loginAttemptsOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _maxFailedLoginAttempts = value;
                    });
                  }
                },
                icon: Icons.lock,
                labelBuilder: (value) => '$value attempts',
              ),
              const Divider(),
              _buildDropdownOption(
                title: 'Session Timeout',
                subtitle: 'Minutes before inactive users are logged out',
                value: _sessionTimeout,
                options: _timeoutOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sessionTimeout = value;
                    });
                  }
                },
                icon: Icons.timer,
                labelBuilder: (value) => '$value minutes',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Feature toggles card
        SettingsCard(
          title: 'Feature Toggles',
          icon: Icons.toggle_on,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchOption(
                title: 'Promotions',
                subtitle: 'Enable/disable promotions feature',
                value: _enablePromotions,
                onChanged: (value) {
                  setState(() {
                    _enablePromotions = value;
                  });
                },
                icon: Icons.local_offer,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'AI Features',
                subtitle: 'Enable/disable AI-powered features',
                value: _enableAIFeatures,
                onChanged: (value) {
                  setState(() {
                    _enableAIFeatures = value;
                  });
                },
                icon: Icons.auto_awesome,
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Chat Support',
                subtitle: 'Enable/disable chat support for users',
                value: _enableChatSupport,
                onChanged: (value) {
                  setState(() {
                    _enableChatSupport = value;
                  });
                },
                icon: Icons.chat,
                chipLabel: 'BETA',
              ),
              const Divider(),
              _buildSwitchOption(
                title: 'Product Reviews',
                subtitle: 'Enable/disable user reviews on products',
                value: _enableReviews,
                onChanged: (value) {
                  setState(() {
                    _enableReviews = value;
                  });
                },
                icon: Icons.star,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Admin Users card
        SettingsCard(
          title: 'Admin Users',
          icon: Icons.admin_panel_settings,
          child: Column(
            children: [
              // List of admin users
              if (_loadingUsers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_adminUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text('No admin users found')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _adminUsers.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = _adminUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: user.isActive
                          ? const Chip(
                              label: Text('Active'),
                              backgroundColor: AppColors.successColor,
                              labelStyle:
                                  TextStyle(color: Colors.white, fontSize: 12),
                              padding: EdgeInsets.zero,
                            )
                          : const Chip(
                              label: Text('Inactive'),
                              backgroundColor: Colors.grey,
                              labelStyle:
                                  TextStyle(color: Colors.white, fontSize: 12),
                              padding: EdgeInsets.zero,
                            ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Add admin button
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to add manager screen with admin role
                  Navigator.pushNamed(context, '/managers/add',
                      arguments: {'role': 'admin'});
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add New Admin'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Database actions card
        SettingsCard(
          title: 'Database Actions',
          icon: Icons.storage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionButton(
                title: 'Backup Database',
                subtitle: 'Create a backup of the database',
                icon: Icons.backup,
                onPressed: () {
                  _showBackupDialog();
                },
              ),
              const Divider(),
              _buildActionButton(
                title: 'Clean Up Database',
                subtitle: 'Remove obsolete and temporary data',
                icon: Icons.cleaning_services,
                onPressed: () {
                  _showCleanupDialog();
                },
              ),
              const Divider(),
              _buildActionButton(
                title: 'Export User Data',
                subtitle: 'Export user data to a CSV file',
                icon: Icons.download,
                onPressed: () {
                  _showExportDialog('users');
                },
              ),
              const Divider(),
              _buildActionButton(
                title: 'Export Product Data',
                subtitle: 'Export product data to a CSV file',
                icon: Icons.inventory_2,
                onPressed: () {
                  _showExportDialog('products');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build switch options
  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    String? chipLabel,
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
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (chipLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          chipLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
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
  Widget _buildDropdownOption<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    required String Function(T) labelBuilder,
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
                DropdownButtonFormField<T>(
                  value: value,
                  items: options.map((T option) {
                    return DropdownMenuItem<T>(
                      value: option,
                      child: Text(labelBuilder(option)),
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

  // Helper method to build action buttons
  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
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
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }

  // Confirmation dialogs
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Database'),
        content: const Text(
            'This will create a backup of the entire database. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database backup initiated'),
                  backgroundColor: AppColors.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Up Database'),
        content: const Text(
            'This will remove temporary and obsolete data from the database. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database cleanup initiated'),
                  backgroundColor: AppColors.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Clean Up'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(String dataType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export ${dataType.capitalize()} Data'),
        content: Text(
            'This will export all $dataType data to a CSV file. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$dataType export initiated'),
                  backgroundColor: AppColors.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}

// Helper extension
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
