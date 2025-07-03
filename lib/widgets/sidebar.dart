// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/routes.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_model.dart';
import '../helpers/route_helper.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  void initState() {
    super.initState();

    // Initialize notifications provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      if (authProvider.isAuthenticated && authProvider.userData != null) {
        notificationProvider.initNotifications(authProvider.userData!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final UserModel? userData = authProvider.userData;
    final bool isInDrawer = Scaffold.of(context).hasDrawer;

    return Container(
      width: isInDrawer ? null : 260,
      color: Colors.white,
      child: Column(
        children: [
          // Logo and title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chair,
                  size: 32,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.appName,
                      style: AppTextStyles.h4,
                    ),
                    Text(
                      'Admin Panel',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Dashboard
                  _hasPermission(userData, 'dashboard')
                      ? _buildNavItem(
                          context,
                          index: 0,
                          icon: Icons.dashboard,
                          title: AppStrings.dashboard,
                          route: AppRoutes.dashboard,
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 8),

                  // Products section heading - show if any child is visible
                  if (_hasPermission(userData, 'products') ||
                      _hasPermission(userData, 'categories') ||
                      _hasPermission(userData, 'promotions'))
                    _buildSectionHeading('INVENTORY'),

                  // Products
                  _hasPermission(userData, 'products')
                      ? _buildNavItem(
                          context,
                          index: 1,
                          icon: Icons.shopping_bag,
                          title: AppStrings.products,
                          route: AppRoutes.products,
                        )
                      : const SizedBox.shrink(),

                  // Promotions
                  _hasPermission(userData, 'promotions')
                      ? _buildNavItem(
                          context,
                          index: 9,
                          icon: Icons.local_offer,
                          title: 'Promotions',
                          route: AppRoutes.promotions,
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 8),

                  // Orders section heading
                  if (_hasPermission(userData, 'orders'))
                    _buildSectionHeading('ORDERS'),

                  // Orders
                  _hasPermission(userData, 'orders')
                      ? _buildNavItem(
                          context,
                          index: 3,
                          icon: Icons.shopping_cart,
                          title: AppStrings.orders,
                          route: AppRoutes.orders,
                          badgeCount: notificationProvider.pendingOrdersCount,
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 8),

                  // Users section heading
                  if (_hasPermission(userData, 'users') ||
                      _hasPermission(userData, 'managers'))
                    _buildSectionHeading('USERS'),

                  // Customers
                  _hasPermission(userData, 'users')
                      ? _buildUserNavItem(
                          context,
                          index: 4,
                          icon: Icons.people,
                          title: 'Users',
                        )
                      : const SizedBox.shrink(),

                  // Managers
                  _hasPermission(userData, 'managers')
                      ? _buildNavItem(
                          context,
                          index: 5,
                          icon: Icons.manage_accounts,
                          title: AppStrings.managers,
                          route: AppRoutes.managers,
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 8),

                  // Analytics section heading
                  if (_hasPermission(userData, 'analytics'))
                    _buildSectionHeading('ANALYTICS'),

                  // Analytics
                  _hasPermission(userData, 'analytics')
                      ? _buildNavItem(
                          context,
                          index: 6,
                          icon: Icons.bar_chart,
                          title: AppStrings.analytics,
                          route: AppRoutes.analytics,
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 8),

                  // Chat section heading
                  if (_hasPermission(userData, 'chats'))
                    _buildSectionHeading('COMMUNICATION'),

                  // Chats
                  _hasPermission(userData, 'chats')
                      ? Consumer<ChatProvider>(
                          builder: (context, chatProvider, child) {
                            return _buildNavItem(
                              context,
                              index: 10,
                              icon: Icons.chat_bubble_outline,
                              title: 'Chats',
                              route: AppRoutes.chats,
                              badgeCount: chatProvider.totalUnreadCount,
                            );
                          },
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 8),

                  // AI section heading
                  if (_hasPermission(userData, 'ai-interiors'))
                    _buildSectionHeading('AI TOOLS'),

                  // AI Interior Design
                  _hasPermission(userData, 'ai-interiors')
                      ? _buildNavItem(
                          context,
                          index: 7,
                          icon: Icons.auto_awesome,
                          title: AppStrings.aiInteriors,
                          route: AppRoutes.aiInteriors,
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 8),

                  // Settings section heading
                  if (_hasPermission(userData, 'settings'))
                    _buildSectionHeading('SETTINGS'),

                  // Settings
                  _hasPermission(userData, 'settings')
                      ? _buildNavItem(
                          context,
                          index: 8,
                          icon: Icons.settings,
                          title: AppStrings.settings,
                          route: AppRoutes.settings,
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // User section at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor,
                  backgroundImage: userData?.photoUrl != null
                      ? NetworkImage(userData!.photoUrl!)
                      : null,
                  child: userData?.photoUrl == null
                      ? Text(
                          userData?.name.isNotEmpty == true
                              ? userData!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData?.name ?? 'Guest User',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userData?.role.toUpperCase() ?? 'GUEST',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    size: 18,
                  ),
                  onPressed: () {
                    _showLogoutConfirmationDialog(context, authProvider);
                  },
                  tooltip: AppStrings.logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String route,
    int? badgeCount,
  }) {
    final isSelected = widget.selectedIndex == index;

    return InkWell(
      onTap: () {
        widget.onItemSelected(index);

        // Use RouteHelper for standard navigation
        RouteHelper.navigateTo(context, route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusXS),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = widget.selectedIndex == index;

    return InkWell(
      onTap: () {
        widget.onItemSelected(index);
        // Use standard navigation like other menu items
        Navigator.pushReplacementNamed(context, AppRoutes.users);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to check permissions based on role and specific permissions
  bool _hasPermission(UserModel? user, String permissionKey) {
    // Admin has all permissions
    if (user?.role == 'admin') {
      return true;
    }

    // Manager with specific permissions
    if (user?.role == 'manager' && user?.permissions != null) {
      return user!.permissions![permissionKey] ?? false;
    }

    // Staff can access only specific sections
    if (user?.role == 'staff') {
      // Define what staff can access
      const staffPermissions = {
        'dashboard': true,
        'products': true,
        'orders': true,
        'chats': true,
      };
      return staffPermissions[permissionKey] ?? false;
    }

    // Fallback for customers or unknown roles - no admin access
    return false;
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmationDialog(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                authProvider.signOut().then((_) {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                });
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
