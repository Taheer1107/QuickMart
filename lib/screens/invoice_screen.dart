import 'dart:async';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import 'home_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final int orderId;
  const InvoiceScreen({super.key, required this.orderId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late Future<Map<String, dynamic>> _invoiceFuture;
  int _secondsLeft = 10 * 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _invoiceFuture = OrderService.getInvoice(widget.orderId);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final delivered = _secondsLeft <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load invoice.'));
          }

          final order = snapshot.data!['order'] as Map<String, dynamic>;
          final items = (snapshot.data!['items'] as List).cast<Map<String, dynamic>>();
          final total = (order['total'] as num).toDouble();
          final createdAt = DateTime.parse(order['created_at'] as String).toLocal();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        delivered ? Icons.check_circle : Icons.delivery_dining,
                        size: 64,
                        color: Colors.green[700],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        delivered ? 'Delivered!' : 'Order Placed!',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (!delivered) ...[
                        const SizedBox(height: 4),
                        Text('Arriving in', style: TextStyle(color: Colors.grey[700])),
                        Text(
                          _formattedTime,
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final price = (item['price'] as num).toDouble();
                  final qty = item['quantity'] as int;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('${item['product_name']} x$qty')),
                        Text('₹${(price * qty).toStringAsFixed(0)}'),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
