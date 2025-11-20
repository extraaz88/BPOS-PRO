# Fix for "Invalid argument: Instance of 'Future<int>'" Error

## Error Location
Based on the stack trace:
- `offline_order_database.dart:236` - `updateSyncError` method
- `offline_order_service.dart:301` - `syncPendingOrders` method

## Problem
A `Future<int>` is being passed to a SQL `update` operation without being awaited first.

## Solution

### Step 1: Find the files
The files are in the `spos` package. Look for:
- `lib/services/offline_order_database.dart` (or similar path)
- `lib/services/offline_order_service.dart` (or similar path)

### Step 2: Fix the `updateSyncError` method

**In `offline_order_database.dart` around line 236:**

```dart
// ❌ WRONG - This is likely the current code
Future<void> updateSyncError(int orderId, String error) async {
  await database.update(
    'offline_orders',
    {'sync_error': error, 'sync_count': getSyncCount()}, // getSyncCount() returns Future<int>
    where: 'id = ?',
    whereArgs: [orderId],
  );
}

// ✅ CORRECT - Await the Future first
Future<void> updateSyncError(int orderId, String error) async {
  final syncCount = await getSyncCount(); // Await the Future<int>
  await database.update(
    'offline_orders',
    {'sync_error': error, 'sync_count': syncCount}, // Now it's an int
    where: 'id = ?',
    whereArgs: [orderId],
  );
}
```

### Step 3: Check `syncPendingOrders` method

**In `offline_order_service.dart` around line 301:**

Look for code like this:

```dart
// ❌ WRONG
await database.updateSyncError(
  orderId, 
  error.toString(),
  syncCount: getSyncCount(), // If this returns Future<int>
);

// ✅ CORRECT
final syncCount = await getSyncCount(); // Await first
await database.updateSyncError(
  orderId, 
  error.toString(),
  syncCount: syncCount, // Pass the int value
);
```

## Common Patterns to Look For

1. **Any Future being passed to a Map that goes to SQL:**
   ```dart
   // ❌ Wrong
   await database.update('table', {
     'count': getCount(), // Returns Future<int>
   });
   
   // ✅ Correct
   final count = await getCount();
   await database.update('table', {
     'count': count,
   });
   ```

2. **Future in where clause values:**
   ```dart
   // ❌ Wrong
   await database.query('table', 
     where: 'id = ?', 
     whereArgs: [getId()], // Returns Future<int>
   );
   
   // ✅ Correct
   final id = await getId();
   await database.query('table', 
     where: 'id = ?', 
     whereArgs: [id],
   );
   ```

## Quick Search Pattern

Search your codebase for:
- `updateSyncError`
- `getSyncCount()` or similar functions that return `Future<int>`
- Any database update operations with Future values

## Note
The `spos` package files might be in:
- A separate package directory
- Under `lib/packages/spos/`
- Or as a git submodule

Find these files and apply the fix above!

