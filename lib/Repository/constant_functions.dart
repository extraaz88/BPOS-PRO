import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  final storedToken = prefs.getString('token') ?? '';

  if (storedToken.isEmpty) {
    print('Auth token not found in prefs');
    return '';
  }

  final normalizedToken = storedToken.toLowerCase().startsWith('bearer ')
      ? storedToken
      : 'Bearer $storedToken';

  print('Auth token loaded: $normalizedToken');
  return normalizedToken;
}

Future<void> saveUserData({
  required String token,
  String? role,
  Map<String, dynamic>? visibility,
}) async {
  print(token);
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('token', token);
  
  // Save role - if not provided or empty, save as 'admin'
  String userRole = role ?? 'admin';
  if (userRole.isEmpty) {
    userRole = 'admin';
  }
  await prefs.setString('user_role', userRole);
  print('User Role Saved: $userRole');
  
  // Save visibility if provided
  if (visibility != null) {
    await prefs.setString('user_visibility', jsonEncode(visibility));
    print('User Visibility Saved: $visibility');
  }
}

Future<String?> getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  String? role = prefs.getString('user_role');
  // If role is not found or empty, return 'admin' for full access
  if (role == null || role.isEmpty) {
    return 'admin';
  }
  return role;
}

Future<Map<String, dynamic>?> getUserVisibility() async {
  final prefs = await SharedPreferences.getInstance();
  final visibilityString = prefs.getString('user_visibility');
  if (visibilityString != null) {
    return jsonDecode(visibilityString) as Map<String, dynamic>;
  }
  return null;
}

Future<void> clearUserData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

// Map API category name to app category name and get features
Map<String, dynamic>? getCategoryByName(String apiCategoryName) {
  // Define shop categories with their features
  final Map<String, Map<String, dynamic>> categoryMap = {
    'All Category': {
      'name': 'All Category',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income',
        'order_booking',
        'salon_service'
      ]
    },
    'Retail Shop': {
      'name': 'Retail Shop',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    'Restaurant': {
      'name': 'Restaurant',
      'features': [
        'sale',
        'product',
        'parties',
        'dashboard',
        'reports',
        'expense',
        'income',
        'order_booking'
      ]
    },
    'Grocery Store': {
      'name': 'Grocery Store',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    'Fashion Store': {
      'name': 'Fashion Store',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'expense',
        'income'
      ]
    },
    'Medical/Pharmacy': {
      'name': 'Medical/Pharmacy',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    'Electronics': {
      'name': 'Electronics',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    'Electronics Store': {
      'name': 'Electronics',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    'Salon': {
      'name': 'Salon',
      'features': [
        'sale',
        'parties',
        'dashboard',
        'reports',
        'expense',
        'income',
        'order_booking',
        'salon_service'
      ]
    },
    'Hardware Store': {
      'name': 'Hardware Store',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    'Mobile Shop': {
      'name': 'Mobile Shop',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    'Stationery': {
      'name': 'Stationery',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
  };

  // Try exact match first
  if (categoryMap.containsKey(apiCategoryName)) {
    return categoryMap[apiCategoryName];
  }

  // Try case-insensitive match
  for (var entry in categoryMap.entries) {
    if (entry.key.toLowerCase() == apiCategoryName.toLowerCase()) {
      return entry.value;
    }
  }

  // Try partial match (e.g., "Electronics Store" contains "Electronics")
  for (var entry in categoryMap.entries) {
    if (apiCategoryName.toLowerCase().contains(entry.key.toLowerCase()) ||
        entry.key.toLowerCase().contains(apiCategoryName.toLowerCase())) {
      return entry.value;
    }
  }

  // Default to "All Category" if no match found
  return categoryMap['All Category'];
}

// Save shop category and features
Future<void> saveShopCategory({
  required String categoryName,
  required List<String> features,
  String? originalApiCategoryName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('shop_category', categoryName);
  await prefs.setStringList('shop_features', features);
  if (originalApiCategoryName != null) {
    await prefs.setString('shop_category_original', originalApiCategoryName);
  }
  print('Shop Category Saved: $categoryName with ${features.length} features');
}

// Get shop category name
Future<String> getShopCategory() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('shop_category') ?? 'All Category';
}

// Get original API category name for display
Future<String?> getOriginalApiCategoryName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('shop_category_original');
}