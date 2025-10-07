import 'package:flutter/material.dart';
import '../services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockTestScreen extends StatefulWidget {
  const StockTestScreen({super.key});

  @override
  State<StockTestScreen> createState() => _StockTestScreenState();
}

class _StockTestScreenState extends State<StockTestScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  String _output = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Test Screen'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Stock Restoration Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _orderIdController,
              decoration: const InputDecoration(
                labelText: 'Order ID',
                border: OutlineInputBorder(),
                hintText: 'Enter order ID to test stock restoration',
              ),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () async {
                if (_orderIdController.text.trim().isEmpty) {
                  setState(() {
                    _output = '❌ Please enter an order ID';
                  });
                  return;
                }
                
                setState(() {
                  _output = '🔄 Testing stock restoration...';
                });
                
                try {
                  await OrderService().testStockRestoration(_orderIdController.text.trim());
                  setState(() {
                    _output = '✅ Stock restoration test completed! Check debug console for details.';
                  });
                } catch (e) {
                  setState(() {
                    _output = '❌ Error: $e';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('🧪 Test Stock Restoration'),
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            
            TextField(
              controller: _productIdController,
              decoration: const InputDecoration(
                labelText: 'Product ID',
                border: OutlineInputBorder(),
                hintText: 'Enter product ID to check stock',
              ),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () async {
                if (_productIdController.text.trim().isEmpty) {
                  setState(() {
                    _output = '❌ Please enter a product ID';
                  });
                  return;
                }
                
                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('products')
                      .doc(_productIdController.text.trim())
                      .get();
                  
                  if (doc.exists) {
                    final stock = doc.data()?['stock'] ?? 'N/A';
                    final name = doc.data()?['name'] ?? 'Unknown';
                    setState(() {
                      _output = '📦 Product: $name\n📊 Current Stock: $stock';
                    });
                  } else {
                    setState(() {
                      _output = '❌ Product not found';
                    });
                  }
                } catch (e) {
                  setState(() {
                    _output = '❌ Error: $e';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('📊 Check Product Stock'),
            ),
            
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Output:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _output.isEmpty ? 'No output yet...' : _output,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _productIdController.dispose();
    super.dispose();
  }
}