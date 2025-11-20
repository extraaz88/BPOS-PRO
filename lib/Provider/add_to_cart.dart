import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/model/business_info_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens/Settings/sales settings/model/amount_rounding_dropdown_model.dart';
import '../Screens/vat_&_tax/model/vat_model.dart';
import '../constant.dart';
import '../model/add_to_cart_model.dart';

final cartNotifier = ChangeNotifierProvider((ref) {
  return CartNotifier(
      businessInformation: ref.watch(businessInfoProvider).value);
});

class CartNotifier extends ChangeNotifier {
  final BusinessInformation? businessInformation;

  CartNotifier({required this.businessInformation}) {
    _loadRoundOffSetting();
  }

  @override
  void addListener(VoidCallback listener) {
    // TODO: implement addListener
    super.addListener(listener);
    roundedOption =
        businessInformation?.saleRoundingOption ?? roundingMethods[0].value;
  }

  List<AddToCartModel> cartItemList = [];
  TextEditingController discountTextControllerFlat = TextEditingController();
  TextEditingController vatAmountController = TextEditingController();
  TextEditingController shippingChargeController = TextEditingController();
  TextEditingController serviceChargeController = TextEditingController();

  ///_________NEW_________________________________
  num totalAmount = 0;
  num discountAmount = 0;
  num discountPercent = 0;
  num roundingAmount = 0;
  num actualTotalAmount = 0;
  num totalPayableAmount = 0;
  VatModel? selectedVat;
  num vatAmount = 0;
  bool isFullPaid = false;
  num receiveAmount = 0;
  num changeAmount = 0;
  num dueAmount = 0;
  num finalShippingCharge = 0;
  num finalServiceCharge = 0;
  String selectedTaxType = 'GST'; // Always GST
  String roundedOption = roundingMethods[0].value;
  bool roundOffEnabled = false;

  // GST calculation variables
  num totalGstAmount = 0;
  num totalSgstAmount = 0;
  num totalCgstAmount = 0;

  bool _isSameCartItem(AddToCartModel first, AddToCartModel second) {
    final firstKey = first.variantKey?.trim();
    final secondKey = second.variantKey?.trim();
    if ((firstKey?.isNotEmpty ?? false) || (secondKey?.isNotEmpty ?? false)) {
      return first.productId == second.productId && firstKey == secondKey;
    }
    return first.productId == second.productId;
  }

  bool _matchesCartItem(
      AddToCartModel element, num productId, String? variantKey) {
    final trimmedKey = variantKey?.trim();
    if (trimmedKey != null && trimmedKey.isNotEmpty) {
      return element.productId == productId &&
          (element.variantKey?.trim() == trimmedKey);
    }
    return element.productId == productId &&
        (element.variantKey == null || element.variantKey!.trim().isEmpty);
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

  void calculateDiscount(
      {required String value, bool? rebuilding, String? selectedTaxType}) {
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
      } else if (selectedTaxType == "Percent") {
        discountPercent = num.tryParse(discountTextControllerFlat.text) ?? 0.0;
        discountAmount = (totalAmount * discountValue) / 100;

        if (discountAmount > totalAmount) {
          discountAmount = totalAmount;
        }
      } else {
        EasyLoading.showError('Invalid discount type selected');
        discountAmount = 0;
      }

      if (discountAmount > totalAmount) {
        discountTextControllerFlat.clear();
        discountAmount = 0;
        EasyLoading.showError('Enter a valid discount');
      }
    }

    if (rebuilding == false) return;
    calculatePrice();
  }

  void updateProduct({
    required num productId,
    required String price,
    required String qty,
    String? variantKey,
  }) {
    int index = cartItemList.indexWhere(
      (element) => _matchesCartItem(element, productId, variantKey),
    );
    if (index == -1) {
      return;
    }
    cartItemList[index].unitPrice = price;
    cartItemList[index].quantity = num.tryParse(qty) ?? 0;
    calculatePrice();
  }

  void calculatePrice(
      {String? receivedAmount,
      String? shippingCharge,
      String? serviceCharge,
      bool? stopRebuild}) {
    totalAmount = 0;
    totalPayableAmount = 0;
    dueAmount = 0;

    // Reset GST amounts
    totalGstAmount = 0;
    totalSgstAmount = 0;
    totalCgstAmount = 0;

    for (var element in cartItemList) {
      totalAmount += element.quantity * (num.tryParse(element.unitPrice) ?? 0);

      // Calculate GST amounts for each item
      if (element.gstRateSelect != null) {
        double itemGstAmount = element.calculateGstAmount(selectedTaxType);
        totalGstAmount += itemGstAmount;

        // Always split GST into SGST and CGST (50-50)
        totalSgstAmount += itemGstAmount / 2;
        totalCgstAmount += itemGstAmount / 2;
      }
    }

    totalPayableAmount = totalAmount;

    if (discountAmount > totalAmount) {
      calculateDiscount(
        value: discountAmount.toString(),
        rebuilding: false,
      );
    }
    if (discountAmount >= 0) {
      totalPayableAmount -= discountAmount;
    }

    // Add GST to total
    totalPayableAmount += totalGstAmount;

    if (selectedVat?.rate != null) {
      vatAmount = (totalPayableAmount * selectedVat!.rate!) / 100;
      vatAmountController.text = vatAmount.toStringAsFixed(2);
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
    actualTotalAmount = totalPayableAmount;

    final String fallbackOption = roundingMethods[0].value;
    final String effectiveRoundingOption = roundOffEnabled
        ? (roundedOption.isEmpty || roundedOption == fallbackOption
            ? 'nearest_whole_number'
            : roundedOption)
        : fallbackOption;
    final bool shouldApplyRoundOff =
        roundOffEnabled && effectiveRoundingOption != fallbackOption;
    final num roundedTotal = roundNumber(
      value: totalPayableAmount,
      roundingType: effectiveRoundingOption,
    );

    if (shouldApplyRoundOff) {
      roundingAmount = roundedTotal - totalPayableAmount;
      totalPayableAmount = roundedTotal;
    } else {
      roundingAmount = 0;
    }
    if (receivedAmount != null && receivedAmount.isNotEmpty) {
      receiveAmount = num.tryParse(receivedAmount) ?? 0;
    } else {
      receiveAmount = 0;
    }

    changeAmount = totalPayableAmount < receiveAmount
        ? receiveAmount - totalPayableAmount
        : 0;

    // Only calculate due amount if partial amount is entered
    if (receivedAmount != null &&
        receivedAmount.isNotEmpty &&
        (num.tryParse(receivedAmount) ?? 0) > 0) {
      dueAmount = totalPayableAmount < receiveAmount
          ? 0
          : totalPayableAmount - receiveAmount;
    } else {
      dueAmount = 0; // No due amount when no partial amount is entered
    }
    if (dueAmount <= 0) {
      isFullPaid = true;
    } else {
      isFullPaid = false;
    }
    if (stopRebuild ?? false) return;

    // Only notify listeners if the notifier is not disposed
    try {
      notifyListeners();
    } catch (e) {
      print(
          'CartNotifier: Cannot notify listeners in calculatePrice - notifier may be disposed: $e');
    }
  }

  quantityIncrease(int index) {
    final num? availableStock = cartItemList[index].stock;
    final num currentQuantity = cartItemList[index].quantity;

    // When stock is not tracked or zero, allow selling without showing overflow
    if (availableStock == null || availableStock <= 0) {
      cartItemList[index].quantity = currentQuantity + 1;
      calculatePrice();
      return;
    }

    if (availableStock > currentQuantity) {
      if (availableStock < currentQuantity + 1) {
        cartItemList[index].quantity = availableStock;
      } else {
        cartItemList[index].quantity = currentQuantity + 1;
      }

      calculatePrice();
    } else {
      EasyLoading.showError('Stock Overflow');
    }
  }

  quantityDecrease(int index) {
    if (cartItemList[index].quantity > 1) {
      cartItemList[index].quantity--;
    }
    calculatePrice();
  }

  addToCartRiverPod(
      {required AddToCartModel cartItem,
      bool? fromEditSales,
      int incrementQuantity = 1}) {
    // Automatically set 18% GST for all products if not already set
    if (cartItem.gstRateSelect == null) {
      cartItem.gstRateSelect = '0';
      cartItem.gstType ??= 'Taxable';
    }

    bool isAlreadyInList =
        cartItemList.any((element) => _isSameCartItem(element, cartItem));
    if (isAlreadyInList) {
      int index = cartItemList.indexWhere(
        (element) => _isSameCartItem(element, cartItem),
      );

      // Ensure we always keep the latest stock information
      num? latestStock = cartItem.stock ?? cartItemList[index].stock;
      if (latestStock != null) {
        cartItemList[index].stock = latestStock;
      }

      // Check stock availability before incrementing
      int currentQuantity = cartItemList[index].quantity.toInt();
      int newQuantity = currentQuantity + incrementQuantity;
      num? availableStock = cartItemList[index].stock;

      if (availableStock != null &&
          availableStock > 0 &&
          newQuantity > availableStock) {
        // If increment would exceed stock, set to maximum available stock
        cartItemList[index].quantity = availableStock;
        EasyLoading.showError(
            'Stock limit reached. Set to maximum available quantity.');
      } else {
        cartItemList[index].quantity = newQuantity;
      }
    } else {
      cartItemList.add(cartItem);
    }
    (fromEditSales ?? false) ? null : calculatePrice();
  }

  deleteToCart(int index) {
    cartItemList.removeAt(index);
    calculatePrice();
  }

  // Method to add items with bulk quantity
  addToCartWithBulkQuantity(
      {required AddToCartModel cartItem,
      required int quantity,
      bool? fromEditSales}) {
    // Automatically set 18% GST for all products if not already set
    if (cartItem.gstRateSelect == null) {
      cartItem.gstRateSelect = '0';
      cartItem.gstType ??= 'Taxable';
    }

    bool isAlreadyInList =
        cartItemList.any((element) => _isSameCartItem(element, cartItem));
    if (isAlreadyInList) {
      int index = cartItemList.indexWhere(
        (element) => _isSameCartItem(element, cartItem),
      );

      // Update stored stock with the latest value before validation
      num? latestStock = cartItem.stock ?? cartItemList[index].stock;
      if (latestStock != null) {
        cartItemList[index].stock = latestStock;
      }
      num? availableStock = cartItemList[index].stock;

      // Check stock availability before setting quantity
      if (availableStock != null &&
          availableStock > 0 &&
          quantity > availableStock) {
        // If quantity exceeds stock, set to maximum available stock
        cartItemList[index].quantity = availableStock;
        EasyLoading.showError(
            'Stock limit reached. Set to maximum available quantity: ${cartItemList[index].stock}');
      } else {
        cartItemList[index].quantity = quantity;
      }
    } else {
      // Create new cart item with the specified quantity
      cartItem.quantity = quantity;
      cartItemList.add(cartItem);
    }
    (fromEditSales ?? false) ? null : calculatePrice();
  }

  // Set due amount from external source (e.g., due completion)
  void setDueAmount(num amount) {
    dueAmount = amount;
    if (dueAmount <= 0) {
      isFullPaid = true;
    } else {
      isFullPaid = false;
    }
    notifyListeners();
  }

  // Clear all cart data - used after successful sale
  void clearCart() {
    cartItemList.clear();
    discountTextControllerFlat.clear();
    vatAmountController.clear();
    shippingChargeController.clear();
    serviceChargeController.clear();
    totalAmount = 0;
    discountAmount = 0;
    discountPercent = 0;
    roundingAmount = 0;
    actualTotalAmount = 0;
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
    roundedOption =
        businessInformation?.saleRoundingOption ?? roundingMethods[0].value;

    // Only notify listeners if the notifier is not disposed
    try {
      notifyListeners();
    } catch (e) {
      print(
          'CartNotifier: Cannot notify listeners - notifier may be disposed: $e');
    }
  }

  void _loadRoundOffSetting() {
    SharedPreferences.getInstance().then((prefs) {
      roundOffEnabled = prefs.getBool(kSalesRoundOffToggleKey) ?? false;
      calculatePrice();
    });
  }

  void updateRoundOffEnabled(bool value) {
    roundOffEnabled = value;
    calculatePrice();
  }

  @override
  void dispose() {
    discountTextControllerFlat.dispose();
    vatAmountController.dispose();
    shippingChargeController.dispose();
    serviceChargeController.dispose();
    super.dispose();
  }
}
