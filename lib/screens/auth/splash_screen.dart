import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/routes.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Add a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Navigate based on authentication status
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.chair,
              size: 80,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              AppStrings.appName,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin Panel',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondaryColor,
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
