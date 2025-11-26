import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.planId,
    required this.businessId,
    this.amount,
  });

  final String planId;
  final String businessId;
  final double? amount;

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    Future.delayed(Duration(milliseconds: 300), () {
      _openRazorpay();
    });
  }

  void _openRazorpay() {
    final amountPaise = ((widget.amount ?? 100) * 100).round();

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',    
      'amount': amountPaise,
      'name': 'Extraaaz Innovative Tech Solutions Pvt. Ltd.',
      'description': 'Subscription Plan Payment',
      'timeout': 300,
      'prefill': {
        'contact': '7709040699',
        'email': 'info@extraaaz.com',
      },
      'theme': {'color': '#6C63FF'},
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay'],
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error opening Razorpay!",
        backgroundColor: Colors.red,
      );
      print("Razorpay Error: $e");
      Navigator.pop(context, false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Successful!",
      backgroundColor: Colors.green,
    );
    Navigator.pop(context, true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Failed!",
      backgroundColor: Colors.red,
    );
    Navigator.pop(context, false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "Wallet: ${response.walletName}",
      backgroundColor: Colors.blue,
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: Center(
        child: Card(
          margin: EdgeInsets.all(40),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  "Opening Razorpay...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Text(
                  "Amount: ₹${widget.amount ?? 0}",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
