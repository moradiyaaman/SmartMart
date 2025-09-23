import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTest {
  static Future<void> testFirebaseConnection() async {
    try {
      print('=== FIREBASE CONNECTION TEST ===');
      
      // Test Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.email ?? 'No user logged in'}');
      print('User UID: ${user?.uid ?? 'N/A'}');
      
      if (user != null) {
        // Test Firestore write
        print('Testing Firestore write...');
        await FirebaseFirestore.instance
            .collection('test')
            .doc('connection_test')
            .set({
          'timestamp': FieldValue.serverTimestamp(),
          'message': 'Firebase connection test',
          'userId': user.uid,
        });
        print('✅ Firestore write successful');
        
        // Test Firestore read
        print('Testing Firestore read...');
        final doc = await FirebaseFirestore.instance
            .collection('test')
            .doc('connection_test')
            .get();
        print('✅ Firestore read successful: ${doc.exists}');
        
        // Test userProfiles collection specifically
        print('Testing userProfiles collection...');
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(user.uid)
            .set({
          'email': user.email,
          'firstName': 'Test',
          'lastName': 'User',
          'phoneNumber': '1234567890',
          'gender': 'Test',
          'profileCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ userProfiles collection write successful');
        
      } else {
        print('❌ No authenticated user found');
      }
      
    } catch (e) {
      print('❌ Firebase test error: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
    }
  }
}
