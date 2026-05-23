import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/responsive_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _allProducts = [];
  List<Product> _featured = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBanner = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_featured.isNotEmpty && _bannerController.hasClients) {
        final next = (_currentBanner + 1) % _featured.length;
        _bannerController.animateToPage(next,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        setState(() => _currentBanner = next);
      }
    });
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService().getProducts();
      final products = data.map((j) => Product.fromJson(j)).toList();
      final featured = products.where((p) => p.featured && p.available).toList();
      final cats = ['All', ...{...products.map((p) => p.category)}.toList()..sort()];
      setState(() {
        _allProducts = products;
        _featured = featured;
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  List<Product> get _filteredProducts {
    return _allProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch && p.available;
    }).toList();
  }

  void _addToCart(Product product) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => GoRouter.of(context).go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final cartService = Provider.of<CartService>(context);
    final userName = authService.isGuest
        ? 'Guest'
        : authService.user?['name']?.toString().split(' ').first ?? 'there';

    return ResponsiveScaffold(
      title: 'BridgeLink',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => GoRouter.of(context).go('/profile'),
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () => GoRouter.of(context).go('/my-orders'),
          tooltip: 'My Orders',
        ),
        IconButton(
          icon: Badge(
            label: Text('${cartService.itemCount}'),
            isLabelVisible: cartService.itemCount > 0,
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          onPressed: () => GoRouter.of(context).go('/cart'),
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildGreeting(userName)),
                  if (_featured.isNotEmpty)
                    SliverToBoxAdapter(child: _buildFeaturedBanner()),
                  SliverToBoxAdapter(child: _buildCategories()),
                  if (_featured.isNotEmpty && _searchQuery.isEmpty && _selectedCategory == 'All')
                    SliverToBoxAdapter(child: _buildFeaturedSection()),
                  SliverToBoxAdapter(child: _buildSectionHeader()),
                  _buildProductsGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildGreeting(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $name! 👋',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('What are you looking for today?',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBanner() {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _featured.length,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemBuilder: (context, index) {
              final product = _featured[index];
              return GestureDetector(
                onTap: () => _addToCart(product),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (product.imageUrl != null)
                          Image.network(
                            '${ApiService.baseUrl.replaceAll('/api', '')}${product.imageUrl}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.blue.shade700),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),
                              Text(product.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('₦${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_featured.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: i == _currentBanner ? 20 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == _currentBanner ? Colors.blue : Colors.grey.shade300,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Featured Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => GoRouter.of(context).go('/catalogue'),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _featured.length,
            itemBuilder: (context, index) {
              final product = _featured[index];
              return _FeaturedProductCard(
                product: product,
                onAddToCart: () => _addToCart(product),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    final count = _filteredProducts.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _searchQuery.isNotEmpty
                ? 'Results for "$_searchQuery"'
                : _selectedCategory == 'All'
                    ? 'All Products'
                    : _selectedCategory,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text('$count items', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 60, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No products in this category',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ProductCard(
            product: products[index],
            onAddToCart: () => _addToCart(products[index]),
          ),
          childCount: products.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
      ),
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const _FeaturedProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.imageUrl != null
                  ? Image.network(
                      '${ApiService.baseUrl.replaceAll('/api', '')}${product.imageUrl}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('₦${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const _ProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                product.imageUrl != null
                    ? Image.network(
                        '${ApiService.baseUrl.replaceAll('/api', '')}${product.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                if (product.featured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('⭐ Featured',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(product.category,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₦${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}