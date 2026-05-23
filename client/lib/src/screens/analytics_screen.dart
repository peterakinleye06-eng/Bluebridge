import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_scaffold.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = Provider.of<AuthService>(context, listen: false).token!;
      final data = await ApiService().getAnalytics(token);
      setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Analytics',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildRevenueChart(),
                      const SizedBox(height: 24),
                      _buildStatusBreakdown(),
                      const SizedBox(height: 24),
                      _buildPaymentBreakdown(),
                      const SizedBox(height: 24),
                      _buildRecentOrders(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final totalOrders = _data!['total_orders'] ?? 0;
    final totalRevenue = (_data!['total_revenue'] ?? 0).toDouble();
    final statusCounts = Map<String, dynamic>.from(_data!['status_counts'] ?? {});
    final delivered = statusCounts['delivered'] ?? 0;
    final pending = (statusCounts['placed'] ?? 0) + (statusCounts['confirmed'] ?? 0);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _summaryCard('Total Orders', '$totalOrders', Icons.receipt_long, Colors.blue),
        _summaryCard('Total Revenue', '₦${totalRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.green),
        _summaryCard('Delivered', '$delivered', Icons.done_all, Colors.teal),
        _summaryCard('Pending', '$pending', Icons.hourglass_empty, Colors.orange),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final days = List<Map<String, dynamic>>.from(_data!['revenue_by_day'] ?? []);
    if (days.isEmpty) return const SizedBox.shrink();

    final maxRevenue = days.fold<double>(1, (max, d) {
      final rev = (d['revenue'] ?? 0).toDouble();
      return rev > max ? rev : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue — Last 7 Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((d) {
                  final rev = (d['revenue'] ?? 0).toDouble();
                  final barHeight = (rev / maxRevenue) * 120;
                  final date = (d['date'] as String).substring(5); // MM-DD
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (rev > 0)
                            Text('₦${rev.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 8, color: Colors.grey),
                                textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight > 0 ? barHeight : 4,
                            decoration: BoxDecoration(
                              color: rev > 0 ? Colors.blue : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(date, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final statusCounts = Map<String, dynamic>.from(_data!['status_counts'] ?? {});
    if (statusCounts.isEmpty) return const SizedBox.shrink();

    final colors = {
      'placed': Colors.blue,
      'confirmed': Colors.orange,
      'out for delivery': Colors.purple,
      'delivered': Colors.green,
      'cancelled': Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orders by Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...statusCounts.entries.map((e) {
              final total = _data!['total_orders'] as int;
              final pct = total > 0 ? (e.value as int) / total : 0.0;
              final color = colors[e.key] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.toUpperCase(), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                        Text('${e.value} orders', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
    final payments = Map<String, dynamic>.from(_data!['payment_breakdown'] ?? {});
    if (payments.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...payments.entries.map((e) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: e.key == 'Paystack' ? Colors.blue.shade50 : Colors.green.shade50,
                child: Icon(
                  e.key == 'Paystack' ? Icons.credit_card : Icons.money,
                  size: 16,
                  color: e.key == 'Paystack' ? Colors.blue : Colors.green,
                ),
              ),
              title: Text(e.key),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    final recent = List<Map<String, dynamic>>.from(_data!['recent_orders'] ?? []);
    if (recent.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recent.map((o) => ListTile(
              dense: true,
              title: Text('Order #${o['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(o['status']?.toString().toUpperCase() ?? ''),
              trailing: Text('₦${double.tryParse(o['total_amount'].toString())?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            )),
          ],
        ),
      ),
    );
  }
}