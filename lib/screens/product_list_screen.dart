import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'product_details_screen.dart';
import 'order_tracking_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final List<String> products = List.generate(20, (index) => 'Product $index');
  List<String> filteredProducts = [];
  final TextEditingController searchController = TextEditingController();
  final List<String> cartItems = [];
  final List<String> wishlistItems = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = products;
  }

  void filterProducts(String query) {
    setState(() {
      filteredProducts = products
          .where((product) => product.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void addToCart(String product) {
    setState(() {
      cartItems.add(product);
    });
  }

  void addToWishlist(String product) {
    setState(() {
      if (!wishlistItems.contains(product)) {
        wishlistItems.add(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WishlistScreen(wishlistItems: wishlistItems),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(products, filterProducts),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderTrackingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.image),
            title: Text(filteredProducts[index]),
            subtitle: Text('Price: \$${(index + 1) * 10}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    addToWishlist(filteredProducts[index]);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () {
                    addToCart(filteredProducts[index]);
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(
                    productName: filteredProducts[index],
                    productPrice: '\$${(index + 1) * 10}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate {
  final List<String> products;
  final Function(String) onSearch;

  ProductSearchDelegate(this.products, this.onSearch);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch(query);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = products
        .where((product) => product.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]),
          onTap: () {
            close(context, results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products
        .where((product) => product.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
