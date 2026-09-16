import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFEDE9E1))),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: const Color(0xFFF3F1EA), child: Center(child: CircularProgressIndicator(color: colors.secondary, strokeWidth: 2))),
                  errorBuilder: (context, error, stack) => Container(
                    color: const Color(0xFFF3F1EA),
                    child: Icon(Icons.image_not_supported_outlined, color: colors.primary),
                  ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 3),
            Text('₹${product.price.toStringAsFixed(0)}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 7), minimumSize: const Size.fromHeight(34)),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
