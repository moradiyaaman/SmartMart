import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/cart_service.dart';
import '../utils/notification_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      // Local asset image
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, size: 50),
        ),
      );
    } else if (imagePath.startsWith('http')) {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, size: 50),
        ),
      );
    } else {
      // Local file path
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, size: 50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Dominant, Full-Width, Scrollable Image Carousel
          _buildDominantImageCarousel(),
          
          // Seamless, Integrated Product Details - No card, no separation
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name - Large, bold, multi-line wrapping
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.25,
                      ),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 8),
                    
                    // Product Description Text - Immediately after product name, no heading
                    Text(
                      widget.product.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    
                    // Price - Single, clean price
                    Text(
                      '₹${widget.product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stock Status
                    Text(
                      widget.product.stock > 0 
                          ? 'Stock: ${widget.product.stock} available'
                          : 'Out of stock',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.product.stock > 0 
                            ? Colors.green.shade600 
                            : Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Quantity Selector
                    if (widget.product.stock > 0) ...[
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _quantity > 1 
                                    ? () => setState(() => _quantity--) 
                                    : null,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.remove,
                                    size: 18,
                                    color: _quantity > 1 
                                        ? Colors.black 
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 44,
                              alignment: Alignment.center,
                              child: Text(
                                _quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _quantity < widget.product.stock 
                                    ? () => setState(() => _quantity++) 
                                    : null,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: _quantity < widget.product.stock 
                                        ? Colors.black 
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Fixed "Add to Cart" Footer Button
      bottomNavigationBar: widget.product.stock > 0
          ? Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Consumer<CartService>(
                builder: (context, cartService, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        cartService.addToCart(widget.product, quantity: _quantity);
                        NotificationService.showSuccess(
                          context, 
                          'Added $_quantity ${widget.product.name} to cart'
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildDominantImageCarousel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55, // Substantial visual height - dominant focal point
      width: double.infinity,
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top), // Add top margin for status bar
      child: Stack(
        children: [
          // Full-Width, Edge-to-Edge, Horizontally Scrollable Carousel
          if (!widget.product.hasImages)
            // No images - show placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey.shade100,
              child: Center(
                child: Icon(
                  Icons.image_not_supported, 
                  size: 80,
                  color: Colors.grey.shade400,
                ),
              ),
            )
          else
            // Horizontally scrollable image carousel - absolute edge to edge
            PageView.builder(
              itemCount: widget.product.images.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: _buildProductImage(widget.product.images[index]),
                );
              },
            ),
          
          // Back Arrow - Properly positioned to avoid status bar overlap
          Positioned(
            top: 12, // Now positioned relative to container with top margin
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 20),
                color: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          
          // Pagination Dots - Overlayed directly on bottom center of image carousel
          if (widget.product.hasImages && widget.product.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.product.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _selectedImageIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
