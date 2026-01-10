# Hold Orders Feature - BharatPOS

## Overview

The Hold Orders feature allows users to temporarily save incomplete sales or purchase orders and retrieve them later with all data intact. This is useful when a customer needs to add more items or when dealing with multiple orders simultaneously.

## Features

### 1. Hold Button in Add Sale & Add Purchase
- **Location**: Positioned between the "Cancel" and "Save" buttons
- **Color**: Orange button with white text
- **Functionality**: Saves the current order (products, customer, amounts, discounts, etc.) to local storage

### 2. Hold Orders Screen
- **Navigation**: Access through the main menu
- **Tabs**: Separate tabs for Sales and Purchase orders
- **Display**: Shows all held orders with:
  - Customer/Supplier name
  - Phone number
  - Order date
  - Number of items
  - Total amount
  - Product list preview (first 3 items)
  - Order type badge (SALE or PURCHASE)

### 3. Restore Functionality
- **Action**: Click on any hold order card or the "Restore" button
- **Result**: Automatically navigates to Add Sale/Purchase screen with all data restored:
  - Customer/Supplier details
  - All products with quantities
  - Discounts (flat/percentage)
  - Shipping and service charges
  - Payment type
  - Split payment details (if applicable)
  - Tax/GST information
  - Date and notes

### 4. Delete Functionality
- **Action**: Click the delete button on a hold order card
- **Result**: Shows confirmation dialog before deleting

## Usage Scenarios

### Example 1: Customer Wants to Add More Products
1. Customer is purchasing items
2. They remember they need to buy something else
3. Clerk clicks "Hold" button in Add Sale screen
4. Order is saved to Hold Orders
5. Customer comes back later
6. Clerk opens Hold Orders screen
7. Clicks on the customer's order
8. Add Sale screen opens with all previous data
9. Clerk adds new products and completes the sale

### Example 2: Managing Multiple Orders
1. Customer A starts an order
2. Customer B arrives and needs urgent service
3. Clerk holds Customer A's order
4. Completes Customer B's transaction
5. Retrieves Customer A's order from Hold Orders screen
6. Completes Customer A's transaction

## Technical Implementation

### Data Storage
- Uses **SharedPreferences** for local storage
- Data persists even after app restart
- Each order has a unique timestamp-based ID

### Data Structure
Saved information includes:
- Order type (sale/purchase)
- Customer/Supplier details (name, ID, phone)
- Date
- Products list with:
  - Product name, ID, quantity
  - Prices (purchase, sale, wholesale, dealer)
  - Stock information
  - GST/Tax details
- Discount details (amount, percentage, type)
- VAT/Tax information
- Shipping and service charges
- Payment type
- Split payment details (if applicable)
- Total, paid, and due amounts
- Notes

### Files Created

1. **lib/model/hold_order_model.dart**
   - `HoldOrderModel`: Main model for hold orders
   - `HoldOrderItem`: Model for individual product items

2. **lib/services/hold_order_service.dart**
   - CRUD operations for hold orders
   - Local storage management using SharedPreferences

3. **lib/Screens/HoldOrders/hold_orders_screen.dart**
   - UI for displaying all hold orders
   - Restore and delete functionality
   - Separate tabs for sales and purchases

4. **lib/Screens/HoldOrders/hold_orders_provider.dart**
   - State management for hold orders
   - Provider for restoring order data

### Files Modified

1. **lib/Screens/Purchase/add_and_edit_purchase.dart**
   - Added Hold button
   - Added restore from hold order functionality
   - Modified button layout to accommodate 3 buttons

2. **lib/Screens/Sales/add_sales.dart**
   - Added Hold button
   - Added restore from hold order functionality
   - Modified button layout to accommodate 3 buttons

## How to Access Hold Orders Screen

To make the Hold Orders screen accessible from the app, add a navigation item to your main menu or drawer:

```dart
// Example: Add to your drawer or menu
ListTile(
  leading: Icon(Icons.pending_actions),
  title: Text('Hold Orders'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HoldOrdersScreen(),
      ),
    );
  },
),
```

Or add it to your home screen tiles:

```dart
// Example: Add to home screen
GestureDetector(
  onTap: () => HoldOrdersScreen().launch(context),
  child: Container(
    // Your tile design here
    child: Column(
      children: [
        Icon(Icons.pending_actions),
        Text('Hold Orders'),
      ],
    ),
  ),
),
```

## User Guide

### How to Hold an Order

1. **In Add Sale or Add Purchase screen**:
   - Add products to cart
   - Fill in customer/supplier details (optional)
   - Add any discounts, charges, etc. (optional)
   - Click the orange **"Hold"** button
   - Order is saved and screen closes
   - Success message: "Order saved to Hold Orders!"

### How to Restore a Hold Order

1. **Navigate to Hold Orders screen** from main menu
2. Select the appropriate tab (Sales or Purchase)
3. Find your order in the list
4. Click on the order card or click **"Restore"** button
5. Add Sale/Purchase screen opens with all data pre-filled
6. Continue editing or complete the transaction
7. Click **"Save"** to finalize the order

### How to Delete a Hold Order

1. Navigate to Hold Orders screen
2. Find the order you want to delete
3. Click the red delete button (trash icon)
4. Confirm deletion in the dialog
5. Order is permanently removed

## Notes

- Hold orders are stored locally on the device
- Data persists even after closing and reopening the app
- No limit on the number of hold orders
- Each order is automatically assigned a unique ID based on timestamp
- When an order is restored and saved, it's automatically removed from hold orders
- You can have both sales and purchase orders on hold simultaneously

## Troubleshooting

### Hold order not appearing after save
- Check if you're on the correct tab (Sales/Purchase)
- Ensure the order was saved (look for success message)
- Try closing and reopening the Hold Orders screen

### Data lost after restore
- Make sure to complete the transaction after restoring
- Don't click "Cancel" as it will discard changes
- If you need to hold the order again, click "Hold" button

### Unable to restore order
- Ensure the customer/supplier still exists in the system
- Check if all products are still available
- Contact support if the issue persists

## Future Enhancements (Possible)

- Search functionality in Hold Orders screen
- Filter by date range
- Auto-delete old hold orders after specified days
- Cloud sync for hold orders across multiple devices
- Hold order notifications/reminders
- Bulk operations (delete multiple orders)

