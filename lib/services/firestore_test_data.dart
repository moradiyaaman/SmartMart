import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add sample products
  static Future<void> addSampleProducts() async {
    final products = [
      {
        'name': 'iPhone 15',
        'description': 'Latest iPhone with advanced features',
        'price': 79999,
        'category': 'Electronics',
        'images': ['assets/images/iphone15.jpg'],
        'stock': 25,
        'rating': 4.5,
        'reviewCount': 120,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Samsung Galaxy S24',
        'description': 'Premium Android smartphone',
        'price': 69999,
        'category': 'Electronics',
        'images': ['assets/images/galaxy_s24.jpg'],
        'stock': 30,
        'rating': 4.3,
        'reviewCount': 85,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'MacBook Air M3',
        'description': 'Lightweight laptop with M3 chip',
        'price': 119999,
        'category': 'Computers',
        'images': ['assets/images/macbook_air.jpg'],
        'stock': 15,
        'rating': 4.7,
        'reviewCount': 65,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Sony WH-1000XM5',
        'description': 'Premium noise-cancelling headphones',
        'price': 29999,
        'category': 'Audio',
        'images': ['assets/images/sony_headphones.jpg'],
        'stock': 40,
        'rating': 4.6,
        'reviewCount': 95,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var product in products) {
      await _firestore.collection('products').add(product);
    }
    print('Sample products added successfully!');
  }

  // Add sample categories
  static Future<void> addSampleCategories() async {
    final categories = [
      {
        'name': 'Electronics',
        'description': 'Smartphones, tablets, and electronic gadgets',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Computers',
        'description': 'Laptops, desktops, and computer accessories',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Audio',
        'description': 'Headphones, speakers, and audio equipment',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Fashion',
        'description': 'Clothing, shoes, and fashion accessories',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var category in categories) {
      await _firestore.collection('categories').add(category);
    }
    print('Sample categories added successfully!');
  }

  // Initialize all sample data
  static Future<void> initializeSampleData() async {
    try {
      await addSampleCategories();
      await addSampleProducts();
      print('All sample data initialized successfully!');
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
}
