import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  static Future<List<Product>> readAllProducts() async {
    final data = await ApiClient.get('/api/products') as List<dynamic>;
    return data.map((row) => Product.fromMap(row as Map<String, dynamic>)).toList();
  }

  static Future<Product> create(Product product) async {
    final data = await ApiClient.post('/api/products', {
      'name': product.name,
      'price': product.price,
      'imageUrl': product.imageUrl,
    }) as Map<String, dynamic>;
    return Product.fromMap(data);
  }

  static Future<void> delete(int id) async {
    await ApiClient.delete('/api/products/$id');
  }
}
