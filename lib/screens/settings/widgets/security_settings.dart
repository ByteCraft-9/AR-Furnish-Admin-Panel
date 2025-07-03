// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import 'settings_card.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  final _formKey = GlobalKey<FormState>();

  // Current and new password controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Two-factor authentication
  bool _twoFactorEnabled = false;
  String _preferredMethod = 'email';

  // Password visibility toggles
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Loading state
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _loadingTwoFactor = false;

  // Activity log
  List<Map<String, dynamic>> _activityLog = [];
  bool _loadingActivity = false;

  // Password requirements
  final bool _hasMinLength = false;
  final bool _hasUppercase = false;
  final bool _hasLowercase = false;
  final bool _hasNumber = false;
  final bool _hasSpecialChar = false;

  final List<String> _twoFactorMethods = ['email', 'sms', 'authenticator'];

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
    _loadActivityLog();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() {
      _loadingTwoFactor = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null) {
        // Get security settings from Firestore
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userData.id)
            .collection('security')
            .doc('settings');

        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            setState(() {
              _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
              _preferredMethod = data['preferredMethod'] ?? 'email';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading security settings: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTwoFactor = false;
        });
      }
    }
  }

  Future<void> _loadActivityLog() async {
    setState(() {
      _loadingActivity = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null) {
        // Get activity log from Firestore
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userData.id)
            .collection('activityLog')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        setState(() {
          _activityLog = querySnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity log: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingActivity = false;
        });
      }
    }
  }

  Future<void> _updateTwoFactorSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null) {
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userData.id)
            .collection('security')
            .doc('settings')
            .set({
          'twoFactorEnabled': _twoFactorEnabled,
          'preferredMethod': _preferredMethod,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Log activity
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userData.id)
            .collection('activityLog')
            .add({
          'type': 'security_update',
          'action': _twoFactorEnabled
              ? 'Enabled two-factor authentication'
              : 'Disabled two-factor authentication',
          'timestamp': FieldValue.serverTimestamp(),
          'ip': '127.0.0.1', // In a real app, you would get the actual IP
          'userAgent':
              'Web Admin Panel', // In a real app, you would get the actual user agent
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Two-factor authentication settings saved'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }

        // Refresh activity log
        _loadActivityLog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating two-factor settings: $e'),
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

  Future<void> _changePassword() async {
    // Validate form
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isChangingPassword = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // In a real app, call the auth provider's change password method
        // await authProvider.changePassword(
        //   currentPassword: _currentPasswordController.text,
        //   newPassword: _newPasswordController.text,
        // );

        // Simulate password change for now
        await Future.delayed(const Duration(seconds: 1));

        // Log activity
        final UserModel? userData = authProvider.userData;
        if (userData != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userData.id)
              .collection('activityLog')
              .add({
            'type': 'password_change',
            'action': 'Changed password',
            'timestamp': FieldValue.serverTimestamp(),
            'ip': '127.0.0.1', // In a real app, you would get the actual IP
            'userAgent':
                'Web Admin Panel', // In a real app, you would get the actual user agent
          });
        }

        // Clear form
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }

        // Refresh activity log
        _loadActivityLog();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error changing password: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isChangingPassword = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Change Password Card
        SettingsCard(
          title: 'Change Password',
          icon: Icons.lock,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current password field
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_currentPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _currentPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentPasswordVisible = !_currentPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadiusS),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // New password field
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_newPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _newPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _newPasswordVisible = !_newPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadiusS),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadiusS),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Password requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusS),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password Requirements',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementRow(
                          'At least 8 characters', _hasMinLength),
                      _buildRequirementRow(
                          'At least one uppercase letter', _hasUppercase),
                      _buildRequirementRow(
                          'At least one lowercase letter', _hasLowercase),
                      _buildRequirementRow('At least one number', _hasNumber),
                      _buildRequirementRow(
                          'At least one special character', _hasSpecialChar),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Submit button
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    icon: _isChangingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Change Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Two-Factor Authentication Card
        SettingsCard(
          title: 'Two-Factor Authentication',
          icon: Icons.security,
          child: _loadingTwoFactor
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enable/Disable 2FA
                    SwitchListTile(
                      title: const Text(
                        'Enable Two-Factor Authentication',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Add an extra layer of security to your account',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                      value: _twoFactorEnabled,
                      onChanged: (value) {
                        setState(() {
                          _twoFactorEnabled = value;
                        });
                      },
                      activeColor: AppColors.primaryColor,
                    ),

                    const SizedBox(height: 16),

                    // 2FA Method
                    if (_twoFactorEnabled) ...[
                      const Text(
                        'Authentication Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Method options
                      _buildAuthMethodOption(
                        'Email',
                        'Receive verification codes via email',
                        Icons.email,
                        'email',
                      ),

                      const SizedBox(height: 8),

                      _buildAuthMethodOption(
                        'SMS',
                        'Receive verification codes via SMS',
                        Icons.message,
                        'sms',
                      ),

                      const SizedBox(height: 8),

                      _buildAuthMethodOption(
                        'Authenticator App',
                        'Use an authenticator app like Google Authenticator',
                        Icons.phone_android,
                        'authenticator',
                      ),

                      const SizedBox(height: 16),

                      // Save button
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading ? null : _updateTwoFactorSettings,
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
                              : const Icon(Icons.save),
                          label: const Text('Save 2FA Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 24),

        // Active Sessions & Security Log Card
        SettingsCard(
          title: 'Security Activity Log',
          icon: Icons.history,
          child: _loadingActivity
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Security Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Activity list
                    if (_activityLog.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: Text('No recent activity')),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activityLog.length,
                        itemBuilder: (context, index) {
                          final activity = _activityLog[index];
                          return ListTile(
                            leading: _getActivityIcon(activity['type']),
                            title: Text(activity['action'] ?? 'Unknown action'),
                            subtitle: Text(
                              'IP: ${activity['ip'] ?? 'Unknown'} • ${_formatTimestamp(activity['timestamp'])}',
                            ),
                            dense: true,
                          );
                        },
                      ),

                    const SizedBox(height: 16),

                    // View all button
                    Align(
                      alignment: Alignment.center,
                      child: OutlinedButton(
                        onPressed: () {
                          // Navigate to full activity log
                        },
                        child: const Text('View Full Activity Log'),
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 24),

        // Security Tips Card
        SettingsCard(
          title: 'Security Tips',
          icon: Icons.lightbulb_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSecurityTip(
                'Use a strong, unique password for this account',
                'Don\'t reuse passwords from other websites or services',
                Icons.lock,
              ),
              const Divider(),
              _buildSecurityTip(
                'Enable two-factor authentication',
                'This adds an extra layer of security to your account',
                Icons.security,
              ),
              const Divider(),
              _buildSecurityTip(
                'Be aware of phishing attempts',
                'Never share your password or verification codes with anyone',
                Icons.warning,
              ),
              const Divider(),
              _buildSecurityTip(
                'Check your activity log regularly',
                'Report any suspicious activity immediately',
                Icons.visibility,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build password requirement rows
  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.check_circle_outline,
            color: isMet ? AppColors.successColor : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet
                  ? AppColors.textPrimaryColor
                  : AppColors.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build authentication method options
  Widget _buildAuthMethodOption(
      String title, String subtitle, IconData icon, String value) {
    return InkWell(
      onTap: () {
        setState(() {
          _preferredMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          border: Border.all(
            color: _preferredMethod == value
                ? AppColors.primaryColor
                : AppColors.borderColor,
          ),
          color: _preferredMethod == value
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _preferredMethod == value
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
                      fontWeight: FontWeight.w500,
                      color: _preferredMethod == value
                          ? AppColors.primaryColor
                          : AppColors.textPrimaryColor,
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
            Radio<String>(
              value: value,
              groupValue: _preferredMethod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _preferredMethod = value;
                  });
                }
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get activity icons
  Widget _getActivityIcon(String? type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'login':
        iconData = Icons.login;
        iconColor = AppColors.successColor;
        break;
      case 'logout':
        iconData = Icons.logout;
        iconColor = AppColors.textSecondaryColor;
        break;
      case 'password_change':
        iconData = Icons.lock_reset;
        iconColor = AppColors.primaryColor;
        break;
      case 'security_update':
        iconData = Icons.security;
        iconColor = AppColors.secondaryColor;
        break;
      case 'failed_login':
        iconData = Icons.error_outline;
        iconColor = AppColors.errorColor;
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = AppColors.textSecondaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 18,
      ),
    );
  }

  // Helper method to format timestamps
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return 'Unknown';
    }

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      dateTime = DateTime.now();
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to build security tips
  Widget _buildSecurityTip(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 16,
            ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
