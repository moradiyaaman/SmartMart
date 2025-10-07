# Updated Firestore Rules - Fix Stock Reduction Permission

## Replace your current rules with this updated version:

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
    
    // Products collection - anyone can read, admin/superAdmin can write, customers can update stock only
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && hasRole(['admin', 'superAdmin']);
      // NEW: Allow authenticated customers to update ONLY the stock field for order processing
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
      // NEW: Allow customers to create new orders (resource is null for new documents)
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
    
    // Helper function to check user role
    function hasRole(roles) {
      return request.auth != null && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in roles;
    }
  }
}
```

## 🔑 Key Changes Made:

### 1. **Products Collection** - Added stock update permission:
```javascript
// NEW: Allow authenticated customers to update ONLY the stock field for order processing
allow update: if request.auth != null && 
  request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stock']) &&
  request.resource.data.stock >= 0;
```

### 2. **Orders Collection** - Added order creation permission:
```javascript
// NEW: Allow customers to create new orders (resource is null for new documents)
allow create: if request.auth != null;
```

## ✅ What This Fixes:

- **Customers can now update product stock** when placing orders
- **Only the stock field can be updated** by customers (secure)
- **Stock cannot go negative** (validation included)
- **Admins still have full control** over products
- **All your existing permissions remain intact**

## 🚀 Apply These Rules:

1. Copy the entire code block above
2. Go to Firebase Console → Firestore Database → Rules  
3. Replace ALL your current rules with this updated version
4. Click "Publish"
5. Wait 30 seconds and test your order!

This keeps your role-based security while specifically allowing the stock reduction feature to work! 🎯