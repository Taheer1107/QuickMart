import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _loading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _loading;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get totalPrice => _items.fold(0.0, (sum, i) => sum + i.total);

  Future<void> loadCart() async {
    _loading = true;
    notifyListeners();
    final raw = await CartService.getCartRaw();
    _items = raw.map((row) => CartItem.fromMap(row)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> addToCart(Product product) async {
    await CartService.addToCart(product);
    await loadCart();
  }

  Future<void> incrementItem(CartItem item) async {
    await CartService.updateQuantity(item.id, item.quantity + 1);
    await loadCart();
  }

  Future<void> decrementItem(CartItem item) async {
    await CartService.updateQuantity(item.id, item.quantity - 1);
    await loadCart();
  }

  Future<void> removeItem(CartItem item) async {
    await CartService.removeItem(item.id);
    await loadCart();
  }

  /// Clears local state immediately (call after a successful checkout,
  /// since the server-side cart is cleared separately once the order is saved).
  void clearLocal() {
    _items = [];
    notifyListeners();
  }
}
