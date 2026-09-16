import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'auth_service.dart';

class CartService {
  static SupabaseClient get _client => Supabase.instance.client;
  static String get _uid => AuthService.currentUser!.id;

  static Future<List<Map<String, dynamic>>> getCartRaw() async {
    final data = await _client
        .from('cart_items')
        .select('id, quantity, products(*)')
        .eq('user_id', _uid);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> addToCart(Product product) async {
    final existing = await _client
        .from('cart_items')
        .select()
        .eq('user_id', _uid)
        .eq('product_id', product.id!)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('cart_items')
          .update({'quantity': (existing['quantity'] as int) + 1}).eq('id', existing['id']);
    } else {
      await _client.from('cart_items').insert({
        'user_id': _uid,
        'product_id': product.id,
        'quantity': 1,
      });
    }
  }

  static Future<void> updateQuantity(int cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    await _client.from('cart_items').update({'quantity': quantity}).eq('id', cartItemId);
  }

  static Future<void> removeItem(int cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  static Future<void> clearCart() async {
    await _client.from('cart_items').delete().eq('user_id', _uid);
  }
}
