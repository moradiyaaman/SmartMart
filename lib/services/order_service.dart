import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart' as models;
import 'cart_service.dart';

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
    
    // Clear cart after successful order creation
    CartService().clearCart();
    
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

  // Update order status (admin function)
  Future<void> updateOrderStatus(String orderId, models.OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Cancel order (user function)
  Future<void> cancelOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final order = await getOrder(orderId);
      if (order == null) throw Exception('Order not found');
      
      if (order.userId != user.uid) {
        throw Exception('Not authorized to cancel this order');
      }
      
      if (order.status != models.OrderStatus.pending && order.status != models.OrderStatus.confirmed) {
        throw Exception('Order cannot be cancelled at this stage');
      }

      await updateOrderStatus(orderId, models.OrderStatus.cancelled);
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
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
