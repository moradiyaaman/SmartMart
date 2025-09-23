import 'package:flutter/material.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key, required this.wishlistItems});

  final List<String> wishlistItems;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: widget.wishlistItems.isEmpty
          ? const Center(
              child: Text('Your wishlist is empty'),
            )
          : ListView.builder(
              itemCount: widget.wishlistItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(widget.wishlistItems[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        widget.wishlistItems.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
