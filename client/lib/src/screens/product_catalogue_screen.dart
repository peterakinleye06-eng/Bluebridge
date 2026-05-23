import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';
import '../widgets/responsive_scaffold.dart';

class ProductCatalogueScreen extends StatefulWidget {
  const ProductCatalogueScreen({super.key});

  @override
  State<ProductCatalogueScreen> createState() => _ProductCatalogueScreenState();
}

class _ProductCatalogueScreenState extends State<ProductCatalogueScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService().getProducts();
      setState(() {
        _products = data.map((j) => Product.fromJson(j)).toList();
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

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return ResponsiveScaffold(
      title: 'Catalogue',
      actions: [
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
          : _products.isEmpty
              ? const Center(child: Text('No products available'))
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final imageUrl = product.imageUrl != null
                          ? '${ApiService.baseUrl.replaceAll('/api', '')}${product.imageUrl}'
                          : null;

                      return GestureDetector(
                        onTap: () => GoRouter.of(context).go(
                          '/product/${product.id}',
                          extra: product,
                        ),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    imageUrl != null
                                        ? Image.network(imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                            ))
                                        : Container(
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                          ),
                                    if (product.featured)
                                      Positioned(
                                        top: 8, left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('⭐',
                                              style: TextStyle(fontSize: 10)),
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
                                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('₦${product.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          GestureDetector(
                                            onTap: () {
                                              cartService.addToCart(product);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${product.name} added to cart'),
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            },
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}