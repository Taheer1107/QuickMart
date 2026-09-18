import '../models/cart_item.dart';
import 'api_client.dart';

class OrderService {
  static Future<int> placeOrder(List<CartItem> cartItems, double total) async {
    final data = await ApiClient.post('/api/orders') as Map<String, dynamic>;
    final order = data['order'] as Map<String, dynamic>;
    return (order['id'] as num).toInt();
  }

  static Future<Map<String, dynamic>> getInvoice(int orderId) async {
    return await ApiClient.get('/api/orders/$orderId') as Map<String, dynamic>;
  }
}
