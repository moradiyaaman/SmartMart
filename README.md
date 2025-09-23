# smartmart

# SmartMart - E-commerce Flutter App

A comprehensive e-commerce mobile application built with Flutter and Firebase, featuring user authentication, product browsing, shopping cart, and admin panel.

## Features

### 🔐 Authentication
- **Email/Password Registration & Login**
- **Google Sign-In Integration**
- **Password Reset Functionality**
- **Input Validation & Error Handling**
- **Secure User Profile Management**

### 🛍️ Shopping Experience (Coming Soon)
- Product Browsing & Search
- Category-wise Filtering
- Shopping Cart Management
- Wishlist Functionality
- Order Tracking
- Product Reviews & Ratings

### 👤 User Management
- User Profile Creation
- Address Management
- Order History
- Account Settings

### 🔧 Admin Features (Coming Soon)
- Product Management (CRUD)
- Order Management
- User Management
- Sales Analytics
- Inventory Tracking

## Technical Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Cloud Storage
  - Cloud Functions (future)
- **State Management**: Provider (planned)
- **Payment**: Stripe Integration (planned)

## Current Implementation Status

### ✅ Completed
- [x] Firebase setup and configuration
- [x] User authentication (Email/Password)
- [x] Google Sign-In integration
- [x] Custom UI components (buttons, text fields)
- [x] Form validation
- [x] Error handling
- [x] Beautiful login/register screens
- [x] Password reset functionality
- [x] User profile creation in Firestore

### 🚧 In Progress
- [ ] Product listing and details
- [ ] Shopping cart implementation
- [ ] User profile management

### 📋 Planned
- [ ] Product search and filtering
- [ ] Wishlist functionality
- [ ] Order management
- [ ] Payment integration
- [ ] Admin dashboard
- [ ] Push notifications
- [ ] Offline support

## Getting Started

### Prerequisites
- Flutter SDK (>=3.9.0)
- Android Studio / VS Code
- Firebase account
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smartmart
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   Follow the detailed instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

4. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Configuration

The app requires Firebase setup for:
- Authentication (Email/Password, Google)
- Firestore Database
- Cloud Storage (for product images)

**Important**: Update `lib/firebase_options.dart` with your actual Firebase configuration values.

---

**Built with ❤️ using Flutter and Firebase**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
