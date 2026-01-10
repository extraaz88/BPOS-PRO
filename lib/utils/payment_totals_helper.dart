import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentTotalsHelper {
  // Update payment totals in local storage after sale/purchase creation
  static Future<void> updatePaymentTotals({
    int? paymentTypeId,
    double? paidAmount,
    bool? isSplitPayment,
    Map<int, double>? splitPaymentAmounts,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalsJson = prefs.getString('payment_totals');
      
      // Load existing totals
      Map<int, double> totals = {};
      if (totalsJson != null) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(totalsJson);
          totals = parsed.map((key, value) => MapEntry(int.parse(key), value.toDouble()));
        } catch (e) {
          print('Error loading payment totals: $e');
          totals = {};
        }
      }

      // Update totals based on payment type
      if (isSplitPayment == true && splitPaymentAmounts != null && splitPaymentAmounts.isNotEmpty) {
        // Handle split payments
        splitPaymentAmounts.forEach((paymentTypeId, amount) {
          totals[paymentTypeId] = (totals[paymentTypeId] ?? 0) + amount;
        });
      } else if (paymentTypeId != null && paidAmount != null && paidAmount > 0) {
        // Handle single payment type
        totals[paymentTypeId] = (totals[paymentTypeId] ?? 0) + paidAmount;
      }

      // Save updated totals back to local storage
      final updatedTotalsJson = jsonEncode(totals);
      await prefs.setString('payment_totals', updatedTotalsJson);

      print('Payment Totals Updated: $totals');
    } catch (e) {
      print('Error updating payment totals: $e');
    }
  }

  // Recalculate all payment totals from sales and purchases
  static Future<void> recalculateAllPaymentTotals() async {
    try {
      // This will be called when dashboard loads to recalculate all totals
      // For now, we'll just trigger a refresh flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('payment_totals_needs_refresh', true);
    } catch (e) {
      print('Error setting refresh flag: $e');
    }
  }
}

