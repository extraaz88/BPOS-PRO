//ignore_for_file: prefer_typing_uninitialized_variables,unused_local_variable
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/product_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Provider/transactions_provider.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../../Customers/Provider/customer_provider.dart';
import '../Model/purchase_transaction_model.dart';

class PurchaseRepo {
  Future<List<PurchaseTransaction>> fetchPurchaseList(
      {bool? purchaseReturn}) async {
    final uri = Uri.parse(
        '${APIConfig.url}/purchase${(purchaseReturn ?? false) ? "?returned-purchase=true" : ''}');

    print('=== PURCHASE REPORT API DEBUG ===');
    print('Purchase API URL: $uri');
    print('Purchase Return: $purchaseReturn');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('Purchase API Response Status: ${response.statusCode}');
    print('Purchase API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Parsed Purchase Data: $parsedData');

      final partyList = parsedData['data'] as List<dynamic>;
      print('Purchase List Count: ${partyList.length}');

      // Print each purchase record
      for (int i = 0; i < partyList.length; i++) {
        print('Purchase $i: ${partyList[i]}');
      }

      return partyList
          .map((category) => PurchaseTransaction.fromJson(category))
          .toList();
      // Parse into Party objects
    } else {
      print('Purchase API Error: ${response.statusCode}');
      print('Purchase API Error Body: ${response.body}');
      throw Exception('Failed to fetch Purchase List');
    }
  }

  // Fetch held purchases
  Future<List<PurchaseTransaction>> fetchHeldPurchases() async {
    final uri = Uri.parse('${APIConfig.url}/purchase?type=Hold');

    print('=== HELD PURCHASES API DEBUG ===');
    print('Held Purchases API URL: $uri');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('Held Purchases API Response Status: ${response.statusCode}');
    print('Held Purchases API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Parsed Held Purchases Data: $parsedData');

      final heldPurchasesList = parsedData['data'] as List<dynamic>;
      print('Held Purchases Count: ${heldPurchasesList.length}');

      // Print each held purchase record
      for (int i = 0; i < heldPurchasesList.length; i++) {
        print('Held Purchase $i: ${heldPurchasesList[i]}');
      }

      return heldPurchasesList
          .map((purchase) => PurchaseTransaction.fromJson(purchase))
          .toList();
    } else {
      print('Held Purchases API Error: ${response.statusCode}');
      print('Held Purchases API Error Body: ${response.body}');
      throw Exception('Failed to fetch Held Purchases List');
    }
  }

  Future<PurchaseTransaction?> holdPurchase({
    required WidgetRef ref,
    required BuildContext context,
    required num partyId,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num? vatId,
    required num totalAmount,
    required num vatAmount,
    required num vatPercent,
    required num dueAmount,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartProductModelPurchase> products,
    required String discountType,
    required num shippingCharge,
    required num serviceCharge,
    required String taxType,
    bool? isSplitPayment,
    Map<int, double>? splitPaymentAmounts,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/purchase/hold');

    // Calculate paidAmount correctly: total - due = paid
    final num paidAmount = totalAmount - dueAmount;

    final Map<String, dynamic> requestData = {
      'party_id': partyId,
      'vat_id': vatId,
      'purchaseDate': purchaseDate,
      'discountAmount': discountAmount,
      'discount_percent': discountPercent,
      'totalAmount': totalAmount,
      'vat_amount': vatAmount,
      'vat_percent': vatPercent,
      'dueAmount': dueAmount,
      'paidAmount': paidAmount,
      'change_amount': changeAmount,
      'isPaid': isPaid,
      'payment_type_id': paymentType,
      'products': products.map((product) => product.toJson()).toList(),
      'discount_type': discountType,
      'shipping_charge': shippingCharge,
      'service_charge': serviceCharge,
      'tax_type': taxType,
      'type': 'Hold', // This is the key field for holding purchases
    };

    final requestBody = jsonEncode(requestData);

    // Debug: Print what we're sending to API
    print('=== HOLD PURCHASE API PAYLOAD DEBUG ===');
    print('Total Amount: $totalAmount');
    print('Due Amount: $dueAmount');
    print('Paid Amount (calculated): $paidAmount');
    print('Change Amount: $changeAmount');
    print('Is Paid: $isPaid');
    print('Type: Hold');
    print('==================================');

    // Print full API Request Details
    print('=== HOLD PURCHASE API REQUEST DEBUG ===');
    print('API URL: $uri');
    print('Request Body: $requestBody');
    print('===================================');

    try {
      var responseData = await http.post(
        uri,
        headers: {
          "Accept": 'application/json',
          'Authorization': await getAuthToken(),
          'Content-Type': 'application/json'
        },
        body: requestBody,
      );

      // Print API Response Details
      print('=== HOLD PURCHASE API RESPONSE DEBUG ===');
      print('Response Status Code: ${responseData.statusCode}');
      print('Response Headers: ${responseData.headers}');
      print('Response Body: ${responseData.body}');
      print('====================================');

      final parsedData = jsonDecode(responseData.body);

      if (responseData.statusCode == 200) {
        EasyLoading.showSuccess('Purchase held successfully!');
        // Refresh providers
        final _ = ref.refresh(productProvider);
        final __ = ref.refresh(partiesProvider);
        final ___ = ref.refresh(purchaseTransactionProvider);
        final ____ = ref.refresh(businessInfoProvider);
        final _____ = ref.refresh(getExpireDateProvider(ref));
        final ______ = ref.refresh(summaryInfoProvider);
        print('Hold Purchase Response: ${parsedData['data']}');
        return PurchaseTransaction.fromJson(parsedData['data']);
      } else {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Failed to hold purchase: ${parsedData['message']}')));
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss();
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An error occurred while holding purchase: $error')));
      return null;
    }
  }

  Future<PurchaseTransaction?> createPurchase({
    required WidgetRef ref,
    required BuildContext context,
    required num partyId,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num? vatId,
    required num totalAmount,
    required num vatAmount,
    required num vatPercent,
    required num dueAmount,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartProductModelPurchase> products,
    required String discountType,
    required num shippingCharge,
    required num serviceCharge,
    required String taxType,
    bool? isSplitPayment,
    Map<int, double>? splitPaymentAmounts,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/purchase');

    // Calculate paidAmount correctly: total - due = paid
    final num paidAmount = totalAmount - dueAmount;

    final Map<String, dynamic> requestData = {
      'party_id': partyId,
      'vat_id': vatId,
      'purchaseDate': purchaseDate,
      'discountAmount': discountAmount,
      'discount_percent': discountPercent,
      'totalAmount': totalAmount,
      'vat_amount': vatAmount,
      'vat_percent': vatPercent,
      'dueAmount': dueAmount,
      'paidAmount': paidAmount,
      'change_amount': changeAmount,
      'isPaid': isPaid,
      'payment_type_id': paymentType,
      'products': products.map((product) => product.toJson()).toList(),
      'discount_type': discountType,
      'shipping_charge': shippingCharge,
      'service_charge': serviceCharge,
      'tax_type': taxType,
    };

    // Split payment data
    if (isSplitPayment == true &&
        splitPaymentAmounts != null &&
        splitPaymentAmounts.isNotEmpty) {
      // Convert Map<int, double> to Map<String, dynamic> for JSON encoding
      final Map<String, dynamic> splitPaymentJson = {};
      splitPaymentAmounts.forEach((key, value) {
        splitPaymentJson[key.toString()] = value;
      });

      requestData['is_split_payment'] = '1';
      requestData['split_payment_amounts'] = jsonEncode(splitPaymentJson);
    }

    final requestBody = jsonEncode(requestData);

    // Debug: Print what we're sending to API
    print('=== PURCHASE API PAYLOAD DEBUG ===');
    print('Total Amount: $totalAmount');
    print('Due Amount: $dueAmount');
    print('Paid Amount (calculated): $paidAmount');
    print('Change Amount: $changeAmount');
    print('Is Paid: $isPaid');
    print('==================================');

    // Print full API Request Details
    print('=== PURCHASE API REQUEST DEBUG ===');
    print('API URL: $uri');
    print('Request Body: $requestBody');
    print('===================================');

    try {
      var responseData = await http.post(
        uri,
        headers: {
          "Accept": 'application/json',
          'Authorization': await getAuthToken(),
          'Content-Type': 'application/json'
        },
        body: requestBody,
      );

      // Print API Response Details
      print('=== PURCHASE API RESPONSE DEBUG ===');
      print('Response Status Code: ${responseData.statusCode}');
      print('Response Headers: ${responseData.headers}');
      print('Response Body: ${responseData.body}');
      print('====================================');

      final parsedData = jsonDecode(responseData.body);

      if (responseData.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!');
        // Refresh providers
        final _ = ref.refresh(productProvider);
        final __ = ref.refresh(partiesProvider);
        final ___ = ref.refresh(purchaseTransactionProvider);
        final ____ = ref.refresh(businessInfoProvider);
        final _____ = ref.refresh(getExpireDateProvider(ref));
        final ______ = ref.refresh(summaryInfoProvider);
        // Navigator.pop(context);
        print('Purchase Response: ${parsedData['data']}');
        return PurchaseTransaction.fromJson(parsedData['data']);
      } else {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Purchase creation failed: ${parsedData['message']}')));
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss();
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      return null;
    }
  }

  Future<PurchaseTransaction?> updatePurchase({
    required WidgetRef ref,
    required BuildContext context,
    required num id,
    required num partyId,
    required num? vatId,
    required num vatAmount,
    required num vatPercent,
    required String purchaseDate,
    required num discountAmount,
    required num totalAmount,
    required num dueAmount,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartProductModelPurchase> products,
    required num shippingCharge,
    required num serviceCharge,
    required String discountType,
    required String taxType,
    bool? isSplitPayment,
    Map<int, double>? splitPaymentAmounts,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/purchase/$id');

    // Calculate paidAmount correctly: total - due = paid
    final num paidAmount = totalAmount - dueAmount;

    final Map<String, dynamic> requestData = {
      '_method': 'put',
      'party_id': partyId,
      'vat_id': vatId,
      'purchaseDate': purchaseDate,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'vat_amount': vatAmount,
      'vat_percent': vatPercent,
      'dueAmount': dueAmount,
      'paidAmount': paidAmount,
      'change_amount': changeAmount,
      'isPaid': isPaid,
      'payment_type_id': paymentType,
      'products': products.map((product) => product.toJson()).toList(),
      'shipping_charge': shippingCharge,
      'service_charge': serviceCharge,
      'discount_type': discountType,
      'tax_type': taxType,
    };

    // Split payment data
    if (isSplitPayment == true &&
        splitPaymentAmounts != null &&
        splitPaymentAmounts.isNotEmpty) {
      // Convert Map<int, double> to Map<String, dynamic> for JSON encoding
      final Map<String, dynamic> splitPaymentJson = {};
      splitPaymentAmounts.forEach((key, value) {
        splitPaymentJson[key.toString()] = value;
      });

      requestData['is_split_payment'] = '1';
      requestData['split_payment_amounts'] = jsonEncode(splitPaymentJson);
    }

    final requestBody = jsonEncode(requestData);

    print('=== PURCHASE UPDATE API PAYLOAD ===');
    print('Total Amount: $totalAmount');
    print('Due Amount: $dueAmount');
    print('Paid Amount (calculated): $paidAmount');
    print('===================================');

    try {
      CustomHttpClient customHttpClient =
          CustomHttpClient(client: http.Client(), context: context, ref: ref);
      var responseData = await customHttpClient.post(
        url: uri,
        addContentTypeInHeader: true,
        body: requestBody,
      );

      final parsedData = jsonDecode(responseData.body);
      print(responseData.statusCode);
      print(parsedData);

      if (responseData.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!');
        // Refresh providers
        final _ = ref.refresh(productProvider);
        final __ = ref.refresh(partiesProvider);
        final ___ = ref.refresh(purchaseTransactionProvider);
        final ____ = ref.refresh(businessInfoProvider);
        final _____ = ref.refresh(getExpireDateProvider(ref));
        Navigator.pop(context);
        return PurchaseTransaction.fromJson(parsedData);
      } else {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Purchase creation failed: ${parsedData['message']}')));
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss();
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      return null;
    }
  }

  Future<void> deletePurchase({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/purchase/$id';

    try {
      CustomHttpClient customHttpClient =
          CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')));

        var data1 = ref.refresh(productProvider);

        Navigator.pop(
            context); // Assuming you want to close the screen after deletion
        Navigator.pop(
            context); // Assuming you want to close the screen after deletion
        // Navigator.pop(context); // Assuming you want to close the screen after deletion
      } else {
        final parsedData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Failed to delete product: ${parsedData['message']}')));
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Method specifically for deleting held purchases (doesn't close screen)
  Future<bool> deleteHeldPurchase({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/purchase/$id';

    try {
      CustomHttpClient customHttpClient =
          CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Held purchase deleted successfully')));

        // Refresh providers
        // ignore: unused_result
        ref.refresh(productProvider);
        // ignore: unused_result
        ref.refresh(partiesProvider);
        // ignore: unused_result
        ref.refresh(purchaseTransactionProvider);
        // ignore: unused_result
        ref.refresh(businessInfoProvider);
        // ignore: unused_result
        ref.refresh(getExpireDateProvider(ref));

        return true;
      } else {
        final parsedData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to delete held purchase: ${parsedData['message']}')));
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting held purchase: $e')));
      return false;
    }
  }
}

class CartProductModelPurchase {
  num productId;
  String productName;
  String? brandName;
  num? productDealerPrice;
  num? productPurchasePrice;
  num? productSalePrice;
  num? productWholeSalePrice;
  num? quantities;
  num? stock;
  String? vatType;
  num? vatAmount;
  String? gstRateSelect;
  String? variantKey;
  String? variantLabel;
  Map<String, String>? productDetails;
  num? stockId;

  CartProductModelPurchase({
    required this.productId,
    required this.productName,
    this.brandName,
    this.stock,
    required this.productDealerPrice,
    required this.productPurchasePrice,
    required this.productSalePrice,
    required this.productWholeSalePrice,
    required this.quantities,
    this.vatType,
    this.vatAmount,
    this.gstRateSelect,
    this.variantKey,
    this.variantLabel,
    this.productDetails,
    this.stockId,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'productDealerPrice': productDealerPrice,
        'productPurchasePrice': productPurchasePrice,
        'productSalePrice': productSalePrice,
        'productWholeSalePrice': productWholeSalePrice,
        'quantities': quantities,
        'vat_type': vatType,
        'vat_amount': vatAmount,
        'gst_rate_select': gstRateSelect,
        'variant_key': variantKey,
        'variant_label': variantLabel,
        'product_details': productDetails != null
            ? productDetails!.map((key, value) => MapEntry(key, value))
            : null,
        'stock_id': stockId,
      };
}
