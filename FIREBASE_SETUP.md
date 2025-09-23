# SmartMart - Firebase Setup Instructions

## Overview
This document provides step-by-step instructions to set up Firebase for the SmartMart e-commerce app, including Authentication, Firestore Database, and Google Sign-In.

## Prerequisites
- Flutter development environment setup
- Google account
- Android Studio/VS Code

## Step 1: Create Firebase Project

1. **Go to Firebase Console**
   - Visit [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Sign in with your Google account

2. **Create New Project**
   - Click "Create a project"
   - Enter project name: `smartmart-ecommerce` (or your preferred name)
   - Enable Google Analytics (recommended)
   - Select your Google Analytics account
   - Click "Create project"

## Step 2: Add Android App to Firebase

1. **Register Android App**
   - In Firebase console, click "Add app" → Android icon
   - Android package name: `com.example.smartmart` (check in `android/app/build.gradle`)
   - App nickname: `SmartMart Android`
   - SHA-1 certificate: Get it by running:
     ```bash
     cd android
     ./gradlew signingReport
     ```
     Copy the SHA-1 from debug variant

2. **Download google-services.json**
   - Download the `google-services.json` file
   - Place it in `android/app/` directory (you already have this)

## Step 3: Configure Firebase Authentication

1. **Enable Authentication**
   - In Firebase console, go to "Authentication" → "Get started"
   - Go to "Sign-in method" tab

2. **Enable Sign-in Methods**
   - **Email/Password**: Click → Enable → Save
   - **Google**: Click → Enable → Add project support email → Save

3. **Configure Google Sign-In**
   - After enabling Google sign-in, note down the Web client ID
   - You'll need this for Google Sign-In configuration

## Step 4: Set up Firestore Database

1. **Create Database**
   - Go to "Firestore Database" → "Create database"
   - Choose "Start in test mode" (for development)
   - Select your preferred location
   - Click "Done"

2. **Create Collections Structure**
   ```
   users/
   ├── {userId}/
   │   ├── uid: string
   │   ├── email: string
   │   ├── fullName: string
   │   ├── phoneNumber: string
   │   ├── role: string (customer/admin)
   │   ├── createdAt: timestamp
   │   ├── addresses: array
   │   ├── wishlist: array
   │   └── cartItems: array
   
   products/
   ├── {productId}/
   │   ├── name: string
   │   ├── description: string
   │   ├── price: number
   │   ├── category: string
   │   ├── images: array
   │   ├── stock: number
   │   ├── rating: number
   │   └── createdAt: timestamp
   
   orders/
   ├── {orderId}/
   │   ├── userId: string
   │   ├── items: array
   │   ├── totalAmount: number
   │   ├── status: string
   │   ├── shippingAddress: object
   │   ├── paymentMethod: string
   │   └── createdAt: timestamp
   ```

## Step 5: Update Firebase Configuration

1. **Get Firebase Config**
   - Go to Project Settings (gear icon)
   - Scroll down to "Your apps" section
   - Click on your app → "Config" tab
   - Copy the configuration values

2. **Update firebase_options.dart**
   - Replace placeholder values in `lib/firebase_options.dart` with actual values:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'your-actual-api-key',
     appId: 'your-actual-app-id',
     messagingSenderId: 'your-actual-sender-id',
     projectId: 'your-actual-project-id',
     storageBucket: 'your-actual-project-id.appspot.com',
   );
   ```

## Step 6: Configure Google Sign-In

1. **Update Android Configuration**
   - The Web client ID from Google Sign-In setup is automatically configured through `google-services.json`

2. **For iOS (if needed later)**
   - Download `GoogleService-Info.plist`
   - Add to `ios/Runner/` directory
   - Update `ios/Runner/Info.plist` with URL scheme

## Step 7: Set up Firebase Security Rules

1. **Firestore Rules (for development)**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can read/write their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Products are readable by all, writable by admins only
       match /products/{productId} {
         allow read: if true;
         allow write: if request.auth != null && 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
       }
       
       // Orders are readable/writable by the user who created them
       match /orders/{orderId} {
         allow read, write: if request.auth != null && 
           resource.data.userId == request.auth.uid;
       }
     }
   }
   ```

2. **Storage Rules (for product images)**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /products/{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null;
       }
       match /users/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

## Step 8: Test Firebase Connection

1. **Run the App**
   ```bash
   flutter run
   ```

2. **Test Features**
   - Try registering a new user
   - Test email/password login
   - Test Google Sign-In
   - Check Firebase console for user creation

## Step 9: Environment Setup

1. **Create Test Users**
   - Register a few test accounts
   - Set one user's role to 'admin' in Firestore manually

2. **Add Sample Products (Optional)**
   - Use Firebase console to add sample products
   - Or create an admin panel to add products

## Troubleshooting

### Common Issues:

1. **Google Sign-In not working**
   - Ensure SHA-1 certificate is correctly added
   - Check if Google Sign-In is enabled in Firebase console

2. **Firestore permission denied**
   - Check security rules
   - Ensure user is authenticated

3. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Check if google-services.json is in correct location

### Debug Commands:
```bash
# Check Flutter doctor
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get

# Check dependencies
flutter pub deps

# Run in debug mode with logs
flutter run --debug
```

## Production Considerations

1. **Security Rules**: Update Firestore rules for production
2. **Authentication**: Enable proper password policies
3. **Monitoring**: Set up Firebase Analytics and Crashlytics
4. **Performance**: Implement proper indexing in Firestore
5. **Backup**: Set up automated backups

## Next Steps

After completing Firebase setup:
1. Test all authentication flows
2. Implement product management
3. Add shopping cart functionality
4. Integrate payment gateway
5. Add order management
6. Implement admin dashboard

## Support

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Console](https://console.firebase.google.com)
