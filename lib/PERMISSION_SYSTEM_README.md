# Role-Based Permission System Documentation

## Overview

This POS application now includes a comprehensive role-based permission system that controls user access to various features based on their assigned role (e.g., "staff", "admin"). When a user logs in, their role and visibility permissions are stored locally and enforced throughout the application.

## How It Works

### 1. Login Flow

When a user logs in, the API response includes:
```json
{
  "message": "User login successfully!",
  "data": {
    "is_setup": true,
    "token": "200|...",
    "currency": {...},
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
      "salesListPermission": false,
      "stockPermission": false,
      "addIncomePermission": false
    }
  }
}
```

The system automatically:
1. Saves the authentication token
2. Saves the user's role
3. Saves all visibility permissions locally using SharedPreferences
4. Navigates to the home screen

### 2. Permission Enforcement

The permission system is enforced in three key areas:

#### A. Navigation Drawer
All items in the app drawer (`app_drawer.dart`) now check permissions before navigation:
- If permission is granted → Navigate to the screen
- If permission is denied → Show "Not allowed this feature from admin" toast message

#### B. Home Screen Quick Actions
Quick action cards on the home screen check permissions before allowing access to features.

#### C. Bottom Navigation
The bottom navigation bar dynamically shows/hides tabs based on permissions:
- Example: If `dashboardPermission` is `false`, the Dashboard tab is hidden

### 3. Permission Keys

The following permission keys are used throughout the application:

| Permission Key | Description |
|----------------|-------------|
| `dashboardPermission` | Access to Dashboard screen |
| `addExpensePermission` | Access to add/view Expenses |
| `dueListPermission` | Access to Due List screen |
| `lossProfitPermission` | Access to Loss/Profit reports |
| `partiesPermission` | Access to Customer/Supplier management |
| `productPermission` | Access to Product management |
| `profileEditPermission` | Permission to edit profile |
| `purchaseListPermission` | Access to Purchase List |
| `purchasePermission` | Access to create Purchases |
| `reportsPermission` | Access to Reports section |
| `salePermission` | Access to create Sales |
| `salesListPermission` | Access to Sales List |
| `stockPermission` | Access to Stock List |
| `addIncomePermission` | Access to add/view Income |

## Core Components

### 1. PermissionService (`lib/services/permission_service.dart`)

A singleton service that handles all permission-related operations:

```dart
// Check if user has a specific permission
bool hasPermission = await PermissionService().hasPermission(PermissionService.SALE_PERMISSION);

// Navigate with permission check
PermissionService().navigateWithPermission(
  context: context,
  permissionKey: PermissionService.SALE_PERMISSION,
  destination: AddSalesScreen(customerModel: null),
  popDrawer: true, // Optional: close drawer before navigation
);

// Show permission denied message
PermissionService().showPermissionDeniedToast(context);
```

### 2. Constant Functions (`lib/Repository/constant_functions.dart`)

Updated to save and retrieve user role and permissions:

```dart
// Save user data including role and permissions
await saveUserData(
  token: token,
  role: 'staff',
  visibility: visibilityMap,
);

// Get user role
String? role = await getUserRole();

// Get visibility permissions
Map<String, dynamic>? permissions = await getUserVisibility();
```

### 3. Updated Login Repository (`lib/Screens/Authentication/Sign In/Repo/sign_in_repo.dart`)

The login repository now extracts and saves role and visibility data from the API response.

## Usage Examples

### Example 1: Check Permission Before Navigation

```dart
// In any widget
onTap: () {
  PermissionService().navigateWithPermission(
    context: context,
    permissionKey: PermissionService.PRODUCT_PERMISSION,
    destination: ProductList(),
  );
}
```

### Example 2: Conditionally Show/Hide UI Elements

```dart
// Check permission asynchronously
final hasPermission = await PermissionService().hasPermission(
  PermissionService.DASHBOARD_PERMISSION
);

if (hasPermission) {
  // Show dashboard button or content
} else {
  // Hide or disable dashboard button
}
```

### Example 3: Check Multiple Permissions at Once

```dart
final permissions = await PermissionService().checkMultiplePermissions([
  PermissionService.SALE_PERMISSION,
  PermissionService.PURCHASE_PERMISSION,
  PermissionService.PRODUCT_PERMISSION,
]);

// Returns: {'salePermission': true, 'purchasePermission': false, ...}
```

## User Experience

### When Permission is Denied

When a user tries to access a feature they don't have permission for:

1. **Toast Message**: A centered toast appears with "🚫 Not allowed this feature from admin"
2. **SnackBar**: A red SnackBar with "Access Denied: This feature is restricted by admin" appears at the bottom
3. **No Navigation**: The user stays on the current screen
4. **Visual Feedback**: The messages use animations and styling to clearly communicate the restriction

### When Permission is Granted

- Normal navigation occurs
- All features work as expected
- No blocking messages are shown

## Testing the System

### Test with Staff Role

1. Login with a staff account
2. The API response should have `"role": "staff"` with limited permissions
3. Try accessing different screens:
   - ✅ Allowed screens: Sales, Reports (if permissions are true)
   - ❌ Blocked screens: Dashboard, Products, Expenses (if permissions are false)
4. Verify that:
   - Toast/SnackBar messages appear for blocked features
   - Bottom navigation only shows allowed tabs
   - Drawer items are clickable but show permission error when restricted

### Test with Admin Role

1. Login with an admin account
2. The API response should have `"role": "admin"` with all permissions set to `true`
3. Verify all features are accessible
4. No permission denied messages should appear

## Default Behavior

- If no visibility data is stored (first-time or admin users), the system assumes all permissions are granted
- This ensures the app doesn't lock out users if there's a data issue
- Admin users typically have all permissions set to `true` by the backend

## Logout Behavior

When a user logs out, call `clearUserData()` to remove all stored permissions:

```dart
import 'package:mobile_pos/Repository/constant_functions.dart';

await clearUserData(); // Clears token, role, and permissions
```

## Adding New Permissions

To add a new permission to the system:

1. **Update PermissionService** (`lib/services/permission_service.dart`):
   ```dart
   static const String NEW_FEATURE_PERMISSION = 'newFeaturePermission';
   ```

2. **Update Backend**: Ensure the API includes the new permission in the login response

3. **Update Visibility Model** (`lib/model/business_info_model.dart`):
   ```dart
   bool? newFeaturePermission;
   ```

4. **Apply Permission Check**: Use `PermissionService` in the relevant screens

## Troubleshooting

### Issue: All features are accessible even for staff
**Solution**: Check if the login response includes the `visibility` object. Verify `sign_in_repo.dart` is saving the permissions.

### Issue: Permission denied even for admin
**Solution**: Check that admin users have all permissions set to `true` in the API response.

### Issue: Bottom navigation shows wrong tabs
**Solution**: Ensure `home.dart` is reading permissions from `businessInfoProvider` correctly.

### Issue: Toast not showing
**Solution**: Verify `fluttertoast` package is properly installed in `pubspec.yaml`.

## Security Notes

⚠️ **Important**: This permission system is for UX purposes only. All critical permission checks should be enforced on the backend API. The frontend permissions prevent users from accessing screens, but a determined user could potentially bypass these checks.

Always:
- ✅ Validate permissions on the server for every API request
- ✅ Return appropriate HTTP status codes (401, 403) for unauthorized requests
- ✅ Keep sensitive data on the backend
- ❌ Don't rely solely on frontend permission checks for security

## Files Modified

1. `lib/services/permission_service.dart` - NEW: Core permission service
2. `lib/Repository/constant_functions.dart` - Updated: Save/retrieve permissions
3. `lib/Screens/Authentication/Sign In/Repo/sign_in_repo.dart` - Updated: Save permissions on login
4. `lib/GlobalComponents/app_drawer.dart` - Updated: Permission checks for all drawer items
5. `lib/Screens/Home/home_screen.dart` - Updated: Permission checks for quick actions
6. `lib/Screens/Home/home.dart` - Updated: Dynamic bottom navigation
7. `lib/Screens/Home/components/bottom_nav.dart` - Updated: Accept dynamic items list

## Summary

The role-based permission system provides a seamless way to control user access throughout the POS application. It combines local storage of permissions, real-time checks, and user-friendly feedback to create a secure and intuitive experience for users with different roles.

