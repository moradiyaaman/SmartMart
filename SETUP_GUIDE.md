# SmartMart Firebase Setup Guide

## 🚀 **Step-by-Step Setup Instructions**

### **1. Firebase Console Setup**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your SmartMart project (or create one if it doesn't exist)
3. Enable the following services:

#### **Authentication Setup:**
- Go to **Authentication > Sign-in method**
- Enable **Email/Password** provider
- Enable **Google** provider (add your app's SHA keys for Android)

#### **Firestore Database Setup:**
- Go to **Firestore Database**
- Click **Create database**
- Choose **Start in test mode** (for development)
- Select your preferred region

#### **Storage Setup:**
- Go to **Storage**
- Click **Get started**
- Choose **Start in test mode**

### **2. Create Admin User**
1. Go to **Authentication > Users**
2. Click **Add user**
3. Add your email and password
4. Note down the **User UID**

### **3. Firestore Collections Setup**

#### **Create Admin User Document:**
1. Go to **Firestore Database**
2. Click **Start collection**
3. Collection ID: `users`
4. Document ID: [Your User UID from step 2]
5. Add these fields:
```
email: "your-email@example.com"
role: "admin"
name: "Your Name"
createdAt: [timestamp - current time]
```

#### **Create Sample Products:**
1. Create collection: `products`
2. Add sample documents with these fields:
```
name: "Sample Product"
description: "This is a sample product"
price: 999
category: "Electronics"
images: ["https://via.placeholder.com/300"]
stock: 50
rating: 4.5
reviewCount: 10
isActive: true
createdAt: [timestamp]
updatedAt: [timestamp]
```

### **4. Update Firestore Rules**
1. Go to **Firestore Database > Rules**
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Products - read for all, write for admin only
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Orders - users can read/write their own orders, admin can access all
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
    
    // Users - users can access their own profile, admin can access all
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
  }
}
```

### **5. Update Storage Rules**
1. Go to **Storage > Rules**
2. Replace with:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### **6. Test Your Setup**
1. Run your Flutter app: `flutter run`
2. Try logging in with your admin credentials
3. You should see the admin dashboard if you're an admin
4. Regular users will see the customer interface

## 🎯 **What Happens Automatically:**
- **Orders collection** - Created when customers place orders
- **User profiles** - Created when users sign up
- **Product images** - Uploaded when admin adds products

## 🔧 **Troubleshooting:**
- **"Permission denied"** - Check Firestore rules and user roles
- **"No products found"** - Add sample products manually
- **"Admin not recognized"** - Ensure user document has `role: "admin"`
- **"Firebase not initialized"** - Check `firebase_options.dart` configuration

## 📱 **Testing the App:**
1. **Admin Login** - Use your admin credentials to access admin dashboard
2. **Customer Signup** - Create new account to test customer features
3. **Add Products** - Use admin panel to add real products
4. **Place Orders** - Test the complete shopping flow

Your SmartMart app is now ready to run! 🚀
