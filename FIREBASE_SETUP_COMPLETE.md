# 🔧 Complete Firebase Setup Guide for SmartMart

## 🚨 **CRITICAL: Image Upload Fix**

The image upload functionality was failing because Firebase configuration used placeholder values. Follow this guide to fix it completely.

## **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Name your project (e.g., "smartmart-demo")
4. Enable Google Analytics (optional)
5. Wait for project creation

## **Step 2: Configure Firebase Authentication**

1. In Firebase Console → Authentication → Sign-in method
2. Enable Email/Password authentication
3. Add your admin email in Users tab with custom claims: `{"role": "admin"}`

## **Step 3: Set up Firestore Database**

1. In Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select your region
5. Go to Rules tab and paste these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
    
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
  }
}
```

## **Step 4: Set up Firebase Storage (CRITICAL FOR IMAGE UPLOADS)**

1. In Firebase Console → Storage
2. Click "Get started"
3. Choose "Start in test mode" 
4. Select same region as Firestore
5. Go to Rules tab and paste these rules:

```javascript
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
```

## **Step 5: Update Firebase Configuration**

1. In Firebase Console → Project Settings → General tab
2. Scroll to "Your apps" section
3. Add your Flutter app or select existing one
4. Copy the configuration values and replace in `lib/firebase_options.dart`:

**Replace these placeholder values:**
- `projectId`: Your actual project ID (e.g., "smartmart-12345")
- `apiKey`: Your actual API key 
- `appId`: Your actual App ID
- `messagingSenderId`: Your actual Sender ID
- `storageBucket`: Your actual storage bucket (projectId.appspot.com)

**Example:**
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyBdXXXXXXXXXXXXXXXXXXXXXXXXXX', // Your actual API key
  appId: '1:123456789:android:abcdefghijk123456', // Your actual App ID
  messagingSenderId: '123456789', // Your actual Sender ID
  projectId: 'smartmart-12345', // Your actual Project ID
  storageBucket: 'smartmart-12345.appspot.com', // Your actual Storage Bucket
);
```

## **Step 6: Create Admin User**

1. Run the app and register with your admin email
2. In Firestore Console, go to users collection
3. Find your user document and add field: `role: "admin"`

## **Step 7: Test Image Upload**

1. Login as admin
2. Go to Product Management 
3. Try "Add New Product" with images
4. Try "Edit Product" with new images
5. Both should now work!

## **Troubleshooting**

### Error: "Storage access denied"
- Check Firebase Storage rules are applied correctly
- Ensure you're logged in as admin user with `role: "admin"`

### Error: "Firebase Storage bucket not found"
- Verify Storage is enabled in Firebase Console
- Check `storageBucket` value in firebase_options.dart matches your project

### Error: "Network timeout"
- Check internet connection
- Verify Firebase project is active and not deleted

### Error: "Image upload failed"
- Check file size (limit is usually 10MB)
- Ensure image format is supported (JPG, PNG)
- Verify Storage rules allow admin write access

## **Final Verification**

✅ Firebase project created and active  
✅ Authentication enabled with admin user  
✅ Firestore rules applied  
✅ Storage enabled with rules applied  
✅ firebase_options.dart updated with real values  
✅ Admin user has role: "admin" in Firestore  
✅ Image upload tested and working  

After completing these steps, image uploads should work perfectly for both "Add Product" and "Edit Product" flows!