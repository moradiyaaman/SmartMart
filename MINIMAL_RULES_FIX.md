# MINIMAL FIRESTORE RULES FIX - Only Change 2 Sections

## Replace ONLY these two sections in your existing rules:

### 1. Replace Products Section:
**Old:**
```javascript
// Products collection - anyone can read, admin/superAdmin can write
match /products/{productId} {
  allow read: if true;
  allow write: if request.auth != null && hasRole(['admin', 'superAdmin']);
}
```

**New:**
```javascript
// Products collection - anyone can read, admin/superAdmin can write, customers can update stock
match /products/{productId} {
  allow read: if true;
  allow write: if request.auth != null && hasRole(['admin', 'superAdmin']);
  // Allow customers to update ONLY stock field for orders
  allow update: if request.auth != null && 
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stock']) &&
    request.resource.data.stock >= 0;
}
```

### 2. Replace Orders Section:
**Old:**
```javascript
// Orders collection - users can read their own orders, admin/superAdmin can read/write all
match /orders/{orderId} {
  allow read, write: if request.auth != null && (
    (resource != null && resource.data.userId == request.auth.uid) ||
    (resource != null && resource.data.customerId == request.auth.uid) ||
    hasRole(['admin', 'superAdmin'])
  );
}
```

**New:**
```javascript
// Orders collection - users can read their own orders, admin/superAdmin can read/write all
match /orders/{orderId} {
  allow read, write: if request.auth != null && (
    (resource != null && resource.data.userId == request.auth.uid) ||
    (resource != null && resource.data.customerId == request.auth.uid) ||
    hasRole(['admin', 'superAdmin'])
  );
  // Allow customers to create new orders
  allow create: if request.auth != null;
}
```

## 🎯 Complete Fixed Rules:
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
      // Allow customers to update ONLY stock field for orders
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
      // Allow customers to create new orders
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

## 🔒 What These Changes Do:
- ✅ **Products**: Customers can now update ONLY the stock field (secure)
- ✅ **Orders**: Customers can now create new orders
- ✅ **Everything else stays exactly the same**
- ✅ **All your other features remain unchanged**

Copy the complete fixed rules above and replace your current rules. This minimal change will fix your stock reduction issue! 🎯