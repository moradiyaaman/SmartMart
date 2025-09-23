import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> orders = [
      {'orderId': '001', 'status': 'Processing'},
      {'orderId': '002', 'status': 'Shipped'},
      {'orderId': '003', 'status': 'Delivered'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Order ID: ${orders[index]['orderId']}'),
            subtitle: Text('Status: ${orders[index]['status']}'),
            leading: const Icon(Icons.local_shipping),
          );
        },
      ),
    );
  }
}
