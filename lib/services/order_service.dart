import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart' as models;

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new order from cart items
  Future<String> createOrder({
    required List<dynamic> cartItems,
    required models.UserAddress deliveryAddress,
    required String paymentMethod,
    String? paymentId,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Convert cart items to order items
    final orderItems = cartItems.map((item) => models.OrderItem.fromCartItem(item)).toList();
    
    // Calculate totals
    final subtotal = orderItems.fold(0.0, (total, item) => total + item.totalPrice);
    final deliveryFee = subtotal > 500 ? 0.0 : 50.0; // Free delivery above ₹500
    final tax = subtotal * 0.18; // 18% GST
    final totalAmount = subtotal + deliveryFee + tax;

    final now = DateTime.now();

    final order = models.Order(
      id: '', // Will be set by Firestore
      userId: user.uid,
      userName: user.displayName ?? '',
      userEmail: user.email ?? '',
      items: orderItems,
      totalAmount: totalAmount,
      status: models.OrderStatus.pending,
      shippingAddress: models.Address(
        name: deliveryAddress.fullName,
        phone: deliveryAddress.phoneNumber,
        street: deliveryAddress.addressLine1,
        city: deliveryAddress.city,
        state: deliveryAddress.state,
        zipCode: deliveryAddress.pincode,
        country: 'India',
      ),
      paymentMethod: paymentMethod,
      createdAt: now,
      updatedAt: now,
    );

    // Save to Firestore
    final docRef = await _firestore.collection('orders').add(order.toMap());

    // Decrement stock for each product in the order
    for (final item in orderItems) {
      final productRef = _firestore.collection('products').doc(item.productId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) return;
        final currentStock = (snapshot.data()?['stock'] ?? 0) as int;
        final newStock = currentStock - item.quantity;
        transaction.update(productRef, {'stock': newStock < 0 ? 0 : newStock});
      });
    }

    // Clear cart after successful order creation
    // Note: Cart will be cleared automatically via the CartService instance
    // that's managed by the Provider system
    
    return docRef.id;
  }

  // Get user's orders - simplified to avoid index requirements
  Stream<List<models.Order>> getUserOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // Use simple query first, then sort manually to avoid index requirements
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => models.Order.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort manually by creation date (newest first)
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  // Get a specific order
  Future<models.Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return models.Order.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Update order status (admin function) - SIMPLIFIED
  Future<void> updateOrderStatus(String orderId, models.OrderStatus status) async {
    try {
      print('🔄 SIMPLE UPDATE: Changing order $orderId to $status');
      
      // If admin is changing to cancelled or refunded, restore stock
      if (status == models.OrderStatus.cancelled || status == models.OrderStatus.refunded) {
        final order = await getOrder(orderId);
        if (order != null) {
          print('� SIMPLE UPDATE: Restoring stock for ${order.items.length} items');
          
          for (final item in order.items) {
            final productRef = _firestore.collection('products').doc(item.productId);
            final productDoc = await productRef.get();
            
            if (productDoc.exists) {
              final currentStock = (productDoc.data()?['stock'] ?? 0) as int;
              final newStock = currentStock + item.quantity;
              
              await productRef.update({'stock': newStock});
              print('🔄 SIMPLE UPDATE: Restored ${item.quantity} units for ${item.productId}');
            }
          }
        }
      }
      
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('✅ SIMPLE UPDATE: Order status updated successfully');
    } catch (e) {
      print('❌ SIMPLE UPDATE ERROR: $e');
      rethrow;
    }
  }

  // Cancel order (user function) - SIMPLE VERSION
  Future<void> cancelOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('🚀 SIMPLE CANCEL: Starting cancel for order $orderId');
      
      final order = await getOrder(orderId);
      if (order == null) throw Exception('Order not found');
      
      if (order.userId != user.uid) {
        throw Exception('Not authorized to cancel this order');
      }
      
      if (order.status != models.OrderStatus.pending && order.status != models.OrderStatus.confirmed) {
        throw Exception('Order cannot be cancelled at this stage');
      }

      print('🚀 SIMPLE CANCEL: Found order with ${order.items.length} items');
      
      // STEP 1: Restore stock FIRST (simple approach)
      for (final item in order.items) {
        print('🚀 SIMPLE CANCEL: Restoring ${item.quantity} units for product ${item.productId}');
        
        final productRef = _firestore.collection('products').doc(item.productId);
        final productDoc = await productRef.get();
        
        if (productDoc.exists) {
          final currentStock = (productDoc.data()?['stock'] ?? 0) as int;
          final newStock = currentStock + item.quantity;
          
          await productRef.update({'stock': newStock});
          print('🚀 SIMPLE CANCEL: Updated stock from $currentStock to $newStock');
        }
      }
      
      // STEP 2: Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('🚀 SIMPLE CANCEL: Order cancelled successfully!');
    } catch (e) {
      print('❌ SIMPLE CANCEL ERROR: $e');
      rethrow;
    }
  }

  // Refund order (admin function) - SIMPLIFIED
  Future<void> refundOrder(String orderId) async {
    try {
      print('🔄 SIMPLE REFUND: Starting refund for order $orderId');
      
      final order = await getOrder(orderId);
      if (order == null) throw Exception('Order not found');
      
      if (order.status != models.OrderStatus.delivered && order.status != models.OrderStatus.confirmed) {
        throw Exception('Order cannot be refunded at this stage');
      }

      // Restore stock first
      for (final item in order.items) {
        final productRef = _firestore.collection('products').doc(item.productId);
        final productDoc = await productRef.get();
        
        if (productDoc.exists) {
          final currentStock = (productDoc.data()?['stock'] ?? 0) as int;
          final newStock = currentStock + item.quantity;
          
          await productRef.update({'stock': newStock});
          print('🔄 SIMPLE REFUND: Restored ${item.quantity} units for ${item.productId}');
        }
      }
      
      // Update status to refunded
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'refunded',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('✅ SIMPLE REFUND: Order refunded successfully!');
    } catch (e) {
      print('❌ SIMPLE REFUND ERROR: $e');
      rethrow;
    }
  }

  // 🧪 TEST METHOD - Direct stock restoration test
  Future<void> testStockRestoration(String orderId) async {
    try {
      print('🧪 TEST: Starting direct stock restoration test for order $orderId');
      
      // Get the order
      final order = await getOrder(orderId);
      if (order == null) {
        print('❌ TEST: Order not found');
        return;
      }
      
      print('🧪 TEST: Order found with ${order.items.length} items');
      print('🧪 TEST: Current order status: ${order.status}');
      
      // Restore stock for each item
      for (final item in order.items) {
        print('🧪 TEST: Processing item ${item.productName} (${item.productId})');
        print('🧪 TEST: Quantity to restore: ${item.quantity}');
        
        // Get current stock
        final productDoc = await _firestore.collection('products').doc(item.productId).get();
        if (productDoc.exists) {
          final currentStock = (productDoc.data()?['stock'] ?? 0) as int;
          print('🧪 TEST: Current stock: $currentStock');
          
          // Update stock
          final newStock = currentStock + item.quantity;
          await _firestore.collection('products').doc(item.productId).update({'stock': newStock});
          
          print('🧪 TEST: ✅ Updated stock from $currentStock to $newStock');
        } else {
          print('🧪 TEST: ❌ Product not found in database');
        }
      }
      
      print('🧪 TEST: Stock restoration test completed!');
    } catch (e) {
      print('🧪 TEST: ❌ Error during test: $e');
    }
  }

  // Get order statistics for admin
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      final orders = ordersSnapshot.docs
          .map((doc) => models.Order.fromMap(doc.data(), doc.id))
          .toList();

      final totalOrders = orders.length;
      final totalRevenue = orders.fold(0.0, (total, order) => total + order.totalAmount);
      final pendingOrders = orders.where((o) => o.status == models.OrderStatus.pending).length;
      final completedOrders = orders.where((o) => o.status == models.OrderStatus.delivered).length;

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
      };
    } catch (e) {
      print('Error getting order stats: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'pendingOrders': 0,
        'completedOrders': 0,
        'averageOrderValue': 0.0,
      };
    }
  }

  // Search orders
  Future<List<models.Order>> searchOrders(String query) async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      final orders = ordersSnapshot.docs
          .map((doc) => models.Order.fromMap(doc.data(), doc.id))
          .toList();

      return orders.where((order) {
        final searchQuery = query.toLowerCase();
        return order.id.toLowerCase().contains(searchQuery) ||
               order.userName.toLowerCase().contains(searchQuery) ||
               order.userEmail.toLowerCase().contains(searchQuery) ||
               order.items.any((item) => 
                   item.productName.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      print('Error searching orders: $e');
      return [];
    }
  }
}
