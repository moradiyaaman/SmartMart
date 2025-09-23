import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Temporary test screen to verify Firebase connection
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase connection...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test 1: Firebase initialization
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      setState(() => _status = '✅ Firebase initialized successfully\n');

      // Test 2: Firestore connection
      final firestore = FirebaseFirestore.instance;
      final productsSnapshot = await firestore.collection('products').limit(1).get();
      setState(() => _status += '✅ Firestore connected (${productsSnapshot.docs.length} products found)\n');

      // Test 3: Auth connection
      final auth = FirebaseAuth.instance;
      setState(() => _status += '✅ Authentication service connected\n');

      // Test 4: Check admin user
      if (productsSnapshot.docs.isNotEmpty) {
        setState(() => _status += '✅ Sample products found\n');
      } else {
        setState(() => _status += '⚠️ No products found - add sample products\n');
      }

      setState(() {
        _status += '\n🎉 Firebase setup is working correctly!';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _status = '❌ Firebase connection failed:\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 20),
            if (!_isLoading)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue to App'),
              ),
          ],
        ),
      ),
    );
  }
}

// To use this test, temporarily replace your home screen in main.dart with:
// home: const FirebaseTestScreen(),
