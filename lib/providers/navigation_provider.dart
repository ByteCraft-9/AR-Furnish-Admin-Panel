import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../screens/users/users_screen.dart';

class NavigationProvider extends ChangeNotifier {
  // Track the current active route
  String _currentRoute = '/';

  // Get the current route
  String get currentRoute => _currentRoute;

  // Navigate to a specific route
  Future<void> navigateTo(BuildContext context, String route) async {
    // Update the current route
    _currentRoute = route;
    notifyListeners();

    // Special handling for users route which has issues with named navigation
    if (route == AppRoutes.users) {
      // Use explicit MaterialPageRoute for UsersScreen
      await Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (context) => const UsersScreen()),
      );
    } else {
      await Navigator.pushReplacementNamed(context, route);
    }
  }
}
