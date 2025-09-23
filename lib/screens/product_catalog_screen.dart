import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/cart_service.dart';
import 'product_detail_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  final String? selectedCategory;
  final String? searchQuery;

  const ProductCatalogScreen({
    super.key,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  bool _isAscending = true;

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      // Local asset image
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, size: 40),
        ),
      );
    } else {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, size: 40),
        ),
      );
    }
  }

  final List<String> categories = [
    'All',
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Sports',
    'Books',
    'Health & Beauty',
    'Automotive',
    'Toys & Games'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory ?? 'All';
    _searchController.text = widget.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getProductsStream() {
    // Start with a simple query
    Query query = FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true);

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // For now, skip sorting to avoid Firestore index issues
    // TODO: Add composite indexes in Firestore for sorting with filters
    
    return query.snapshots();
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchController.text.isEmpty) {
      return products;
    }

    final searchTerm = _searchController.text.toLowerCase();
    return products.where((product) =>
        product.name.toLowerCase().contains(searchTerm) ||
        product.description.toLowerCase().contains(searchTerm) ||
        product.category.toLowerCase().contains(searchTerm)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              // Quick debug: Create a test product
              try {
                await FirebaseFirestore.instance.collection('products').add({
                  'name': 'Debug Product',
                  'description': 'Quick test product from catalog screen',
                  'price': 99.99,
                  'category': 'Electronics',
                  'images': ['https://picsum.photos/400/400?random=${DateTime.now().millisecondsSinceEpoch}'],
                  'stock': 10,
                  'rating': 4.0,
                  'reviewCount': 5,
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debug product created!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'asc' || value == 'desc') {
                  _isAscending = value == 'asc';
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'sort_price',
                child: Text('Sort by Price'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'asc',
                child: Row(
                  children: [
                    Icon(_isAscending ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    const SizedBox(width: 8),
                    const Text('Ascending'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'desc',
                child: Row(
                  children: [
                    Icon(!_isAscending ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    const SizedBox(width: 8),
                    const Text('Descending'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade600,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Products Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getProductsStream(),
              builder: (context, snapshot) {
                print('ProductCatalog - Connection state: ${snapshot.connectionState}');
                print('ProductCatalog - Has data: ${snapshot.hasData}');
                print('ProductCatalog - Docs count: ${snapshot.data?.docs.length ?? 0}');
                
                if (snapshot.hasError) {
                  print('ProductCatalog - Error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 50, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('No products found${_selectedCategory != null && _selectedCategory != 'All' ? ' in $_selectedCategory' : ''}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All';
                            });
                          },
                          child: const Text('Show All Categories'),
                        ),
                      ],
                    ),
                  );
                }

                final allProducts = snapshot.data!.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();
                
                final filteredProducts = _filterProducts(allProducts);

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No products match your search'),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        final isInCart = cartService.isInCart(product.id);
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: product.images.isNotEmpty
                          ? _buildProductImage(product.images.first)
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                  ),
                ),
              ),

              // Product Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          if (product.stock > 0)
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                onPressed: () {
                                  if (isInCart) {
                                    cartService.removeFromCart(product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Removed from cart'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  } else {
                                    cartService.addToCart(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to cart'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  isInCart 
                                      ? Icons.remove_shopping_cart 
                                      : Icons.add_shopping_cart,
                                  size: 18,
                                  color: isInCart 
                                      ? Colors.red 
                                      : Colors.blue.shade600,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            )
                          else
                            Text(
                              'Out of Stock',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
