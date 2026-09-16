import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// Talks to the hosted Supabase 'products' table.
/// Inserts/deletes are restricted to admins server-side via RLS policies.
class ProductService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<Product>> readAllProducts() async {
    final data = await _client.from('products').select().order('id');
    return (data as List).map((row) => Product.fromMap(row as Map<String, dynamic>)).toList();
  }

  static Future<Product> create(Product product) async {
    final data = await _client.from('products').insert(product.toInsertMap()).select().single();
    return Product.fromMap(data);
  }

  static Future<void> delete(int id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
