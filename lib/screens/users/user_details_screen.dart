// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import 'add_edit_user_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _isLoading = true;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = await userProvider.getUserById(widget.userId);

    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  void _navigateToEditUser() {
    if (_userData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditUserScreen(user: _userData),
      ),
    ).then((_) => _loadUserData()); // Refresh after returning
  }

  void _showDeleteConfirmation() {
    if (_userData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${_userData!.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuspendConfirmation() {
    if (_userData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_userData!.isActive ? 'Suspend User' : 'Activate User'),
        content: Text(_userData!.isActive
            ? 'Are you sure you want to suspend ${_userData!.name}? They will not be able to access the system until reactivated.'
            : 'Are you sure you want to reactivate ${_userData!.name}? They will regain access to the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleUserStatus();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    _userData!.isActive ? Colors.orange : Colors.green),
            child: Text(_userData!.isActive ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    if (_userData == null) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.deleteUser(_userData!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
      Navigator.pop(context); // Return to users list
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleUserStatus() async {
    if (_userData == null) return;
    final newStatus = !_userData!.isActive;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // Create a copy of the user with the updated status
      final updatedUser = _userData!.copyWith(isActive: newStatus);
      userProvider.toggleUserStatus(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'User activated successfully'
              : 'User suspended successfully'),
        ),
      );
      _loadUserData(); // Refresh the data
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_userData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditUser,
              tooltip: 'Edit User',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? _buildUserNotFound()
              : _buildUserDetails(),
      bottomNavigationBar: _userData == null
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete User'),
                        onPressed: _showDeleteConfirmation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(_userData!.isActive
                            ? Icons.block
                            : Icons.check_circle),
                        label: Text(_userData!.isActive
                            ? 'Suspend User'
                            : 'Activate User'),
                        onPressed: _showSuspendConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _userData!.isActive
                              ? Colors.orange
                              : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'User Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The requested user could not be found.',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildContactInformation(),
          const SizedBox(height: 24),
          _buildAccountInformation(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildUserAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userData!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData!.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleBadge(),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.primaryColor,
      backgroundImage: _userData!.photoUrl != null
          ? NetworkImage(_userData!.photoUrl!)
          : null,
      child: _userData!.photoUrl == null
          ? Text(
              _userData!.name.isNotEmpty
                  ? _userData!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildRoleBadge() {
    final Map<String, Color> roleColors = {
      'admin': Colors.red,
      'manager': Colors.purple,
      'staff': Colors.blue,
      'customer': Colors.green,
    };

    final role = _userData!.role.toLowerCase();
    final color = roleColors[role] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            role[0].toUpperCase() + role.substring(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _userData!.isActive ? Colors.green : Colors.red;
    final text = _userData!.isActive ? 'Active' : 'Suspended';
    final icon = _userData!.isActive ? Icons.check_circle : Icons.block;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInformation() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.email,
              title: 'Email',
              value: _userData!.email,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.phone,
              title: 'Phone',
              value: _userData!.phone ?? 'Not provided',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Address',
              value: _userData!.address ?? 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInformation() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.fingerprint,
              title: 'User ID',
              value: _userData!.id,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.calendar_today,
              title: 'Created On',
              value: _formatDate(_userData!.createdAt),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.update,
              title: 'Last Updated',
              value: _formatDate(_userData!.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
