# 🚀 Fix Firestore Permission Error - Update Security Rules

## ❌ **Current Problem:**
You're getting a "permission-denied" error when customers try to place orders because the current Firestore security rules only allow admin users to modify products, but the new stock decrement feature needs customers to be able to update product stock during checkout.

## ✅ **Solution:**
Update your Firestore security rules to allow authenticated users to update only the `stock` field of products.

---

## 🔧 **Step-by-Step Instructions:**

### **1. Open Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your SmartMart project
3. Navigate to **Firestore Database**
4. Click on the **Rules** tab

### **2. Replace Current Rules**
**Delete all existing rules** and replace with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Products - read for all, full write for admin only, stock updates for authenticated users
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
    
    // User Profiles - users can access their own profile, admin can access all
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
    
    // Addresses - users can access their own addresses, admin can access all
    match /addresses/{addressId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }
  }
}
```

### **3. Click "Publish" Button**
- After pasting the rules, click the **"Publish"** button
- Wait for the confirmation that rules have been deployed

---

## 🔍 **What Changed:**

### **Before (Problematic):**
```javascript
match /products/{productId} {
  allow read: if true;
  allow write: if request.auth != null && 
    exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

### **After (Fixed):**
```javascript
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
```

---

## 🛡️ **Security Explanation:**

### **What this allows:**
✅ **Anyone** can read products  
✅ **Admin users** can create, read, update, delete products  
✅ **Authenticated customers** can update ONLY the `stock` field during order placement  
✅ **Stock must be >= 0** (prevents negative stock)  

### **What this prevents:**
❌ **Customers cannot** create new products  
❌ **Customers cannot** delete products  
❌ **Customers cannot** modify product name, price, description, etc.  
❌ **Customers cannot** set negative stock values  
❌ **Unauthenticated users** cannot modify anything  

---

## 🧪 **Test the Fix:**

### **After updating rules:**
1. **Wait 1-2 minutes** for rules to propagate
2. **Try placing an order** as a customer
3. **Check the product stock** - it should decrease after successful order
4. **Verify admin functions** still work (product management)

---

## 🆘 **If You Still Get Errors:**

### **Error: "Request did not match expected pattern"**
- Double-check the rules syntax in Firebase Console
- Make sure there are no syntax errors
- Try copying the rules again

### **Error: "Insufficient permissions"**
- Wait 2-3 minutes for rules to fully deploy
- Try logging out and back in to refresh authentication
- Clear browser cache

### **Error: "Property 'stock' is undefined"**
- Make sure your products in Firestore have a `stock` field
- Check that the stock field is a number, not a string

---

## 📞 **Need Help?**
If you're still experiencing issues after following these steps, please share:
1. The exact error message you're seeing
2. A screenshot of your Firebase Console Rules tab
3. Whether you can see the updated rules in the Firebase Console

---

**✨ Once you update these rules, your customers will be able to place orders successfully and the stock will automatically decrease!**