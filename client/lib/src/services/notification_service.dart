// Simple in-app notification service - no external plugin needed
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // No initialization needed for in-app notifications
  }

  Future<void> showOrderStatusNotification({
    required int orderId,
    required String status,
    BuildContext? context,
  }) async {
    if (context == null) return;

    final String title = _titleForStatus(status);
    final String body = _bodyForStatus(orderId, status);
    final Color color = _colorForStatus(status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(_iconForStatus(status), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(body,
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _titleForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return 'Order Confirmed!';
      case 'out for delivery': return 'Out for Delivery!';
      case 'delivered': return 'Order Delivered!';
      case 'cancelled': return 'Order Cancelled';
      default: return 'Order Update';
    }
  }

  String _bodyForStatus(int orderId, String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return 'Order #$orderId is being prepared.';
      case 'out for delivery': return 'Order #$orderId is on its way!';
      case 'delivered': return 'Order #$orderId has been delivered. Enjoy!';
      case 'cancelled': return 'Order #$orderId has been cancelled.';
      default: return 'Order #$orderId status: $status.';
    }
  }

  String _iconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return '✅';
      case 'out for delivery': return '🚚';
      case 'delivered': return '🎉';
      case 'cancelled': return '❌';
      default: return '📦';
    }
  }

  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.orange;
      case 'out for delivery': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }
}