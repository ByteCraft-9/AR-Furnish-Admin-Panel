import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import 'settings_card.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  bool _isDarkMode = false;
  bool _isCompactMode = false;
  bool _isHighContrastMode = false;
  bool _isReducedMotion = false;
  String _selectedFont = 'System Default';
  double _textSize = 1.0; // 1.0 is the default (medium)
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _fontOptions = [
    'System Default',
    'Poppins',
    'Roboto',
    'Open Sans',
    'Montserrat'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null) {
        // Get user preferences from Firestore
        final docRef = FirebaseFirestore.instance
            .collection('userPreferences')
            .doc(userData.id);

        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            setState(() {
              _isDarkMode = data['darkMode'] ?? false;
              _isCompactMode = data['compactMode'] ?? false;
              _isHighContrastMode = data['highContrastMode'] ?? false;
              _isReducedMotion = data['reducedMotion'] ?? false;
              _selectedFont = data['font'] ?? 'System Default';
              _textSize = data['textSize'] ?? 1.0;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: $e'),
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

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final UserModel? userData = authProvider.userData;

      if (userData != null) {
        // Save user preferences to Firestore
        await FirebaseFirestore.instance
            .collection('userPreferences')
            .doc(userData.id)
            .set({
          'darkMode': _isDarkMode,
          'compactMode': _isCompactMode,
          'highContrastMode': _isHighContrastMode,
          'reducedMotion': _isReducedMotion,
          'font': _selectedFont,
          'textSize': _textSize,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appearance settings saved'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
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
        // Theme options card
        SettingsCard(
          title: 'Theme Options',
          icon: Icons.palette,
          actions: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePreferences,
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
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dark Mode switch
              _buildSwitchOption(
                title: 'Dark Mode',
                subtitle: 'Use dark colors for the interface',
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
                icon: Icons.dark_mode,
              ),

              const Divider(),

              // Compact Mode switch
              _buildSwitchOption(
                title: 'Compact Mode',
                subtitle: 'Reduce padding and spacing in the UI',
                value: _isCompactMode,
                onChanged: (value) {
                  setState(() {
                    _isCompactMode = value;
                  });
                },
                icon: Icons.view_compact,
              ),

              const Divider(),

              // High Contrast switch
              _buildSwitchOption(
                title: 'High Contrast',
                subtitle: 'Increase contrast for better visibility',
                value: _isHighContrastMode,
                onChanged: (value) {
                  setState(() {
                    _isHighContrastMode = value;
                  });
                },
                icon: Icons.contrast,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Typography settings card
        SettingsCard(
          title: 'Typography',
          icon: Icons.text_fields,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Font dropdown
              _buildDropdownOption(
                title: 'Font',
                value: _selectedFont,
                options: _fontOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFont = value;
                    });
                  }
                },
                icon: Icons.font_download,
              ),

              const SizedBox(height: 16),

              // Text size slider
              _buildTextSizeOption(
                title: 'Text Size',
                value: _textSize,
                onChanged: (value) {
                  setState(() {
                    _textSize = value;
                  });
                },
                icon: Icons.format_size,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Accessibility settings card
        SettingsCard(
          title: 'Accessibility',
          icon: Icons.accessibility,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reduced motion switch
              _buildSwitchOption(
                title: 'Reduced Motion',
                subtitle: 'Minimize animations throughout the app',
                value: _isReducedMotion,
                onChanged: (value) {
                  setState(() {
                    _isReducedMotion = value;
                  });
                },
                icon: Icons.animation,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Preview card
        SettingsCard(
          title: 'Preview',
          icon: Icons.preview,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              border: Border.all(color: AppColors.borderColor),
            ),
            padding: EdgeInsets.all(_isCompactMode ? 8.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      color:
                          _isDarkMode ? Colors.white : AppColors.primaryColor,
                      size: 24 * _textSize,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 18 * _textSize,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode
                            ? Colors.white
                            : AppColors.textPrimaryColor,
                        fontFamily: _selectedFont == 'System Default'
                            ? null
                            : _selectedFont,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(_isCompactMode ? 8.0 : 16.0),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadiusM),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.grey.shade800
                            : AppColors.borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Overview',
                          style: TextStyle(
                            fontSize: 16 * _textSize,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode
                                ? Colors.white
                                : AppColors.textPrimaryColor,
                            fontFamily: _selectedFont == 'System Default'
                                ? null
                                : _selectedFont,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preview of how your content will look with these settings.',
                          style: TextStyle(
                            fontSize: 14 * _textSize,
                            color: _isDarkMode
                                ? Colors.grey.shade300
                                : AppColors.textSecondaryColor,
                            fontFamily: _selectedFont == 'System Default'
                                ? null
                                : _selectedFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
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
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: value,
                  items: options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: TextStyle(
                          fontFamily:
                              option == 'System Default' ? null : option,
                        ),
                      ),
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

  // Helper method to build text size slider
  Widget _buildTextSizeOption({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: _getTextSizeLabel(value),
                  onChanged: onChanged,
                  activeColor: AppColors.primaryColor,
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get text size label
  String _getTextSizeLabel(double value) {
    if (value <= 0.8) return 'Very Small';
    if (value <= 0.9) return 'Small';
    if (value <= 1.0) return 'Medium';
    if (value <= 1.1) return 'Large';
    if (value <= 1.2) return 'X-Large';
    if (value <= 1.3) return 'XX-Large';
    return 'XXX-Large';
  }
}
