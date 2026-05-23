import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/order.dart';
import '../widgets/responsive_scaffold.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> _orders = [];
  Map<int, String> _previousStatuses = {};
  bool _isLoading = true;
  String? _error;
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _loadOrders(isInitial: true);
  }

  Future<void> _loadOrders({bool isInitial = false}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = Provider.of<AuthService>(context, listen: false).token!;
      final data = await ApiService().getOrders(token);
      final newOrders = data.map((j) => Order.fromJson(j)).toList();

      // Check for status changes and fire notifications
      if (!isInitial) {
        for (final order in newOrders) {
          final prev = _previousStatuses[order.id];
          if (prev != null && prev != order.status) {
            await _notificationService.showOrderStatusNotification(
              orderId: order.id,
              status: order.status,
              context: mounted ? context : null,
            );
          }
        }
      }

      // Save current statuses for next comparison
      _previousStatuses = {for (final o in newOrders) o.id: o.status};

      setState(() {
        _orders = newOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'My Orders',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadOrders(),
          tooltip: 'Check for updates',
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
                  ],
                ))
              : _orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('Your orders will appear here', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => _OrderCard(order: _orders[index]),
                      ),
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  static const _steps = ['placed', 'confirmed', 'out for delivery', 'delivered'];

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

  int get _currentStep {
    final idx = _steps.indexOf(order.status.toLowerCase());
    return idx >= 0 ? idx : -1;
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final color = _statusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(_statusIcon(order.status), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Text(order.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCancelled) ...[
                  _buildProgressTracker(),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
                if (isCancelled) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text('This order was cancelled.', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                ],
                _infoRow(Icons.location_on_outlined, 'Delivery to', order.deliveryAddress),
                if (order.deliveryNotes != null && order.deliveryNotes!.isNotEmpty)
                  _infoRow(Icons.note_outlined, 'Notes', order.deliveryNotes!),
                _infoRow(Icons.payment_outlined, 'Payment', order.paymentMethod),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('₦${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    final step = _currentStep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final filled = i ~/ 2 < step;
              return Expanded(
                child: Container(height: 3, color: filled ? Colors.green : Colors.grey.shade300),
              );
            }
            final s = i ~/ 2;
            final done = s <= step;
            final icons = [Icons.receipt_long, Icons.check_circle_outline, Icons.local_shipping, Icons.done_all];
            final labels = ['Placed', 'Confirmed', 'On Way', 'Delivered'];
            return Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: done ? Colors.green : Colors.grey.shade200,
                  child: Icon(icons[s], size: 16, color: done ? Colors.white : Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(labels[s],
                    style: TextStyle(
                      fontSize: 9,
                      color: done ? Colors.green : Colors.grey,
                      fontWeight: done ? FontWeight.bold : FontWeight.normal,
                    )),
              ],
            );
          }),
        ),
      ],
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
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }
}