# 🚨 URGENT FIX: Firestore Permission Error

## The Problem
You're still getting the permission error because either:
1. **Firestore rules weren't updated properly**
2. **The transaction approach is conflicting with the rules**
3. **Missing user profile data**

## ✅ IMMEDIATE SOLUTION

### Step 1: Verify Firestore Rules Are Actually Applied

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your SmartMart project
3. Go to **Firestore Database** → **Rules**
4. **COPY AND PASTE THIS EXACTLY** (replace everything):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Products collection - Allow stock updates for authenticated users
    match /products/{productId} {
      allow read: if true;
      allow create, delete: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superAdmin'];
      allow update: if request.auth != null && (
        // Admin can update everything
        (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superAdmin']) ||
        // Any authenticated user can update stock field only
        (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stock']) &&
         request.resource.data.stock >= 0)
      );
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superAdmin']));
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superAdmin']));
    }
    
    // UserProfiles collection
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superAdmin']));
    }
    
    // Addresses collection
    match /addresses/{addressId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superAdmin']));
    }
  }
}
```

5. **Click "Publish"**
6. **Wait 2-3 minutes** for rules to propagate

### Step 2: If Rules Don't Fix It - Temporary Workaround

If the rules still don't work, we'll temporarily use a simpler approach without transactions. I'll modify the order service to use a basic update instead of transactions.

### Step 3: Check Your Firebase Console

Make sure you have:
1. **A user document** in the `users` collection with your UID
2. **The role field** set to "customer" (not admin)
3. **Products have a stock field** (numeric value)

---

## 🔧 Alternative Fix (If Rules Still Don't Work)

If the rules above still don't work, we can use a different approach - let me know and I'll modify the code to handle stock updates differently.

---

**Try the rules update first, wait 2-3 minutes, then test the order again!**