# Backend Integration Required - Screens & Functions

This document lists all screens, functions, and features that currently use **local storage (SharedPreferences)** or **hardcoded/mock data** and need **backend API integration**.

---

## 🔴 **HIGH PRIORITY - Core Features**

### 1. **Waste Management** ⚠️
**Location:** `lib/Screens/Waste_management/`

**Files:**
- `waste_management_screen.dart`
- `disposal_form.dart`

**Current Status:**
- ✅ UI is complete
- ❌ Uses local storage only (SharedPreferences)
- ❌ Has TODO comment: "Implement actual disposal logic"
- ❌ No backend API integration

**What Needs Backend:**
- `POST /api/v1/waste/dispose` - Create disposal record
- `GET /api/v1/waste/list` - Fetch all disposed items
- `GET /api/v1/waste/summary` - Get waste statistics (total waste, total value lost)
- `PUT /api/v1/waste/{id}` - Update disposal record (if needed)
- `DELETE /api/v1/waste/{id}` - Delete disposal record

**Required Data:**
- Product ID
- Quantity disposed
- Disposal date
- Reason (Damaged, Expired, Defective, Lost, Stolen, Other)
- Responsible person
- Auto-reduce product stock when disposed

---

### 2. **Calendar/Appointments** ⚠️
**Location:** `lib/Screens/Calendar/`**

**Files:**
- `calendar_screen.dart`
- `new_appointment_screen.dart`
- `edit_appointment_screen.dart`
- `date_time_selection_screen.dart`
- `lib/services/appointment_service.dart` (uses SharedPreferences)

**Current Status:**
- ✅ UI is complete
- ❌ Uses SharedPreferences (local storage only)
- ❌ Data not synced across devices
- ❌ No backend API integration

**What Needs Backend:**
- `GET /api/v1/appointments` - Fetch all appointments
- `GET /api/v1/appointments?date={date}` - Get appointments for specific date
- `POST /api/v1/appointments` - Create new appointment
- `PUT /api/v1/appointments/{id}` - Update appointment
- `DELETE /api/v1/appointments/{id}` - Delete appointment

**Required Data:**
- Customer/Party ID
- Appointment date & time
- Service type
- Duration
- Status (Scheduled, Completed, Cancelled)
- Notes

---

### 3. **Salon Services** ⚠️
**Location:** `lib/Screens/` and `lib/services/`

**Files:**
- `saloon_service.dart`
- `saloon_service_list.dart`
- `lib/services/saloon_service_service.dart` (uses SharedPreferences)

**Current Status:**
- ✅ UI is complete
- ❌ Uses SharedPreferences (local storage only)
- ❌ No backend API integration

**What Needs Backend:**
- `GET /api/v1/salon-services` - Fetch all salon services
- `POST /api/v1/salon-services` - Create new service
- `PUT /api/v1/salon-services/{id}` - Update service
- `DELETE /api/v1/salon-services/{id}` - Delete service

**Required Data:**
- Service name
- Price
- Duration (in minutes)
- Description (optional)
- Category (optional)

---

### 4. **Notifications** ⚠️
**Location:** `lib/Screens/Notifications/`

**Files:**
- `notification_screen.dart`

**Current Status:**
- ✅ UI is complete
- ❌ Shows hardcoded/mock data
- ❌ No backend API integration

**What Needs Backend:**
- `GET /api/v1/notifications` - Fetch all notifications
- `GET /api/v1/notifications/unread` - Get unread notifications count
- `PUT /api/v1/notifications/{id}/read` - Mark notification as read
- `PUT /api/v1/notifications/read-all` - Mark all as read
- `DELETE /api/v1/notifications/{id}` - Delete notification

**Required Data:**
- Notification title
- Description
- Type (Purchase Alarm, Sale Confirmed, Low Stock, etc.)
- Timestamp
- Read status
- Action URL (optional)

---

### 5. **Order Booking** ⚠️
**Location:** `lib/Screens/OrderBooking/`

**Files:**
- `order_booking_screen.dart`
- `order_booking_controller.dart`

**Current Status:**
- ✅ UI is complete
- ❌ Uses hardcoded/default values
- ❌ No backend API integration
- ❌ No repository file exists

**What Needs Backend:**
- `GET /api/v1/order-bookings` - Fetch all bookings
- `GET /api/v1/order-bookings/{id}` - Get booking details
- `POST /api/v1/order-bookings` - Create new booking
- `PUT /api/v1/order-bookings/{id}` - Update booking
- `PUT /api/v1/order-bookings/{id}/status` - Update booking status
- `DELETE /api/v1/order-bookings/{id}` - Cancel/Delete booking

**Required Data:**
- Order ID (auto-generated)
- Customer/Party ID
- Order date & time
- Delivery date (optional)
- Total amount
- Status (Pending, Confirmed, Preparing, Ready, Delivered, Cancelled)
- Items (products/services)
- Notes

---

## 🟡 **MEDIUM PRIORITY - Marketing & Social**

### 6. **Marketing/Social Media** ⚠️
**Location:** `lib/Screens/Marketing/`

**Files:**
- `marketing_screen.dart`
- `edit_social_media.dart`

**Current Status:**
- ✅ UI is complete
- ❌ No backend API integration
- ❌ Social media links not saved/retrieved

**What Needs Backend:**
- `GET /api/v1/business/social-media` - Fetch social media links
- `PUT /api/v1/business/social-media` - Update social media links

**Required Data:**
- Facebook URL
- Twitter URL
- Instagram URL
- LinkedIn URL
- WhatsApp number (optional)
- YouTube URL (optional)

---

## 🟢 **LOW PRIORITY - Enhancements**

### 7. **Thermal Printing - Image Rendering** 📝
**Location:** `lib/thermal priting invoices/`

**Files:**
- `multilingual_thermal_printer.dart` (Line 1223)

**Current Status:**
- ✅ Text-based printing works
- ❌ Has TODO: "Implement image-based product row rendering"
- ⚠️ Feature enhancement, not critical

**What Needs:**
- Image rendering support in thermal printer
- Product image display in invoices

---

## 📋 **Summary Table**

| # | Feature | Priority | Current Storage | Status |
|---|---------|----------|----------------|--------|
| 1 | Waste Management | 🔴 High | SharedPreferences | UI Complete, No API |
| 2 | Calendar/Appointments | 🔴 High | SharedPreferences | UI Complete, No API |
| 3 | Salon Services | 🔴 High | SharedPreferences | UI Complete, No API |
| 4 | Notifications | 🔴 High | Hardcoded Data | UI Complete, No API |
| 5 | Order Booking | 🔴 High | Hardcoded Data | UI Complete, No API |
| 6 | Marketing/Social Media | 🟡 Medium | None | UI Complete, No API |
| 7 | Thermal Print Images | 🟢 Low | N/A | Enhancement Needed |

---

## 🔧 **Implementation Guide**

### For Each Feature:

1. **Create Repository File**
   - Location: `lib/Screens/{Feature}/Repo/{feature}_repo.dart`
   - Follow existing pattern from other repos (e.g., `sales_repo.dart`)

2. **Create Model File** (if not exists)
   - Location: `lib/Screens/{Feature}/Model/{feature}_model.dart`
   - Define data models matching API response

3. **Create Provider** (if using Riverpod)
   - Location: `lib/Screens/{Feature}/Provider/{feature}_provider.dart`
   - Manage state and API calls

4. **Update Service File** (if exists)
   - Replace SharedPreferences calls with API calls
   - Keep local caching if needed for offline support

5. **Update Screen Files**
   - Replace local storage calls with provider/repository calls
   - Add loading states
   - Add error handling

---

## 📝 **API Endpoint Examples**

### Waste Management
```dart
// POST /api/v1/waste/dispose
{
  "product_id": 123,
  "quantity": 5,
  "disposal_date": "2025-01-15",
  "reason": "Damaged",
  "responsible_person": "Manager",
  "note": "Optional note"
}

// GET /api/v1/waste/list
Response: {
  "data": [
    {
      "id": 1,
      "product_id": 123,
      "product_name": "Product Name",
      "quantity": 5,
      "disposal_date": "2025-01-15",
      "reason": "Damaged",
      "responsible_person": "Manager",
      "value_lost": 250.00
    }
  ],
  "summary": {
    "total_waste": 50,
    "total_value_lost": 2500.00
  }
}
```

### Appointments
```dart
// POST /api/v1/appointments
{
  "party_id": 456,
  "appointment_date": "2025-01-20",
  "appointment_time": "14:30",
  "service_type": "Haircut",
  "duration": 30,
  "notes": "Customer prefers short hair"
}

// GET /api/v1/appointments?date=2025-01-20
Response: {
  "data": [
    {
      "id": 1,
      "party_id": 456,
      "party_name": "John Doe",
      "appointment_date": "2025-01-20",
      "appointment_time": "14:30",
      "service_type": "Haircut",
      "duration": 30,
      "status": "Scheduled",
      "notes": "Customer prefers short hair"
    }
  ]
}
```

### Notifications
```dart
// GET /api/v1/notifications
Response: {
  "data": [
    {
      "id": 1,
      "title": "Purchase Alarm",
      "description": "Low stock alert for Product XYZ",
      "type": "stock_alert",
      "created_at": "2025-01-15T10:30:00Z",
      "is_read": false,
      "action_url": "/products/123"
    }
  ],
  "unread_count": 5
}
```

---

## ✅ **Already Integrated Features**

These features already have backend integration:
- ✅ Sales (SalesRepo)
- ✅ Purchase (PurchaseRepo)
- ✅ Products (ProductRepo)
- ✅ Customers/Suppliers (PartiesRepo)
- ✅ Expenses (ExpenseRepo)
- ✅ Income (IncomeRepo)
- ✅ Reports (various repos)
- ✅ Authentication (SignInRepo, SignUpRepo)
- ✅ Dashboard (uses existing APIs)
- ✅ Due Calculation (DueRepo)
- ✅ VAT/Tax (TaxRepo)
- ✅ Payment Types (PaymentTypeRepo)
- ✅ User Roles (UserRoleRepo)
- ✅ Subscription (SubscriptionRepo)
- ✅ Invoice Returns (InvoiceReturnRepo)

---

## 🚀 **Next Steps**

1. **Prioritize Features:**
   - Start with High Priority features (Waste Management, Appointments, Salon Services, Notifications, Order Booking)
   - These are core business features that need data persistence

2. **Backend Development:**
   - Create API endpoints for each feature
   - Ensure proper authentication/authorization
   - Add validation and error handling

3. **Frontend Integration:**
   - Create repository files
   - Update services to use APIs instead of SharedPreferences
   - Add proper error handling and loading states
   - Test offline/online scenarios

4. **Testing:**
   - Test API integration
   - Test error scenarios
   - Test data synchronization
   - Test permission-based access

---

**Last Updated:** January 2025
**Status:** Ready for Backend Integration

