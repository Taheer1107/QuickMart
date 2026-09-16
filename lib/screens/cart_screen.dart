import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your bag', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your groceries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('${cart.itemCount} items', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFEDE9E1)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    item.product.imageUrl,
                                    width: 82,
                                    height: 82,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 82,
                                      height: 82,
                                      color: const Color(0xFFF3F1EA),
                                      child: Icon(Icons.shopping_basket_outlined, color: colors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 6),
                                      Text('₹${item.product.price.toStringAsFixed(0)} each', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            height: 34,
                                            decoration: BoxDecoration(color: const Color(0xFFF1F6F2), borderRadius: BorderRadius.circular(10)),
                                            child: Row(
                                              children: [
                                                IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 32), icon: Icon(Icons.remove_rounded, size: 17, color: colors.primary), onPressed: () => context.read<CartProvider>().decrementItem(item)),
                                                Text('${item.quantity}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                                                IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 32), icon: Icon(Icons.add_rounded, size: 17, color: colors.primary), onPressed: () => context.read<CartProvider>().incrementItem(item)),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Text('₹${item.total.toStringAsFixed(0)}', style: TextStyle(color: colors.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(tooltip: 'Remove item', icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[500]), onPressed: () => context.read<CartProvider>().removeItem(item)),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEDE9E1))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal', style: TextStyle(color: Colors.grey[600])), Text('₹${cart.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w600)), Text('FREE', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold))]),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text('₹${cart.totalPrice.toStringAsFixed(0)}', style: TextStyle(color: colors.primary, fontSize: 20, fontWeight: FontWeight.w800))]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Continue to checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
