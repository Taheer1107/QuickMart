import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import 'auth_service.dart';

class OrderService {
  static SupabaseClient get _client => Supabase.instance.client;
  static String get _uid => AuthService.currentUser!.id;

  /// Creates an order + its line items from the current cart. No payment step —
  /// this just records the order so an invoice can be shown.
  static Future<int> placeOrder(List<CartItem> cartItems, double total) async {
    final order =
        await _client.from('orders').insert({'user_id': _uid, 'total': total}).select().single();
    final orderId = order['id'] as int;

    final itemsPayload = cartItems
        .map((item) => {
              'order_id': orderId,
              'product_name': item.product.name,
              'price': item.product.price,
              'quantity': item.quantity,
            })
        .toList();

    await _client.from('order_items').insert(itemsPayload);
    try {
      final response = await _client.functions.invoke(
        'send-order-confirmation',
        body: {'orderId': orderId},
      );
      debugPrint('Order confirmation response: ${response.status} ${response.data}');
    } catch (error) {
      // The order remains successful if email delivery is unavailable.
      debugPrint('Order confirmation email failed: $error');
    }
    return orderId;
  }

  static Future<Map<String, dynamic>> getInvoice(int orderId) async {
    final order = await _client.from('orders').select().eq('id', orderId).single();
    final items = await _client.from('order_items').select().eq('order_id', orderId);
    return {'order': order, 'items': items};
  }
}
