import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const ResponsiveScaffold({super.key, required this.title, required this.child, this.actions});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: isDesktop ? null : Drawer(child: _NavigationMenu()),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 280, child: _NavigationMenu()),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavigationMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Colors.blue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 64,
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              const Text('BridgeLink', style: TextStyle(color: Colors.white, fontSize: 24)),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () => GoRouter.of(context).go('/'),
        ),
        ListTile(
          leading: const Icon(Icons.storefront),
          title: const Text('Catalogue'),
          onTap: () => GoRouter.of(context).go('/catalogue'),
        ),
        ListTile(
          leading: const Icon(Icons.shopping_cart),
          title: const Text('Cart'),
          onTap: () => GoRouter.of(context).go('/cart'),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Admin Dashboard'),
          onTap: () => GoRouter.of(context).go('/admin'),
        ),
      ],
    );
  }
}
