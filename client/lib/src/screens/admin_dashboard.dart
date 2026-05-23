import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_scaffold.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return ResponsiveScaffold(
      title: 'Admin Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            authService.logout();
            GoRouter.of(context).go('/');
          },
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Owner / Admin Panel',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Manage your logistics business',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _DashboardCard(
                  title: 'Products',
                  icon: Icons.inventory,
                  onTap: () => GoRouter.of(context).go('/admin/products'),
                ),
                _DashboardCard(
                  title: 'Orders',
                  icon: Icons.shopping_cart,
                  onTap: () => GoRouter.of(context).go('/admin/orders'),
                ),
                _DashboardCard(
                  title: 'Analytics',
                  icon: Icons.analytics,
                  onTap: () {
                    GoRouter.of(context).go('/admin/analytics');
                  },
                ),
                _DashboardCard(
                  title: 'Settings',
                  icon: Icons.settings,
                  onTap: () {
                    // TODO: Navigate to settings screen
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}