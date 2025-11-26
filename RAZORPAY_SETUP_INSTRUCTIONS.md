# 🔑 Razorpay Setup Instructions (Test Mode)

## Step 1: Create Razorpay Account (FREE)

1. Visit: https://dashboard.razorpay.com/signup
2. Sign up with your email/phone
3. Complete email verification

## Step 2: Get Test Keys

1. **Login** to Razorpay Dashboard: https://dashboard.razorpay.com/
2. **Switch to Test Mode** (toggle at top-left corner - should show "Test Mode")
3. Go to **Settings** → **API Keys** (or directly: https://dashboard.razorpay.com/app/website-app-settings/api-keys)
4. Click on **"Generate Test Key"** button
5. You'll get:
   - **Key ID** (starts with `rzp_test_`)
   - **Key Secret** (click "Show" to reveal)

## Step 3: Add Keys to Your App

Open the file: `lib/Screens/payment getway/payment_getway_screen.dart`

Find lines 57-58 and replace with your keys:

```dart
razorpayKey: 'rzp_test_YOUR_KEY_HERE',     // Paste your Key ID here
razorpaySecret: 'YOUR_SECRET_HERE',         // Paste your Key Secret here
```

### Example:
```dart
razorpayKey: 'rzp_test_1DP5mmOlF5G5ag',
razorpaySecret: 'ThisIsASecretKey123456',
```

## Step 4: Test the App

1. **Hot Restart** the app (NOT hot reload):
   ```bash
   flutter run
   ```
   Or press `R` in the terminal where app is running

2. Go to subscription plans
3. Select a plan
4. Click **"Pay for Subscribe"**
5. ✅ **Razorpay payment gateway will open!**

## Step 5: Test Payment

### Test Card Details (Use these in Razorpay checkout):

**Success Card:**
- Card Number: `4111 1111 1111 1111`
- CVV: Any 3 digits (e.g., `123`)
- Expiry: Any future date (e.g., `12/25`)
- Name: Any name

**Other Test Cards:**
- Insufficient Funds: `4000 0000 0000 9995`
- Card Declined: `4000 0000 0000 0002`
- Network Error: `4000 0000 0000 0119`

**Test UPI IDs:**
- Success: `success@razorpay`
- Failure: `failure@razorpay`

**Test Netbanking:**
- Select any bank
- In the popup, click "Success" or "Failure" button

## 📌 Important Notes:

1. **Test Mode** mein कोई real payment नहीं होता
2. Test keys से सिर्फ testing के लिए fake payments कर सकते हैं
3. Production में deploy करते समय **Live Keys** use करें
4. Keys को **कभी भी Git/GitHub** पर upload न करें

## 🚀 Production Setup (Real Payments के लिए):

1. Complete KYC on Razorpay
2. Get business verification done
3. Switch to **"Live Mode"**
4. Generate **Live Keys**
5. Replace test keys with live keys

## ❓ Troubleshooting:

### Issue: Razorpay not opening
**Solution:** Do a full rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "MissingPluginException"
**Solution:** Stop app completely and rebuild (NOT hot reload)

### Issue: Payment fails immediately
**Solution:** Check if you're using correct test card details

## 📞 Need Help?

- Razorpay Docs: https://razorpay.com/docs/
- Test Cards: https://razorpay.com/docs/payments/payments/test-card-details/
- Support: support@razorpay.com

---

## ✅ Quick Checklist:

- [ ] Created Razorpay account
- [ ] Switched to Test Mode
- [ ] Generated Test Keys
- [ ] Added keys to `payment_getway_screen.dart`
- [ ] Did `flutter run` (full rebuild)
- [ ] Tested payment with test card `4111 1111 1111 1111`

Happy Testing! 🎉

