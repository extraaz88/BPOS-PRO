import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Keys for SharedPreferences
  static const String _roleKey = 'user_role';
  static const String _visibilityKey = 'user_visibility';

  /// Save user role and visibility permissions
  Future<void> saveUserPermissions({
    required String role,
    required Map<String, dynamic> visibility,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    await prefs.setString(_visibilityKey, jsonEncode(visibility));
    print('Permissions saved: Role=$role, Visibility=$visibility');
  }

  /// Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString(_roleKey);
    // If role is not found or empty, return 'admin' for full access
    if (role == null || role.isEmpty) {
      return 'admin';
    }
    return role;
  }

  /// Get visibility permissions
  Future<Map<String, dynamic>?> getVisibilityPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final visibilityString = prefs.getString(_visibilityKey);
    if (visibilityString != null) {
      return jsonDecode(visibilityString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear all permissions (useful for logout)
  Future<void> clearPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_visibilityKey);
  }

  /// Check if user has permission for a specific feature
  Future<bool> hasPermission(String permissionKey) async {
    final role = await getUserRole();
    
    // If role is not 'staff', grant all permissions
    if (role != 'staff') {
      return true;
    }
    
    // For staff role, check visibility permissions
    final visibility = await getVisibilityPermissions();
    if (visibility == null) {
      // If no visibility data, deny permission for staff
      return false;
    }
    return visibility[permissionKey] ?? false;
  }

  /// Show permission denied toast with animation
  void showPermissionDeniedToast(BuildContext context) {
    Fluttertoast.showToast(
      msg: "🚫 Not allowed this feature from admin",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: "linear-gradient(to right, #FF5252, #F44336)",
      webPosition: "center",
    );

    // Also show a SnackBar for better UX
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.block, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Access Denied: This feature is restricted by admin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Navigate with permission check
  Future<void> navigateWithPermission({
    required BuildContext context,
    required String permissionKey,
    required Widget destination,
    bool popDrawer = false,
  }) async {
    final hasAccess = await hasPermission(permissionKey);
    
    if (hasAccess) {
      if (popDrawer) {
        Navigator.pop(context); // Close drawer
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      if (popDrawer) {
        Navigator.pop(context); // Close drawer
      }
      showPermissionDeniedToast(context);
    }
  }

  /// Check multiple permissions at once
  Future<Map<String, bool>> checkMultiplePermissions(
      List<String> permissionKeys) async {
    final role = await getUserRole();
    
    // If role is not 'staff', grant all permissions
    if (role != 'staff') {
      Map<String, bool> results = {};
      for (String key in permissionKeys) {
        results[key] = true;
      }
      return results;
    }
    
    // For staff role, check visibility permissions
    final visibility = await getVisibilityPermissions();
    Map<String, bool> results = {};

    for (String key in permissionKeys) {
      results[key] = visibility?[key] ?? false;
    }

    return results;
  }

  /// Get all permissions as a formatted string (for debugging)
  Future<String> getPermissionsDebugInfo() async {
    final role = await getUserRole();
    final visibility = await getVisibilityPermissions();
    return 'Role: $role\nPermissions: $visibility';
  }

  // Permission key constants
  static const String DASHBOARD_PERMISSION = 'dashboardPermission';
  static const String ADD_EXPENSE_PERMISSION = 'addExpensePermission';
  static const String DUE_LIST_PERMISSION = 'dueListPermission';
  static const String LOSS_PROFIT_PERMISSION = 'lossProfitPermission';
  static const String PARTIES_PERMISSION = 'partiesPermission';
  static const String PRODUCT_PERMISSION = 'productPermission';
  static const String PROFILE_EDIT_PERMISSION = 'profileEditPermission';
  static const String PURCHASE_LIST_PERMISSION = 'purchaseListPermission';
  static const String PURCHASE_PERMISSION = 'purchasePermission';
  static const String REPORTS_PERMISSION = 'reportsPermission';
  static const String SALE_PERMISSION = 'salePermission';
  static const String SALES_LIST_PERMISSION = 'salesListPermission';
  static const String STOCK_PERMISSION = 'stockPermission';
  static const String ADD_INCOME_PERMISSION = 'addIncomePermission';
}

