import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_scaffold.dart';

// ── REPLACE WITH YOUR PAYSTACK SECRET KEY (keep this server-side in production) ─
const String _paystackSecretKey = 'sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Paystack (Card / Bank)',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentMethod == 'Paystack (Card / Bank)') {
      await _payWithPaystack();
    } else {
      await _submitOrder(paymentRef: null);
    }
  }

  Future<void> _payWithPaystack() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = authService.user?['email'] ?? 'customer@bridgelink.com';
    final amountInKobo = (cartService.total * 100).toInt().toString();
    final reference = 'BL-${DateTime.now().millisecondsSinceEpoch}';

    await FlutterPaystackPlus.openPaystackPopup(
      context: context,
      secretKey: _paystackSecretKey,
      customerEmail: email,
      amount: amountInKobo,
      reference: reference,
      currency: 'NGN',
      callBackUrl: 'https://bridgelink.app/payment/callback',
      onSuccess: () async {
        await _submitOrder(paymentRef: reference);
      },
      onClosed: () {},

    );
  }

  Future<void> _submitOrder({String? paymentRef}) async {
    setState(() => _isLoading = true);
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final orderData = {
        'user_id': authService.user?['id'],
        'total_amount': cartService.total,
        'delivery_address': _addressController.text,
        'delivery_notes': _notesController.text,
        'payment_method': paymentRef != null
            ? 'Paystack (ref: $paymentRef)'
            : _paymentMethod,
      };

      await ApiService().createOrder(orderData);
      cartService.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return ResponsiveScaffold(
      title: 'Checkout',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...cartService.items.map((item) => Card(
              child: ListTile(
                title: Text(item.product.name),
                subtitle: Text('Qty: ${item.quantity}'),
                trailing: Text('₦${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₦${cartService.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Delivery Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.isEmpty) ? 'Please enter delivery address' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Delivery Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            const Text('Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...(_paymentMethods.map((method) => Card(
              color: _paymentMethod == method ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(
                      method == 'Paystack (Card / Bank)' ? Icons.credit_card : Icons.money,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(method),
                  ],
                ),
                subtitle: method == 'Paystack (Card / Bank)'
                    ? const Text('Pay securely with card or bank transfer', style: TextStyle(fontSize: 12))
                    : const Text('Pay when your order arrives', style: TextStyle(fontSize: 12)),
                value: method,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
            ))),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _paymentMethod == 'Paystack (Card / Bank)'
                          ? 'Pay ₦${cartService.total.toStringAsFixed(2)}'
                          : 'Place Order',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
            if (_paymentMethod == 'Paystack (Card / Bank)')
              const Center(
                child: Text('🔒 Secured by Paystack', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}