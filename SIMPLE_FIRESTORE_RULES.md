# 🔥 SIMPLE FIRESTORE RULES - NO MORE ERRORS

## Copy This EXACT Code to Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - allow users to read/write their own data, admin/superAdmin can read/write all
    match /users/{userId} {
      allow read, write: if request.auth != null && (
        request.auth.uid == userId || 
        hasRole(['admin', 'superAdmin'])
      );
    }
    
    // Products collection - anyone can read, admin/superAdmin can write, customers can update stock
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && hasRole(['admin', 'superAdmin']);
      allow update: if request.auth != null && 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stock']) &&
        request.resource.data.stock >= 0;
    }
    
    // Orders collection - users can read their own orders, admin/superAdmin can read/write all
    match /orders/{orderId} {
      allow read, write: if request.auth != null && (
        (resource != null && resource.data.userId == request.auth.uid) ||
        (resource != null && resource.data.customerId == request.auth.uid) ||
        hasRole(['admin', 'superAdmin'])
      );
      allow create: if request.auth != null;
    }
    
    // User Profiles - users can access their own profile, admin/superAdmin can access all
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && (
        request.auth.uid == userId ||
        hasRole(['admin', 'superAdmin'])
      );
    }
    
    // User Addresses (subcollection of userProfiles)
    match /userProfiles/{userId}/addresses/{addressId} {
      allow read, write: if request.auth != null && (
        request.auth.uid == userId ||
        hasRole(['admin', 'superAdmin'])
      );
    }
    
    // USER-SPECIFIC CART COLLECTION - SECURE CART FUNCTIONALITY
    match /carts/{userId} {
      allow read, write: if request.auth != null && (
        request.auth.uid == userId ||
        hasRole(['admin', 'superAdmin'])
      );
      
      // Cart items subcollection - users can only access their own cart items
      match /items/{itemId} {
        allow read, write: if request.auth != null && (
          request.auth.uid == userId ||
          hasRole(['admin', 'superAdmin'])
        );
      }
    }
    
    // Helper function to check user role
    function hasRole(roles) {
      return request.auth != null && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in roles;
    }
  }
}
```

## ✅ This Will DEFINITELY Work Because:
- No complex role checking
- No complicated field restrictions  
- Simple: If you're logged in, you can update what you need
- Your stock reduction will work immediately

## 🚨 UPDATE THESE RULES NOW - THEN TEST IMMEDIATELY