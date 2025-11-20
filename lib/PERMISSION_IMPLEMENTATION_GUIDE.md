# Permission-Based Visibility System Implementation Guide

## Overview
This document explains the permission-based visibility system implemented in the POS app. The system ensures that users only see and access features they have permission to use based on their role and visibility settings from the backend.

## How It Works

### 1. Login Flow
When a user logs in via email/password, the login response includes:
```json
{
  "role": "staff",
  "visibility": {
    "dashboardPermission": false,
    "addExpensePermission": false,
    "dueListPermission": false,
    "lossProfitPermission": false,
    "partiesPermission": false,
    "productPermission": false,
    "profileEditPermission": false,
    "purchaseListPermission": false,
    "purchasePermission": false,
    "reportsPermission": true,
    "salePermission": true,
    "salesListPermission": true,
    "stockPermission": false,
    "addIncomePermission": false
  }
}
```

This data is saved to SharedPreferences and also available through the BusinessInformation provider.

### 2. Permission Storage
Permissions are stored in two places:
- **SharedPreferences**: Keys `user_role` and `user_visibility`
- **BusinessInformation Provider**: Fetched from API and contains user.role and user.visibility

### 3. Where Permissions Are Checked

#### Home Screen (`lib/Screens/Home/home_screen.dart`)
- **Quick Actions Grid**: Only shows action cards for features the user has permission to access
- Uses `FutureBuilder` with `_buildQuickActionCards()` to filter cards based on permissions
- If no permissions are granted, shows a message: "No actions available. Contact admin for access."

#### App Drawer (`lib/GlobalComponents/app_drawer.dart`)
- **Navigation Menu**: Only displays menu items for features the user can access
- Uses `FutureBuilder` with `_buildDrawerItems()` to filter menu items
- Settings is always visible to all users

#### Settings Screen (`lib/Screens/Settings/settings_screen.dart`)
- **Dashboard Menu Item**: Hidden if `dashboardPermission` is false
- **User Role Menu Item**: Hidden for staff users (only visible to admin/owner)
- Other settings items are visible to all users

#### Bottom Navigation (`lib/Screens/Home/home.dart`)
- **Dashboard Tab**: Hidden if `dashboardPermission` is false
- Home, Reports, and Settings tabs are always visible

### 4. Permission Keys
All permission keys are defined as constants in `PermissionService`:
```dart
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
```

## Example: Staff User with Limited Access

Based on your login response example, a staff user with these permissions:
- ✅ **Reports**: `reportsPermission: true`
- ✅ **Sales**: `salePermission: true`
- ✅ **Sales List**: `salesListPermission: true`
- ❌ All other features: `false`

Will see:
1. **Home Screen Quick Actions**: Only "New Sale", "Reports", and "Sales List" cards
2. **App Drawer**: Only "Sales", "Sales List", "Reports", and "Settings" menu items
3. **Settings**: No "Dashboard" or "User Role" options
4. **Bottom Navigation**: No "Dashboard" tab

## Logout Behavior
When user logs out:
- `user_role` and `user_visibility` are removed from SharedPreferences
- App restarts to clear all cached data
- Next login will fetch fresh permissions

## Admin/Owner Behavior
Users with no visibility restrictions (null or undefined):
- See all features and menu items
- Have full access to the app
- Can manage user roles and permissions

## Technical Details

### Permission Checking Flow
1. Check if visibility data exists in SharedPreferences
2. If null (admin/owner), grant all permissions
3. If exists, check specific permission key
4. Return true/false based on permission value

### UI Update Pattern
```dart
// Example: Filtering items based on permissions
Future<List<Widget>> _buildFilteredItems() async {
  final visibility = await PermissionService().getVisibilityPermissions();
  
  if (visibility == null) {
    return _getAllItems(); // Admin - show all
  }
  
  List<Widget> items = [];
  
  if (visibility['salePermission'] == true) {
    items.add(salesWidget);
  }
  
  // Add other items based on permissions...
  
  return items;
}
```

## Files Modified
1. `lib/Screens/Home/home_screen.dart` - Quick Actions filtering
2. `lib/GlobalComponents/app_drawer.dart` - Drawer items filtering  
3. `lib/Screens/Settings/settings_screen.dart` - Settings items filtering
4. `lib/Screens/Authentication/Repo/logout_repo.dart` - Clear permissions on logout
5. `lib/services/permission_service.dart` - Already existed
6. `lib/Repository/constant_functions.dart` - Already handled permissions
7. `lib/Screens/Authentication/Sign In/Repo/sign_in_repo.dart` - Already saved permissions

## Testing Checklist
- [ ] Login with staff account having limited permissions
- [ ] Verify only permitted features show in Quick Actions
- [ ] Verify only permitted items show in App Drawer
- [ ] Verify Dashboard tab hidden when dashboardPermission is false
- [ ] Verify Settings screen hides restricted items
- [ ] Logout and verify permissions are cleared
- [ ] Login with admin account and verify all features are visible

## Future Enhancements
1. Add permission check to direct route navigation
2. Add permission validation for API calls
3. Add visual indicator for permission-restricted features (grayed out with tooltip)
4. Add audit logging for permission-denied attempts

