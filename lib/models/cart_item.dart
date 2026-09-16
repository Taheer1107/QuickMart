import 'product.dart';

class CartItem {
  final int id; // cart_items row id in Supabase
  final Product product;
  final int quantity;

  const CartItem({required this.id, required this.product, required this.quantity});

  double get total => product.price * quantity;

  static CartItem fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int,
      product: Product.fromMap(map['products'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
    );
  }
}
