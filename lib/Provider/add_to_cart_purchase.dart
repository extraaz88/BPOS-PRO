import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../Screens/Purchase/Repo/purchase_repo.dart';
import '../Screens/vat_&_tax/model/vat_model.dart';

final cartNotifierPurchaseNew =
    ChangeNotifierProvider((ref) => CartNotifierPurchase());

class CartNotifierPurchase extends ChangeNotifier {
  List<CartProductModelPurchase> cartItemList = [];
  TextEditingController discountTextControllerFlat = TextEditingController();
  TextEditingController vatAmountController = TextEditingController();
  TextEditingController shippingChargeController = TextEditingController();
  TextEditingController serviceChargeController = TextEditingController();

  ///_________NEW_________________________________
  num totalAmount = 0;
  num discountAmount = 0;
  num discountPercent = 0;
  num totalPayableAmount = 0;
  VatModel? selectedVat;
  num vatAmount = 0;
  bool isFullPaid = false;
  num receiveAmount = 0;
  num changeAmount = 0;
  num dueAmount = 0;
  num finalShippingCharge = 0;
  num finalServiceCharge = 0;
  String selectedTaxType = 'GST'; // Always GST (like sales)

  // GST calculation variables (same as sales)
  num totalGstAmount = 0;
  num totalSgstAmount = 0;
  num totalCgstAmount = 0;

  void setTaxType(String taxType) {
    selectedTaxType = taxType;
    print('Tax type set to: $selectedTaxType');
    calculatePrice();
  }

  void changeSelectedVat({VatModel? data}) {
    if (data != null) {
      selectedVat = data;
    } else {
      selectedVat = null;
      vatAmount = 0;
      vatAmountController.clear();
    }

    calculatePrice();
  }

  void calculateDiscount({
    required String value,
    bool? rebuilding,
    String? selectedTaxType,
  }) {
    if (value.isEmpty) {
      discountAmount = 0;
      discountPercent = 0;
      discountTextControllerFlat.clear();
    } else {
      num discountValue = num.tryParse(value) ?? 0;

      if (selectedTaxType == null) {
        EasyLoading.showError('Please select a discount type');
        discountAmount = 0;
        discountPercent = 0;
      } else if (selectedTaxType == "Flat") {
        discountAmount = discountValue;

        if (discountAmount > totalAmount) {
          discountTextControllerFlat.clear();
          discountAmount = 0;
          EasyLoading.showError('Enter a valid discount');
        }
      } else if (selectedTaxType == "Percent") {
        discountPercent = discountValue;
        discountAmount = (totalAmount * discountPercent) / 100;

        if (discountAmount > totalAmount) {
          discountAmount = totalAmount;
        }
      } else {
        EasyLoading.showError('Invalid discount type selected');
        discountAmount = 0;
      }
    }

    if (rebuilding == false) return;
    calculatePrice();
  }

  void updateProduct(
      {required num productId,
      required num price,
      required String qty,
      String? variantKey}) {
    int index;
    if (variantKey != null && variantKey.isNotEmpty) {
      // Find by productId AND variantKey
      index = cartItemList.indexWhere((element) =>
          element.productId == productId && element.variantKey == variantKey);
    } else {
      // Find by productId only (non-variant products)
      index = cartItemList.indexWhere((element) =>
          element.productId == productId &&
          (element.variantKey == null || element.variantKey!.isEmpty));
    }

    if (index >= 0) {
      cartItemList[index].productPurchasePrice = price;
      cartItemList[index].quantities = qty.toInt();
      calculatePrice();
    }
  }

  void calculatePrice(
      {String? receivedAmount,
      String? shippingCharge,
      String? serviceCharge,
      bool? stopRebuild}) {
    totalAmount = 0;
    totalPayableAmount = 0;
    dueAmount = 0;
    totalGstAmount = 0;
    totalSgstAmount = 0;
    totalCgstAmount = 0;

    for (var element in cartItemList) {
      totalAmount +=
          (element.quantities ?? 0) * (element.productPurchasePrice ?? 0);

      // Calculate GST amounts for each item (same as sales - calculate from gstRateSelect)
      if (element.gstRateSelect != null &&
          element.gstRateSelect!.isNotEmpty &&
          element.gstRateSelect!.toLowerCase() != 'n/a' &&
          element.gstRateSelect != '0') {
        // Calculate GST amount dynamically from gstRateSelect (same as sales)
        double productTotal = (element.quantities ?? 0) *
            (element.productPurchasePrice ?? 0).toDouble();
        String rateString = element.gstRateSelect!.replaceAll('%', '').trim();
        double gstRate = num.tryParse(rateString)?.toDouble() ?? 0.0;

        if (gstRate > 0) {
          double itemGstAmount = (productTotal * gstRate) / 100;

          totalGstAmount += itemGstAmount;
          // GST is split equally between CGST and SGST
          totalCgstAmount += itemGstAmount / 2;
          totalSgstAmount += itemGstAmount / 2;
        }
      }
    }
    totalPayableAmount = totalAmount;

    if (discountAmount > totalAmount) {
      calculateDiscount(value: discountAmount.toString(), rebuilding: false);
    }
    if (discountAmount >= 0) {
      totalPayableAmount -= discountAmount;
    }

    // Add item-level GST first (same as sales)
    totalPayableAmount += totalGstAmount;

    // Then calculate and add VAT on the total (after GST is added, same as sales)
    if (selectedVat?.rate != null) {
      vatAmount = (totalPayableAmount * selectedVat!.rate!) / 100;
      vatAmountController.text = vatAmount.toStringAsFixed(2);

      // Print tax calculation details
      print('=== TAX CALCULATION DEBUG ===');
      print('Selected Tax Type: $selectedTaxType');
      print('VAT Rate: ${selectedVat!.rate}%');
      print(
          'Subtotal Amount (after discount): ${totalAmount - discountAmount}');
      print('Item-level GST: $totalGstAmount');
      print('Total before VAT: $totalPayableAmount');
      print('VAT on Total: $vatAmount');
      print('=============================');
    }

    totalPayableAmount += vatAmount;
    if (shippingCharge != null && shippingCharge.isNotEmpty) {
      finalShippingCharge = num.tryParse(shippingCharge) ?? 0;
    }
    totalPayableAmount += finalShippingCharge;
    if (serviceCharge != null && serviceCharge.isNotEmpty) {
      finalServiceCharge = num.tryParse(serviceCharge) ?? 0;
    }
    totalPayableAmount += finalServiceCharge;
    if (receivedAmount != null && receivedAmount.isNotEmpty) {
      receiveAmount = num.tryParse(receivedAmount) ?? 0;
    } else {
      receiveAmount = 0;
    }
    changeAmount = totalPayableAmount < receiveAmount
        ? receiveAmount - totalPayableAmount
        : 0;
    dueAmount = totalPayableAmount < receiveAmount
        ? 0
        : totalPayableAmount - receiveAmount;

    if (dueAmount <= 0) {
      isFullPaid = true;
    } else {
      isFullPaid = false;
    }

    // Debug print for calculation tracking
    print('=== PURCHASE PAYMENT CALCULATION ===');
    print('Subtotal (totalAmount): $totalAmount');
    print('Discount: $discountAmount');
    print('Item-level GST (totalGstAmount): $totalGstAmount');
    print('VAT on Total: $vatAmount');
    print('Shipping Charge: $finalShippingCharge');
    print('Service Charge: $finalServiceCharge');
    print('Total Payable: $totalPayableAmount');
    print('Received Amount: $receiveAmount');
    print('Due Amount: $dueAmount');
    print('Change Amount: $changeAmount');
    print('Paid Amount (to send): ${totalPayableAmount - dueAmount}');
    print('====================================');

    if (stopRebuild ?? false) return;
    notifyListeners();
  }

  double getTotalAmount() {
    double totalAmountOfCart = 0;
    for (var element in cartItemList) {
      totalAmountOfCart = totalAmountOfCart +
          ((element.productPurchasePrice ?? 0) * (element.quantities ?? 0));
    }

    return totalAmountOfCart;
  }

  quantityIncrease(int index) {
    cartItemList[index].quantities = (cartItemList[index].quantities ?? 0) + 1;
    calculatePrice();
  }

  quantityDecrease(int index) {
    if ((cartItemList[index].quantities ?? 0) > 1) {
      cartItemList[index].quantities =
          (cartItemList[index].quantities ?? 0) - 1;
    }
    calculatePrice();
  }

  addToCartRiverPod(
      {required CartProductModelPurchase cartItem, bool? fromEditSales}) {
    // Check if item exists - for variants, check both productId and variantKey
    int existingIndex = -1;
    if (cartItem.variantKey != null && cartItem.variantKey!.isNotEmpty) {
      // For variant products, match by both productId and variantKey
      existingIndex = cartItemList.indexWhere((element) =>
          element.productId == cartItem.productId &&
          element.variantKey == cartItem.variantKey);
    } else {
      // For non-variant products, match by productId only
      existingIndex = cartItemList.indexWhere((element) =>
          element.productId == cartItem.productId &&
          (element.variantKey == null || element.variantKey!.isEmpty));
    }

    if (existingIndex >= 0) {
      // Update existing item
      cartItemList[existingIndex] = cartItem;
    } else {
      // Add new item
      cartItemList.add(cartItem);
    }
    (fromEditSales ?? false) ? null : calculatePrice();
  }

  deleteToCart(int index) {
    cartItemList.removeAt(index);
    calculatePrice();
  }

  // Clear all cart data - used after successful purchase
  void clearCart() {
    cartItemList.clear();
    discountTextControllerFlat.clear();
    vatAmountController.clear();
    shippingChargeController.clear();
    serviceChargeController.clear();
    totalAmount = 0;
    discountAmount = 0;
    discountPercent = 0;
    totalPayableAmount = 0;
    selectedVat = null;
    vatAmount = 0;
    isFullPaid = false;
    receiveAmount = 0;
    changeAmount = 0;
    dueAmount = 0;
    finalShippingCharge = 0;
    finalServiceCharge = 0;
    totalGstAmount = 0;
    totalSgstAmount = 0;
    totalCgstAmount = 0;
    notifyListeners();
  }
}
