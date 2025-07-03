import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

class SettingsCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? padding;

  const SettingsCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primaryColor),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, thickness: 1),

          // Content
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
