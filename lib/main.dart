// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:path_provider_windows/path_provider_windows.dart'
    if (dart.library.html) 'package:admin_penal/web_stub_providers.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart'
    if (dart.library.html) 'package:admin_penal/web_stub_providers.dart';

import 'dart:io' if (dart.library.html) 'package:admin_penal/web_stub_io.dart';

import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'constants/routes.dart';
import 'providers/analytics_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/promotion_provider.dart';
import 'providers/order_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/ai_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/promotions/promotions_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/managers/managers_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/widgets/admin_settings.dart';
import 'screens/settings/widgets/security_settings.dart';
import 'screens/chat/chats_screen.dart';
import 'screens/ai_interiors/ai_analytics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize path provider for Windows, but only in non-web environments
  if (!kIsWeb) {
    try {
      if (Platform.isWindows) {
        final provider = PathProviderWindows();
        PathProviderPlatform.instance = provider;
      }
    } catch (e) {
      // Ignore platform errors
      print('Platform detection failed: $e');
    }
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => PromotionProvider()),
        ChangeNotifierProvider(create: (context) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => AIProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primaryColor,
          primarySwatch: MaterialColor(0xFF2D3436, {
            50: AppColors.primaryColor.withOpacity(0.1),
            100: AppColors.primaryColor.withOpacity(0.2),
            200: AppColors.primaryColor.withOpacity(0.3),
            300: AppColors.primaryColor.withOpacity(0.4),
            400: AppColors.primaryColor.withOpacity(0.5),
            500: AppColors.primaryColor,
            600: AppColors.primaryColor.withOpacity(0.7),
            700: AppColors.primaryColor.withOpacity(0.8),
            800: AppColors.primaryColor.withOpacity(0.9),
            900: AppColors.primaryColor.withOpacity(1.0),
          }),
          scaffoldBackgroundColor: AppColors.backgroundColor,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimaryColor),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
          ),
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          // Special handling for problematic routes
          if (settings.name == AppRoutes.users || settings.name == '/users') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const UsersScreen(),
            );
          }

          // Return null to let the routes table handle the case
          // If no route is found, this will be handled by onUnknownRoute
          return null;
        },
        onUnknownRoute: (settings) {
          // Fallback to dashboard if route not found
          return MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          );
        },
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.dashboard: (context) => const DashboardScreen(),
          AppRoutes.products: (context) => const ProductsScreen(),
          AppRoutes.orders: (context) => const OrdersScreen(),
          AppRoutes.users: (context) => const UsersScreen(),
          AppRoutes.promotions: (context) => const PromotionsScreen(),
          AppRoutes.managers: (context) => const ManagersScreen(),
          AppRoutes.notifications: (context) => const NotificationsScreen(),
          AppRoutes.analytics: (context) => const AnalyticsScreen(),
          AppRoutes.settings: (context) => const SettingsScreen(),
          AppRoutes.adminSettings: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Admin Settings'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.settings),
                  ),
                ),
                body: const Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingL),
                  child: AdminSettings(),
                ),
              ),
          AppRoutes.securitySettings: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Security Settings'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.settings),
                  ),
                ),
                body: const Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingL),
                  child: SecuritySettings(),
                ),
              ),
          AppRoutes.chats: (context) => const ChatsScreen(),
          AppRoutes.aiInteriors: (context) => const AIAnalyticsScreen(),
        },
      ),
    );
  }
}

class DashboardLoader extends StatelessWidget {
  const DashboardLoader({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize chat provider with current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.userData != null) {
        Provider.of<ChatProvider>(context, listen: false)
            .initChats(authProvider.userData!.id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 64,
              color: AppColors.primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'Dashboard',
              style: AppTextStyles.h1,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to the AR Furnish Admin Panel',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
