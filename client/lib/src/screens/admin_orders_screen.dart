import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/order.dart';
import '../widgets/responsive_scaffold.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final token = Provider.of<AuthService>(context, listen: false).token!;
      final data = await ApiService().getOrders(token);
      setState(() {
        _orders = data.map((j) => Order.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    try {
      final token = Provider.of<AuthService>(context, listen: false).token!;
      await ApiService().updateOrderStatus(order.id, newStatus, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.id} → $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed': return Colors.blue;
      case 'confirmed': return Colors.orange;
      case 'out for delivery': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'placed': return Icons.receipt_long;
      case 'confirmed': return Icons.check_circle_outline;
      case 'out for delivery': return Icons.local_shipping;
      case 'delivered': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Order Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadOrders,
          tooltip: 'Refresh',
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(order.status).withOpacity(0.15),
                            child: Icon(_statusIcon(order.status), color: _statusColor(order.status), size: 20),
                          ),
                          title: Row(
                            children: [
                              Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(order.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.status.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '₦${order.totalAmount.toStringAsFixed(2)} • ${order.createdAt.toString().split(' ')[0]}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  _infoRow(Icons.location_on, 'Delivery Address', order.deliveryAddress),
                                  if (order.deliveryNotes != null && order.deliveryNotes!.isNotEmpty)
                                    _infoRow(Icons.note, 'Notes', order.deliveryNotes!),
                                  _infoRow(Icons.payment, 'Payment', order.paymentMethod),
                                  const SizedBox(height: 16),
                                  const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  _statusButtons(order),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _statusButtons(Order order) {
    final status = order.status.toLowerCase();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statusBtn('Confirm', Icons.check_circle_outline, Colors.orange,
            enabled: status == 'placed',
            onTap: () => _updateStatus(order, 'confirmed')),
        _statusBtn('Out for Delivery', Icons.local_shipping, Colors.purple,
            enabled: status == 'confirmed',
            onTap: () => _updateStatus(order, 'out for delivery')),
        _statusBtn('Delivered', Icons.done_all, Colors.green,
            enabled: status == 'out for delivery',
            onTap: () => _updateStatus(order, 'delivered')),
        _statusBtn('Cancel', Icons.cancel, Colors.red,
            enabled: status != 'delivered' && status != 'cancelled',
            onTap: () => _updateStatus(order, 'cancelled')),
      ],
    );
  }

  Widget _statusBtn(String label, IconData icon, Color color,
      {required bool enabled, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade200,
        foregroundColor: enabled ? Colors.white : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}