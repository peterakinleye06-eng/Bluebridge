import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _addToCart() {
    final cartService = Provider.of<CartService>(context, listen: false);
    for (int i = 0; i < _quantity; i++) {
      cartService.addToCart(widget.product);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_quantity × ${widget.product.name} added to cart'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => GoRouter.of(context).go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cartService = Provider.of<CartService>(context);
    final imageUrl = product.imageUrl != null
        ? '${ApiService.baseUrl.replaceAll('/api', '')}${product.imageUrl}'
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
            ),
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
          ),

          // Product details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name & featured badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (product.featured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('⭐ Featured',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Text(
                    '₦${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 16),

                  // Availability
                  Row(
                    children: [
                      Icon(
                        product.available ? Icons.check_circle : Icons.cancel,
                        color: product.available ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.available
                            ? 'In Stock (${product.stockQuantity} available)'
                            : 'Out of Stock',
                        style: TextStyle(
                          color: product.available ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text('Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'No description available.',
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // Quantity selector
                  if (product.available) ...[
                    const Text('Quantity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _quantity < product.stockQuantity
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Total: ₦${(product.price * _quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Add to Cart button
      bottomNavigationBar: product.available
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    'Add $_quantity to Cart — ₦${(product.price * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Out of Stock', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
    );
  }
}