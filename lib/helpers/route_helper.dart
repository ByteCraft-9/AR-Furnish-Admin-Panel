import 'package:flutter/material.dart';
import '../screens/users/users_screen.dart';
import '../constants/routes.dart';

class RouteHelper {
  // Special navigation method for problem routes
  static void navigateToUsers(BuildContext context) {
    // Navigate directly to the UsersScreen without using named routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const UsersScreen(),
        settings: const RouteSettings(
            name: AppRoutes.users), // Set route name explicitly
      ),
      (route) => false, // Remove all existing routes
    );
  }

  // General navigation method
  static void navigateTo(BuildContext context, String route) {
    // Special case for Users route
    if (route == AppRoutes.users) {
      navigateToUsers(context);
      return;
    }

    // Standard navigation for other routes
    Navigator.of(context).pushReplacementNamed(route);
  }
}
