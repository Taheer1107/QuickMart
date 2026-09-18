import '../models/product.dart';
import 'api_client.dart';

class CartService {
  static Future<List<Map<String, dynamic>>> getCartRaw() async {
    final data = await ApiClient.get('/api/cart') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<void> addToCart(Product product) async {
    await ApiClient.post('/api/cart', {'productId': product.id});
  }

  static Future<void> updateQuantity(int cartItemId, int quantity) async {
    if (quantity <= 0) {
      await ApiClient.patch('/api/cart/$cartItemId', {'quantity': 0});
      return;
    }
    await ApiClient.patch('/api/cart/$cartItemId', {'quantity': quantity});
  }

  static Future<void> removeItem(int cartItemId) async {
    await ApiClient.delete('/api/cart/$cartItemId');
  }

  static Future<void> clearCart() async {
    await ApiClient.delete('/api/cart');
  }
}
