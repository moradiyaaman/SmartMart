import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _profilesCollection = 'userProfiles';
  static const String _addressesCollection = 'addresses';

  // Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Warning: getCurrentUserProfile timeout');
              throw Exception('Network timeout');
            },
          );

      if (!doc.exists) return null;

      final profile = UserProfile.fromFirestore(doc);
      
      // Load addresses with timeout handling
      final addresses = await getUserAddresses(user.uid);
      
      return profile.copyWith(addresses: addresses);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create or update user profile
  static Future<bool> saveUserProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Error: No authenticated user found');
      return false;
    }

    try {
      print('Attempting to save profile for user: ${user.uid}');
      print('Profile data: ${profile.toMap()}');
      
      await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .set(profile.toMap(), SetOptions(merge: true));
      
      print('Profile saved successfully');
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  // Create initial profile for new user
  static Future<bool> createInitialProfile(String email) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final profile = UserProfile(
        userId: user.uid,
        email: email,
        firstName: '',
        lastName: '',
        phoneNumber: '',
        profileCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .set(profile.toMap());
      return true;
    } catch (e) {
      print('Error creating initial profile: $e');
      return false;
    }
  }

  // Get user addresses
  static Future<List<UserAddress>> getUserAddresses(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_profilesCollection)
          .doc(userId)
          .collection(_addressesCollection)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Warning: getUserAddresses timeout, returning empty list');
              throw Exception('Network timeout');
            },
          );

      // Sort in memory to avoid Firebase composite index requirement
      final addresses = querySnapshot.docs
          .map((doc) => UserAddress.fromFirestore(doc))
          .toList();
      
      // Sort default addresses first, then by creation date
      addresses.sort((a, b) {
        // First sort by isDefault (true first)
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        // Then sort by createdAt (older first)
        return a.createdAt.compareTo(b.createdAt);
      });

      return addresses;
    } catch (e) {
      print('Error getting user addresses: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Add new address
  static Future<String?> addAddress(UserAddress address) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // If this is the first address or marked as default, make it default
      final existingAddresses = await getUserAddresses(user.uid);
      final isFirstAddress = existingAddresses.isEmpty;
      
      final addressData = address.copyWith(
        isDefault: address.isDefault || isFirstAddress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // If setting as default, update other addresses
      if (addressData.isDefault) {
        await _setOtherAddressesNonDefault(user.uid);
      }

      final docRef = await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .collection(_addressesCollection)
          .add(addressData.toMap());

      // Update profile with default address ID if this is the default
      if (addressData.isDefault) {
        await _firestore
            .collection(_profilesCollection)
            .doc(user.uid)
            .update({
          'defaultAddressId': docRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return docRef.id;
    } catch (e) {
      print('Error adding address: $e');
      return null;
    }
  }

  // Update address
  static Future<bool> updateAddress(UserAddress address) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // If setting as default, update other addresses
      if (address.isDefault) {
        await _setOtherAddressesNonDefault(user.uid);
        
        // Update profile default address ID
        await _firestore
            .collection(_profilesCollection)
            .doc(user.uid)
            .update({
          'defaultAddressId': address.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .collection(_addressesCollection)
          .doc(address.id)
          .update(address.copyWith(updatedAt: DateTime.now()).toMap());

      return true;
    } catch (e) {
      print('Error updating address: $e');
      return false;
    }
  }

  // Delete address
  static Future<bool> deleteAddress(String addressId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .collection(_addressesCollection)
          .doc(addressId)
          .delete();

      // If this was the default address, set another as default
      final remainingAddresses = await getUserAddresses(user.uid);
      if (remainingAddresses.isNotEmpty) {
        final newDefault = remainingAddresses.first;
        await updateAddress(newDefault.copyWith(isDefault: true));
      } else {
        // No addresses left, clear default
        await _firestore
            .collection(_profilesCollection)
            .doc(user.uid)
            .update({
          'defaultAddressId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  // Set default address
  static Future<bool> setDefaultAddress(String addressId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Set all addresses as non-default
      await _setOtherAddressesNonDefault(user.uid);

      // Set the selected address as default
      await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .collection(_addressesCollection)
          .doc(addressId)
          .update({
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update profile default address ID
      await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .update({
        'defaultAddressId': addressId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error setting default address: $e');
      return false;
    }
  }

  // Helper method to set other addresses as non-default
  static Future<void> _setOtherAddressesNonDefault(String userId) async {
    final batch = _firestore.batch();
    
    final addresses = await _firestore
        .collection(_profilesCollection)
        .doc(userId)
        .collection(_addressesCollection)
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in addresses.docs) {
      batch.update(doc.reference, {
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Check if user profile is completed
  static Future<bool> isProfileCompleted() async {
    try {
      final profile = await getCurrentUserProfile();
      if (profile == null) return false;
      
      // A profile is considered completed if basic info is filled
      return profile.firstName.isNotEmpty &&
             profile.lastName.isNotEmpty &&
             profile.phoneNumber.isNotEmpty;
    } catch (e) {
      print('Error checking profile completion: $e');
      // Return false on error to force profile setup if network issues exist
      return false;
    }
  }

  // Mark profile as completed
  static Future<bool> markProfileCompleted() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .update({
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error marking profile completed: $e');
      return false;
    }
  }

  // Get default address
  static Future<UserAddress?> getDefaultAddress() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection(_profilesCollection)
          .doc(user.uid)
          .collection(_addressesCollection)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserAddress.fromFirestore(querySnapshot.docs.first);
      }
      
      // If no default address, return the first address if any exists
      final allAddresses = await getUserAddresses(user.uid);
      return allAddresses.isNotEmpty ? allAddresses.first : null;
    } catch (e) {
      print('Error getting default address: $e');
      return null;
    }
  }

  // Stream user profile changes
  static Stream<UserProfile?> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(_profilesCollection)
        .doc(user.uid)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return null;
      
      final profile = UserProfile.fromFirestore(doc);
      final addresses = await getUserAddresses(user.uid);
      
      return profile.copyWith(addresses: addresses);
    });
  }

  // Stream user addresses
  static Stream<List<UserAddress>> getUserAddressesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_profilesCollection)
        .doc(user.uid)
        .collection(_addressesCollection)
        .snapshots()
        .map((snapshot) {
      // Sort in memory to avoid Firebase composite index requirement
      final addresses = snapshot.docs
          .map((doc) => UserAddress.fromFirestore(doc))
          .toList();
      
      // Sort default addresses first, then by creation date
      addresses.sort((a, b) {
        // First sort by isDefault (true first)
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        // Then sort by createdAt (older first)
        return a.createdAt.compareTo(b.createdAt);
      });

      return addresses;
    });
  }
}
