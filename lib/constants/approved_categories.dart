import 'package:flutter/material.dart';

/// Approved product categories for SmartMart
/// 
/// This file contains the official, fixed list of categories that should be used
/// throughout the application. No other categories should be displayed to customers
/// or allowed in the admin panel.
class ApprovedCategories {
  /// The complete list of approved product categories
  static const List<String> categories = [
    'Electronics',
    'Clothing', 
    'Books',
    'Home & Garden',
    'Sports',
    'Beauty & Health',
    'Toys',
    'Automotive',
  ];

  /// Check if a category is approved
  static bool isApproved(String category) {
    return categories.contains(category);
  }

  /// Filter a list of products to only include approved categories
  static List<T> filterApprovedProducts<T>(
    List<T> products, 
    String Function(T) getCategoryFunction
  ) {
    return products.where((product) => 
      isApproved(getCategoryFunction(product))
    ).toList();
  }

  /// Get approved categories for dropdown/select widgets
  static List<DropdownMenuItem<String>> getDropdownItems() {
    return categories.map((category) => 
      DropdownMenuItem<String>(
        value: category,
        child: Text(category),
      )
    ).toList();
  }
}