import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'manage_products_screen.dart';
import 'login_screen.dart';
import 'package:flutter/gestures.dart';

class _CategoryOption {
  final String name;
  final IconData icon;
  final String imageUrl;
  final Color color;

  const _CategoryOption(this.name, this.icon, this.imageUrl, this.color);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = [
    _CategoryOption('All', Icons.grid_view_rounded, 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=300', Color(0xFFE2F1E7)),
    _CategoryOption('Fruits', Icons.apple_rounded, 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=300', Color(0xFFFFE3D5)),
    _CategoryOption('Dairy', Icons.local_drink_rounded, 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=300', Color(0xFFFFF0C9)),
    _CategoryOption('Bakery', Icons.bakery_dining_rounded, 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300', Color(0xFFF8E3C5)),
    _CategoryOption('Chocolates', Icons.cookie_rounded, 'https://images.unsplash.com/photo-1575377427642-087cf684f29d?w=300', Color(0xFFEEDBD2)),
    _CategoryOption('Electronics', Icons.headphones_rounded, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=300', Color(0xFFDCE8F5)),
    _CategoryOption('Juices', Icons.local_cafe_rounded, 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=300', Color(0xFFFFE2B8)),
  ];

  late Future<List<Product>> _productsFuture;
  bool _isAdmin = false;
  bool _signingOut = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  final _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _checkAdmin();
    // Load the signed-in user's cart once on entry.
    Future.microtask(() => context.read<CartProvider>().loadCart());
  }

  void _loadProducts() {
    _productsFuture = ProductService.readAllProducts();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await AuthService.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await AuthService.signOut();
      if (mounted && AuthService.currentUser == null) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log out. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _refresh() {
    setState(_loadProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DELIVERING TO', style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            const Row(children: [Icon(Icons.location_on_rounded, size: 16), SizedBox(width: 4), Text('Bengaluru, Karnataka', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
          ],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.storefront_outlined),
              tooltip: 'Manage products',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
                );
                _refresh();
              },
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Open cart',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${cart.itemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: _signingOut
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _signingOut ? null : _signOut,
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Could not load products. Check your connection.'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products yet.'));
          }
          final filteredProducts = products.where((product) {
            final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
            final categoryTerms = <String, List<String>>{
              'Fruits': ['banana', 'tomato'],
              'Dairy': ['milk', 'egg'],
              'Bakery': ['bread'],
              'Chocolates': ['chocolate', 'cocoa'],
              'Electronics': ['phone', 'laptop', 'headphone', 'electronic'],
              'Juices': ['juice', 'drink', 'smoothie'],
            };
            final matchesCategory = _selectedCategory == 'All' ||
                (categoryTerms[_selectedCategory] ?? []).any((term) => product.name.toLowerCase().contains(term));
            return matchesSearch && matchesCategory;
          }).toList();
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 168,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(24),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1542838132-92c53300491e?w=900'),
                              fit: BoxFit.cover,
                              opacity: 0.18,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Good food,\nzero waiting.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.05)),
                                    SizedBox(height: 10),
                                    Text('Fresh picks delivered to your door.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                                child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 38),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: const InputDecoration(hintText: 'Search milk, bread, fruits...', prefixIcon: Icon(Icons.search_rounded)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Explore categories', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                            Text('Swipe to explore  →', style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 126,
                          child: Scrollbar(
                            controller: _categoryScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            scrollbarOrientation: ScrollbarOrientation.bottom,
                            child: ListView.separated(
                              controller: _categoryScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              dragStartBehavior: DragStartBehavior.start,
                              padding: const EdgeInsets.only(bottom: 10),
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final selected = category.name == _selectedCategory;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => setState(() => _selectedCategory = category.name),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    width: 88,
                                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                                    decoration: BoxDecoration(
                                      color: selected ? colors.primary : category.color,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: selected ? colors.primary : Colors.transparent, width: 2),
                                      boxShadow: selected ? [BoxShadow(color: colors.primary.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))] : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(13),
                                            child: Image.network(category.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(category.icon, color: colors.primary, size: 32)),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? Colors.white : const Color(0xFF26332B), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Popular near you', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                            Text('${filteredProducts.length} items', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredProducts.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('No matching products')))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 190,
                        childAspectRatio: 0.74,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = filteredProducts[index];
                          return ProductCard(
                            product: product,
                            onAdd: () async {
                              await context.read<CartProvider>().addToCart(product);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(milliseconds: 600)));
                              }
                            },
                          );
                        },
                        childCount: filteredProducts.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
