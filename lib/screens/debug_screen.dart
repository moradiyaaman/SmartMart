import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Firestore'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('No products found in Firestore'),
                  SizedBox(height: 8),
                  Text('Make sure you have:'),
                  Text('• A "products" collection'),
                  Text('• Products with isActive: true'),
                  Text('• Valid product data structure'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document ID: ${doc.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Raw Data:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text('Active: ${data['isActive'] ?? 'null'}'),
                            backgroundColor: (data['isActive'] == true) 
                                ? Colors.green.shade100 
                                : Colors.red.shade100,
                          ),
                          const SizedBox(width: 8),
                          if (data.containsKey('images'))
                            Chip(
                              label: Text('Images: ${(data['images'] as List?)?.length ?? 0}'),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          if (data.containsKey('imageUrls'))
                            Chip(
                              label: Text('ImageUrls: ${(data['imageUrls'] as List?)?.length ?? 0}'),
                              backgroundColor: Colors.orange.shade100,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "mixed",
            onPressed: () => _createMultipleTestProducts(context),
            child: const Icon(Icons.add_box),
            tooltip: 'Mixed URL + Local images',
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "local",
            onPressed: () => _createLocalAssetProducts(context),
            child: const Icon(Icons.folder),
            tooltip: 'Local asset images only',
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "update",
            onPressed: () => _updateExistingProduct(context),
            child: const Icon(Icons.edit),
            tooltip: 'Update existing product',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "add",
            onPressed: () => _createTestProduct(context),
            child: const Icon(Icons.add),
            tooltip: 'Add single URL product',
          ),
        ],
      ),
    );
  }

  Future<void> _createTestProduct(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': 'Test Product',
        'description': 'This is a test product created by the debug screen',
        'price': 299.99,
        'category': 'Electronics',
        'images': [
          'https://picsum.photos/400/400?random=1', // Free reliable image service
        ],
        'stock': 10,
        'rating': 4.5,
        'reviewCount': 25,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test product created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating test product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createLocalAssetProducts(BuildContext context) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final products = [
        {
          'name': 'Local iPhone (Asset)',
          'description': 'iPhone using only local asset image',
          'price': 99999.0,
          'category': 'Electronics',
          'images': ['assets/images/google_logo.png'],
          'stock': 25,
          'rating': 4.5,
          'reviewCount': 128,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Local Laptop (Asset)',
          'description': 'Laptop using only local asset image',
          'price': 79999.0,
          'category': 'Electronics',
          'images': ['assets/images/google_logo.png'],
          'stock': 15,
          'rating': 4.3,
          'reviewCount': 95,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];
      
      for (var product in products) {
        final docRef = FirebaseFirestore.instance.collection('products').doc();
        batch.set(docRef, product);
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local asset products created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating local products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateExistingProduct(BuildContext context) async {
    try {
      // Update the existing product to use a working image
      await FirebaseFirestore.instance
          .collection('products')
          .doc('product-001')
          .update({
        'images': [
          'https://picsum.photos/400/400?random=2', // Free reliable image service
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Existing product updated with web image!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createMultipleTestProducts(BuildContext context) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final products = [
        {
          'name': 'iPhone 15 Pro (URL Image)',
          'description': 'Latest iPhone with titanium design - using web image',
          'price': 99999.0,
          'category': 'Electronics',
          'images': ['https://picsum.photos/400/400?random=10'],
          'stock': 25,
          'rating': 4.5,
          'reviewCount': 128,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Samsung Galaxy S24 (Local Asset)',
          'description': 'Premium Android smartphone - using local image',
          'price': 79999.0,
          'category': 'Electronics',
          'images': ['assets/images/google_logo.png'], // Using existing local asset
          'stock': 15,
          'rating': 4.3,
          'reviewCount': 95,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'MacBook Air M3 (URL Image)',
          'description': 'Lightweight laptop with M3 chip - using web image',
          'price': 119999.0,
          'category': 'Electronics',
          'images': ['https://picsum.photos/400/400?random=12'],
          'stock': 8,
          'rating': 4.7,
          'reviewCount': 67,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'AirPods Pro 2 (Mixed Images)',
          'description': 'Wireless earbuds - mix of local and web images',
          'price': 24999.0,
          'category': 'Electronics',
          'images': [
            'https://picsum.photos/400/400?random=13',
            'assets/images/google_logo.png'
          ], // Mix of URL and local asset
          'stock': 30,
          'rating': 4.4,
          'reviewCount': 203,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];
      
      for (var product in products) {
        final docRef = FirebaseFirestore.instance.collection('products').doc();
        batch.set(docRef, product);
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Multiple test products created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
