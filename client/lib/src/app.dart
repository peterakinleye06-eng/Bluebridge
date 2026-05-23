import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/phone_auth_screen.dart';
import 'screens/product_catalogue_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/admin_products_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/product_detail_screen.dart';
import 'models/product.dart';

// Admin-only route guard widget
class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Not logged in → go to login
    if (!authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(context).go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Logged in but not admin → go to home with error
    if (authService.user?['role'] != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(context).go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Admin privileges required.'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}

class BridgeLinkApp extends StatelessWidget {
  BridgeLinkApp({super.key});

  final _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/phone-auth', builder: (context, state) => const PhoneAuthScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/catalogue', builder: (context, state) => const ProductCatalogueScreen()),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),

      // Admin-only routes — protected by AdminGuard
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminGuard(child: AdminDashboard()),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminGuard(child: AdminProductsScreen()),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(product: state.extra as Product),
      ),
      GoRoute(
        path: '/my-orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminGuard(child: AnalyticsScreen()),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminGuard(child: AdminOrdersScreen()),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp.router(
        title: 'BridgeLink Logistics',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isAuthenticated || authService.isGuest) {
      // Admin → Admin Dashboard
      if (authService.user?['role'] == 'admin') {
        return const AdminDashboard();
      }
      // Customer or Guest → Home
      return const HomeScreen();
    }

    // Not logged in → Login
    return const LoginScreen();
  }
}