import 'package:flutter/material.dart';

// App Colors
class AppColors {
  // Primary Colors
  static const primaryColor = Color(0xFF854836);
  static const primaryColorLight = Color.fromARGB(255, 209, 116, 88);
  static const primaryColorDark = Color.fromARGB(255, 81, 44, 33);

  // Secondary Colors
  static const secondaryColor = Color(0xFF0984E3);
  static const secondaryColorLight = Color(0xFF54A8E9);
  static const secondaryColorDark = Color(0xFF0769B8);

  // Background Colors
  static const backgroundColor = Color(0xFFF5F5F5);
  static const secondaryBackgroundColor = Color(0xFFEEEEEE);
  static const cardColor = Colors.white;

  // Text Colors
  static const textPrimaryColor = Color(0xFF2D3436);
  static const textSecondaryColor = Color(0xFF757575);
  static const textLightColor = Color(0xFF9E9E9E);
  static const textTertiaryColor = Color(0xFFA1A1A1);

  // Status Colors
  static const successColor = Color(0xFF00B894);
  static const warningColor = Color(0xFFFDCB6E);
  static const errorColor = Color(0xFFD63031);
  static const infoColor = Color(0xFF0ABDE3);

  // Border Colors
  static const borderColor = Color(0xFFE0E0E0);
  static const dividerColor = Color(0xFFE0E0E0);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF4B6BFB),
    Color(0xFFFF8A00),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
}

// Text Styles
class AppTextStyles {
  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
  );

  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
  );

  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
  );

  static const h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimaryColor,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondaryColor,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLightColor,
  );

  static const buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// App Dimensions
class AppDimensions {
  // Paddings
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Margins
  static const double marginXS = 4.0;
  static const double marginS = 8.0;
  static const double marginM = 16.0;
  static const double marginL = 24.0;
  static const double marginXL = 32.0;

  // Border Radius
  static const double borderRadiusXS = 4.0;
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;

  // Card Elevation
  static const double cardElevation = 2.0;
}

// App Assets
class AppAssets {
  // Images
  static const String logoImage = 'assets/logo.png';
  static const String loginBackgroundImage = 'assets/login_background.jpg';
  static const String placeholderImage = 'assets/placeholder.png';

  // Icons
  static const String dashboardIcon = 'assets/icons/dashboard.png';
  static const String userIcon = 'assets/icons/user.png';
  static const String productIcon = 'assets/icons/product.png';
  static const String orderIcon = 'assets/icons/order.png';
  static const String revenueIcon = 'assets/icons/revenue.png';
  static const String settingIcon = 'assets/icons/setting.png';
}

// App Strings
class AppStrings {
  // App Name
  static const String appName = 'AR Furnish Admin';

  // Auth Screens
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String forgotPassword = 'Forgot Password?';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Name';
  static const String phone = 'Phone';
  static const String address = 'Address';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String totalUsers = 'Total Users';
  static const String totalProducts = 'Total Products';
  static const String totalOrders = 'Total Orders';
  static const String totalRevenue = 'Total Revenue';
  static const String salesOverview = 'Sales Overview';
  static const String recentOrders = 'Recent Orders';
  static const String topProducts = 'Top Products';
  static const String newUsers = 'New Users';

  // Navigation
  static const String users = 'Users';
  static const String products = 'Products';
  static const String orders = 'Orders';
  static const String inventory = 'Inventory';
  static const String categories = 'Categories';
  static const String analytics = 'Analytics';
  static const String aiInteriors = 'AI Interiors';
  static const String managers = 'Managers';
  static const String settings = 'Settings';
  static const String logout = 'Logout';

  // Products
  static const String addProduct = 'Add Product';
  static const String editProduct = 'Edit Product';
  static const String productName = 'Product Name';
  static const String productDescription = 'Product Description';
  static const String productPrice = 'Product Price';
  static const String productCategory = 'Product Category';
  static const String productImages = 'Product Images';
  static const String productStock = 'Product Stock';
  static const String productModel = '3D Model';

  // Users
  static const String addUser = 'Add User';
  static const String editUser = 'Edit User';
  static const String userType = 'User Type';
  static const String isActive = 'Is Active';

  // Error Messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String somethingWentWrong =
      'Something went wrong. Please try again later.';
}
