// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import 'settings_card.dart';
import 'package:intl/intl.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    // Populate fields from user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateUserData();
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Populate text fields with user data
  void _populateUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final UserModel? userData = authProvider.userData;

    if (userData != null) {
      _nameController.text = userData.name;
      _emailController.text = userData.email;
      _phoneController.text = userData.phone ?? '';
      _addressController.text = userData.address ?? '';
    }
  }

  // Save profile changes
  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // In a real app, you would update user data here
        // For now, we're just simulating a network delay
        await Future.delayed(const Duration(seconds: 1));

        // Assuming authProvider has an updateProfile method
        // authProvider.updateProfile(
        //   name: _nameController.text,
        //   phone: _phoneController.text,
        //   address: _addressController.text,
        // );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }

        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? userData = authProvider.userData;

    return ListView(
      children: [
        // Profile Card
        SettingsCard(
          title: 'Profile Information',
          icon: Icons.person,
          actions: [
            _isEditing
                ? Row(
                    children: [
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isEditing = false;
                                  _populateUserData();
                                });
                              },
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    tooltip: 'Edit Profile',
                    color: AppColors.primaryColor,
                  ),
          ],
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar and role
                if (!_isEditing) ...[
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
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
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData?.name ?? 'User Name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userData?.role.toUpperCase() ?? 'ROLE',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],

                // Editable Fields
                // Name Field
                _buildFormField(
                  isReadOnly: !_isEditing,
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Field (non-editable)
                _buildFormField(
                  isReadOnly: true, // Email is typically not editable
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  validator: null, // No validation needed for read-only field
                ),

                const SizedBox(height: 16),

                // Phone Field
                _buildFormField(
                  isReadOnly: !_isEditing,
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  validator: (value) {
                    // Add phone validation if needed
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Address Field
                _buildFormField(
                  isReadOnly: !_isEditing,
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  validator: null,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Account Information Card
        SettingsCard(
          title: 'Account Information',
          icon: Icons.badge,
          child: Column(
            children: [
              _buildInfoRow('Account ID', userData?.id ?? 'N/A'),
              const Divider(),
              _buildInfoRow('Role', userData?.role ?? 'N/A'),
              const Divider(),
              _buildInfoRow(
                  'Account Created',
                  userData?.createdAt != null
                      ? _formatDateTime(userData!.createdAt)
                      : 'N/A'),
              const Divider(),
              _buildInfoRow(
                  'Last Updated',
                  userData?.updatedAt != null
                      ? _formatDateTime(userData!.updatedAt)
                      : 'N/A'),
              const Divider(),
              _buildInfoRow('Account Status',
                  userData?.isActive == true ? 'Active' : 'Inactive',
                  isHighlighted: userData?.isActive == true,
                  highlightColor: userData?.isActive == true
                      ? AppColors.successColor
                      : AppColors.errorColor),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build form fields
  Widget _buildFormField({
    required bool isReadOnly,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
        filled: true,
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlighted = false,
    Color highlightColor = AppColors.successColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    isHighlighted ? highlightColor : AppColors.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date time
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
  }
}
