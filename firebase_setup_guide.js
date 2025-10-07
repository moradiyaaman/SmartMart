// Firebase Setup Guide for SmartMart App
// Run this in Firebase Console -> Firestore -> Rules

// 1. FIRESTORE SECURITY RULES
// Copy and paste this into Firestore Rules:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to products for everyone
    match /products/{productId} {
      allow read: if true;
      // Allow admin full write access
      allow write: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      // Allow authenticated users to update only the stock field (for order processing)
      allow update: if request.auth != null &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stock']) &&
        request.resource.data.stock >= 0;
    }
    
    // Allow users to read/write their own orders
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
    
    // Allow users to read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
  }
}

// 2. STORAGE RULES
// Copy and paste this into Storage Rules:

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}

// 3. SAMPLE DATA STRUCTURE
// Create these collections manually in Firestore Console:

/* 
COLLECTION: products
SAMPLE DOCUMENT:
{
  "name": "iPhone 15 Pro",
  "description": "Latest iPhone with titanium design",
  "price": 99999,
  "category": "Electronics",
  "images": ["https://example.com/iphone.jpg"],
  "stock": 50,
  "rating": 4.5,
  "reviewCount": 128,
  "isActive": true,
  "createdAt": timestamp,
  "updatedAt": timestamp
}

COLLECTION: users  
SAMPLE ADMIN USER DOCUMENT (use your email):
{
  "email": "admin@smartmart.com",
  "role": "admin",
  "name": "Admin User",
  "createdAt": timestamp
}

COLLECTION: orders (will be created automatically when customers place orders)
*/
