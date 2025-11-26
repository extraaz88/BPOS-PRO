import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get/get.dart';

class TestRazorpayScreen extends StatefulWidget {
  @override
  _TestRazorpayScreenState createState() => _TestRazorpayScreenState();
}

class _TestRazorpayScreenState extends State<TestRazorpayScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.snackbar("Success 🎉", "Payment ID: ${response.paymentId}",
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar("Failed ❌", response.message ?? "Error",
        backgroundColor: Colors.red, colorText: Colors.white);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar("Wallet", "Wallet: ${response.walletName}",
        backgroundColor: Colors.blue, colorText: Colors.white);
  }

  void openRazorpay() {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // TEST KEY SAME AS YOUR CODE
      'amount': 100, // ₹1.00 TEST
      'name': 'Extraaaz Innovative Tech Solutions Pvt. Ltd.',
      'description': 'Test Payment',
      'timeout': 300,
      'prefill': {
        'contact': '9999999999',
        'email': 'test@spos.com',
      },
      'theme': {'color': '#6C63FF'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Get.snackbar("Error", "Unable to open Razorpay",
          backgroundColor: Colors.red, colorText: Colors.white);
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Razorpay Test Button")),
      body: Center(
        child: ElevatedButton(
          onPressed: openRazorpay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text("Open Razorpay Test",
              style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}
