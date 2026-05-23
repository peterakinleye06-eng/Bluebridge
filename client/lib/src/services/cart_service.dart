import 'package:flutter/material.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get total => _items.fold(0, (sum, item) => sum + item.total);

  void addToCart(Product product) {
    final existingItem = _items.where((item) => item.product.id == product.id).firstOrNull;
    if (existingItem != null) {
      existingItem.quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void updateQuantity(Product product, int quantity) {
    final item = _items.where((item) => item.product.id == product.id).firstOrNull;
    if (item != null) {
      if (quantity <= 0) {
        removeFromCart(product);
      } else {
        item.quantity = quantity;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}