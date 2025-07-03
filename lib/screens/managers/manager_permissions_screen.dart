// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class ManagerPermissionsScreen extends StatefulWidget {
  final UserModel manager;

  const ManagerPermissionsScreen({
    super.key,
    required this.manager,
  });

  @override
  _ManagerPermissionsScreenState createState() =>
      _ManagerPermissionsScreenState();
}

class _ManagerPermissionsScreenState extends State<ManagerPermissionsScreen> {
  bool _isLoading = false;
  Map<String, bool> _permissions = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final permissions =
          await userProvider.getUserPermissions(widget.manager.id);

      setState(() {
        if (permissions != null) {
          _permissions = permissions;
        } else {
          // Set default permissions if none exist
          _permissions = userProvider.getDefaultPermissions();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load permissions: $e')),
      );
    }
  }

  Future<void> _savePermissions() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.updateUserPermissions(
          widget.manager.id, _permissions);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to update permissions: ${userProvider.errorMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update permissions: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Permissions: ${widget.manager.name}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryColor,
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _savePermissions,
            icon: Icon(_isLoading ? Icons.hourglass_top : Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
      body: _isLoading && _permissions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildPermissionsForm(),
    );
  }

  Widget _buildPermissionsForm() {
    // Define sidebar sections and items
    final sidebarSections = [
      {
        'title': 'DASHBOARD',
        'items': [
          {'key': 'dashboard', 'title': 'Dashboard', 'icon': Icons.dashboard},
        ],
      },
      {
        'title': 'INVENTORY',
        'items': [
          {'key': 'products', 'title': 'Products', 'icon': Icons.shopping_bag},
          {'key': 'categories', 'title': 'Categories', 'icon': Icons.category},
          {
            'key': 'promotions',
            'title': 'Promotions',
            'icon': Icons.local_offer
          },
        ],
      },
      {
        'title': 'ORDERS',
        'items': [
          {'key': 'orders', 'title': 'Orders', 'icon': Icons.shopping_cart},
        ],
      },
      {
        'title': 'USERS',
        'items': [
          {'key': 'users', 'title': 'Users', 'icon': Icons.people},
          {
            'key': 'managers',
            'title': 'Managers',
            'icon': Icons.manage_accounts
          },
        ],
      },
      {
        'title': 'ANALYTICS',
        'items': [
          {'key': 'analytics', 'title': 'Analytics', 'icon': Icons.bar_chart},
        ],
      },
      {
        'title': 'AI TOOLS',
        'items': [
          {
            'key': 'ai-interiors',
            'title': 'AI Interiors',
            'icon': Icons.auto_awesome
          },
        ],
      },
      {
        'title': 'SETTINGS',
        'items': [
          {'key': 'settings', 'title': 'Settings', 'icon': Icons.settings},
        ],
      },
    ];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information card about the manager
            Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryColor,
                      backgroundImage: widget.manager.photoUrl != null
                          ? NetworkImage(widget.manager.photoUrl!)
                          : null,
                      child: widget.manager.photoUrl == null
                          ? Text(
                              widget.manager.name.isNotEmpty
                                  ? widget.manager.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.manager.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.manager.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRoleBadge(widget.manager.role),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Permissions section
            Text(
              'Manage Access Permissions',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Control which sections of the admin panel this manager can access.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (final section in sidebarSections) {
                        for (final item in section['items'] as List) {
                          _permissions[item['key'] as String] = true;
                        }
                      }
                    });
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Allow All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (final section in sidebarSections) {
                        for (final item in section['items'] as List) {
                          _permissions[item['key'] as String] = false;
                        }
                      }
                    });
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Deny All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Permission items by section
            ...sidebarSections.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section heading
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      section['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  // Section items
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: (section['items'] as List).map((item) {
                        final key = item['key'] as String;
                        final title = item['title'] as String;
                        final icon = item['icon'] as IconData;

                        // Initialize permission if not set
                        _permissions[key] ??= false;

                        return SwitchListTile(
                          title: Row(
                            children: [
                              Icon(icon,
                                  size: 20, color: AppColors.primaryColor),
                              const SizedBox(width: 16),
                              Text(title),
                            ],
                          ),
                          value: _permissions[key] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _permissions[key] = value;
                            });
                          },
                          activeColor: AppColors.primaryColor,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePermissions,
                icon: Icon(_isLoading ? Icons.hourglass_top : Icons.save),
                label: Text(
                    _isLoading ? 'Saving permissions...' : 'Save Permissions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final Map<String, Color> roleColors = {
      'admin': Colors.red,
      'manager': Colors.purple,
      'staff': Colors.blue,
      'customer': Colors.green,
    };

    final color = roleColors[role.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
