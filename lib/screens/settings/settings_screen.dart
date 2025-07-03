import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import './widgets/profile_settings.dart';
import './widgets/appearance_settings.dart';
import './widgets/notification_settings.dart';
import './widgets/admin_settings.dart';
import './widgets/security_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentSection = 'profile';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? userData = authProvider.userData;
    final bool isAdmin = userData?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.primaryColor),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.dashboard);
                  },
                  tooltip: 'Back to Dashboard',
                ),
                const Icon(Icons.settings,
                    size: 32, color: AppColors.primaryColor),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.settings, style: AppTextStyles.h1),
                    Text(
                      'Manage your account and application preferences',
                      style: TextStyle(color: AppColors.textSecondaryColor),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Main content with sidebar and content area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left sidebar for settings navigation
                  SizedBox(
                    width: 260,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Profile settings option
                          _buildSettingsNavItem(
                            icon: Icons.person,
                            title: 'Profile Settings',
                            subtitle: 'Manage your personal information',
                            isSelected: _currentSection == 'profile',
                            onTap: () =>
                                setState(() => _currentSection = 'profile'),
                          ),

                          const SizedBox(height: 12),

                          // App settings option
                          _buildSettingsNavItem(
                            icon: Icons.style,
                            title: 'App Appearance',
                            subtitle: 'Customize app theme and layout',
                            isSelected: _currentSection == 'appearance',
                            onTap: () =>
                                setState(() => _currentSection = 'appearance'),
                          ),

                          const SizedBox(height: 12),

                          // Notification settings option
                          _buildSettingsNavItem(
                            icon: Icons.notifications,
                            title: 'Notification Settings',
                            subtitle: 'Manage app and email notifications',
                            isSelected: _currentSection == 'notifications',
                            onTap: () => setState(
                                () => _currentSection = 'notifications'),
                          ),

                          // Only show admin settings for admin users
                          if (isAdmin) ...[
                            const SizedBox(height: 12),

                            // Admin settings option
                            _buildSettingsNavItem(
                              icon: Icons.admin_panel_settings,
                              title: 'Admin Settings',
                              subtitle: 'Configure global app settings',
                              isSelected: _currentSection == 'admin',
                              onTap: () =>
                                  setState(() => _currentSection = 'admin'),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Security settings option
                          _buildSettingsNavItem(
                            icon: Icons.security,
                            title: 'Security',
                            subtitle: 'Password and authentication settings',
                            isSelected: _currentSection == 'security',
                            onTap: () =>
                                setState(() => _currentSection = 'security'),
                          ),

                          const SizedBox(height: 24),

                          // System information
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadiusM),
                              border: Border.all(color: AppColors.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        size: 16,
                                        color: AppColors.textSecondaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'System Information',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const _InfoItem(
                                    label: 'App Version', value: '1.0.0'),
                                const _InfoItem(
                                    label: 'Last Update',
                                    value: 'Apr 11, 2025'),
                                const _InfoItem(
                                    label: 'Server Status',
                                    value: 'Online',
                                    isHighlighted: true),
                              ],
                            ),
                          ),

                          // Quick access buttons for specific settings screens
                          if (isAdmin) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, AppRoutes.adminSettings);
                              },
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text('Open Admin Settings Directly'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.securitySettings);
                            },
                            icon: const Icon(Icons.security),
                            label:
                                const Text('Open Security Settings Directly'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 32),

                  // Right content area
                  Expanded(
                    child: _buildSettingsContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build settings navigation items
  Widget _buildSettingsNavItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor.withOpacity(0.3)
                : AppColors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textSecondaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.keyboard_arrow_right,
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  // Method to return the appropriate content based on selected section
  Widget _buildSettingsContent() {
    switch (_currentSection) {
      case 'profile':
        return const ProfileSettings();
      case 'appearance':
        return const AppearanceSettings();
      case 'notifications':
        return const NotificationSettings();
      case 'admin':
        return const AdminSettings();
      case 'security':
        return const SecuritySettings();
      default:
        return const SizedBox.shrink();
    }
  }
}

// Helper widget for system information items
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _InfoItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted
                  ? AppColors.successColor
                  : AppColors.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
