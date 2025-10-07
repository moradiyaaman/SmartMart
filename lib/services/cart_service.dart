import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/app_models.dart';

class CartItem {
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  final Product product; // Keep for backward compatibility
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => productPrice * quantity;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? productPrice,
    String? productImage,
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static CartItem fromMap(Map<String, dynamic> map, Product product) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      productImage: map['productImage'] ?? '',
      product: product,
      quantity: map['quantity'] ?? 1,
    );
  }
}

class CartService extends ChangeNotifier {
  CartService();

  static const String _cartCollection = 'carts'; // Using 'carts' as requested
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<CartItem> _items = [];
  bool _isLoading = false;
  User? _currentUser;
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUser?.uid;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Initialize cart service with user context and set up real-time listener
  Future<void> initialize(User? user) async {
    print('CartService: Initializing for user ${user?.uid}');
    
    // Dispose of previous listener if exists
    _cartSubscription?.cancel();
    _cartSubscription = null;
    _clearCartData();
    
    _currentUser = user;
    
    if (_currentUser != null) {
      await _setupCartListener();
    } else {
      _clearCartData();
    }
  }

  /// Dispose of cart service and clean up resources
  @override
  void dispose() {
    print('CartService: Disposing cart service');
    _cartSubscription?.cancel();
    _cartSubscription = null;
    _clearCartData();
    super.dispose();
  }

  /// Clear local cart data
  void _clearCartData() {
    print('CartService: Clearing local cart data');
    _items.clear();
    _isLoading = false;
    notifyListeners();
  }

  /// Set up real-time cart listener for the current user
  Future<void> _setupCartListener() async {
    if (_currentUser == null) return;
    
    print('CartService: Setting up cart listener for user ${_currentUser!.uid}');
    _isLoading = true;
    notifyListeners();

    try {
      // Set up real-time listener for cart changes
      _cartSubscription = _firestore
          .collection(_cartCollection)
          .doc(_currentUser!.uid)
          .collection('items')
          .snapshots()
          .listen(
            (snapshot) => _handleCartSnapshot(snapshot),
            onError: (error) {
              print('CartService: Error in cart listener: $error');
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      print('CartService: Error setting up cart listener: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle cart snapshot updates from Firestore
  Future<void> _handleCartSnapshot(QuerySnapshot snapshot) async {
    print('CartService: Handling cart snapshot with ${snapshot.docs.length} items');
    
    try {
      final List<CartItem> newItems = [];
      
      for (final doc in snapshot.docs) {
        final cartData = doc.data() as Map<String, dynamic>;
        
        // Fetch the full product details
        final productDoc = await _firestore
            .collection('products')
            .doc(cartData['productId'])
            .get();
            
        if (productDoc.exists) {
          final product = Product.fromMap(productDoc.data()!, productDoc.id);
          final cartItem = CartItem.fromMap(cartData, product);
          newItems.add(cartItem);
          print('CartService: Loaded ${cartItem.productName} (qty: ${cartItem.quantity})');
        } else {
          print('CartService: Product ${cartData['productId']} not found, skipping');
        }
      }
      
      _items.clear();
      _items.addAll(newItems);
      _isLoading = false;
      
      print('CartService: Cart updated with ${_items.length} items for user ${_currentUser!.uid}');
      notifyListeners();
    } catch (e) {
      print('CartService: Error handling cart snapshot: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add product to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (_currentUser == null) {
      print('CartService: No user logged in, cannot add to cart');
      return;
    }

    print('CartService: Adding ${product.name} to cart for user ${_currentUser!.uid}');

    try {
      final cartRef = _firestore
          .collection(_cartCollection)
          .doc(_currentUser!.uid)
          .collection('items')
          .doc(product.id);

      final cartDoc = await cartRef.get();
      
      if (cartDoc.exists) {
        // Update existing item
        final currentQuantity = (cartDoc.data()?['quantity'] ?? 0) as int;
        final newQuantity = currentQuantity + quantity;
        
        await cartRef.update({
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('CartService: Updated ${product.name} quantity to $newQuantity in Firestore');
      } else {
        // Add new item
        final cartItem = CartItem(
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productImage: product.imageUrl,
          product: product,
          quantity: quantity,
        );
        
        await cartRef.set(cartItem.toMap());
        print('CartService: Added new ${product.name} to Firestore');
      }
    } catch (e) {
      print('CartService: Error adding to cart: $e');
    }
  }

  /// Remove product from cart
  Future<void> removeFromCart(String productId) async {
    if (_currentUser == null) {
      print('CartService: No user logged in, cannot remove from cart');
      return;
    }

    print('CartService: Removing product $productId from cart for user ${_currentUser!.uid}');

    try {
      await _firestore
          .collection(_cartCollection)
          .doc(_currentUser!.uid)
          .collection('items')
          .doc(productId)
          .delete();
          
      print('CartService: Removed product $productId from Firestore');
    } catch (e) {
      print('CartService: Error removing from cart: $e');
    }
  }

  /// Update product quantity in cart
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    if (_currentUser == null) return;

    try {
      await _firestore
          .collection(_cartCollection)
          .doc(_currentUser!.uid)
          .collection('items')
          .doc(productId)
          .update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('CartService: Updated product $productId quantity to $quantity');
    } catch (e) {
      print('CartService: Error updating quantity: $e');
    }
  }

  /// Increment product quantity
  Future<void> incrementQuantity(String productId) async {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        productName: '',
        productPrice: 0,
        productImage: '',
        product: Product(
          id: '',
          name: '',
          description: '',
          price: 0,
          category: '',
          images: [],
          stock: 0,
          createdBy: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: 0,
      ),
    );
    
    if (item.productId.isNotEmpty) {
      await updateQuantity(productId, item.quantity + 1);
    }
  }

  /// Decrement product quantity
  Future<void> decrementQuantity(String productId) async {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        productName: '',
        productPrice: 0,
        productImage: '',
        product: Product(
          id: '',
          name: '',
          description: '',
          price: 0,
          category: '',
          images: [],
          stock: 0,
          createdBy: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: 0,
      ),
    );
    
    if (item.productId.isNotEmpty) {
      final newQuantity = item.quantity - 1;
      if (newQuantity > 0) {
        await updateQuantity(productId, newQuantity);
      } else {
        await removeFromCart(productId);
      }
    }
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    if (_currentUser == null) return;

    try {
      final cartRef = _firestore
          .collection(_cartCollection)
          .doc(_currentUser!.uid)
          .collection('items');
          
      final cartSnapshot = await cartRef.get();
      
      final batch = _firestore.batch();
      for (final doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('CartService: Cleared cart for user ${_currentUser!.uid}');
    } catch (e) {
      print('CartService: Error clearing cart: $e');
    }
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  /// Get quantity of specific product in cart
  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        productName: '',
        productPrice: 0,
        productImage: '',
        product: Product(
          id: '',
          name: '',
          description: '',
          price: 0,
          category: '',
          images: [],
          stock: 0,
          createdBy: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ), 
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}
