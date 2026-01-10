import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:async';

class QRPaymentDialog extends StatefulWidget {
  final double amount;
  final String upiId;
  final VoidCallback onPaymentComplete;

  const QRPaymentDialog({
    super.key,
    required this.amount,
    required this.upiId,
    required this.onPaymentComplete,
  });

  @override
  State<QRPaymentDialog> createState() => _QRPaymentDialogState();
}

class _QRPaymentDialogState extends State<QRPaymentDialog> {
  Timer? _autoCompleteTimer;
  bool _isPaymentCompleted = false;

  @override
  void initState() {
    super.initState();
    // Auto-complete payment after 5 seconds (simulating user completing payment)
    _autoCompleteTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isPaymentCompleted) {
        _completePayment();
      }
    });
  }

  @override
  void dispose() {
    _autoCompleteTimer?.cancel();
    super.dispose();
  }

  void _completePayment() {
    if (!_isPaymentCompleted) {
      setState(() {
        _isPaymentCompleted = true;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment received! Invoice will be generated.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Close dialog and complete payment
      Navigator.of(context).pop();
      widget.onPaymentComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate UPI payment string
    final upiString = 'upi://pay?pa=${widget.upiId}&pn=BharatPOS&am=${widget.amount.toStringAsFixed(2)}&cu=INR&tn=Payment';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only QR Code - no background, no borders, no text
            BarcodeWidget(
              barcode: Barcode.qrCode(),
              data: upiString,
              width: 250,
              height: 250,
              color: Colors.black,
            ),
            
            const SizedBox(height: 20),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.white),
                  backgroundColor: Colors.black.withOpacity(0.7),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
