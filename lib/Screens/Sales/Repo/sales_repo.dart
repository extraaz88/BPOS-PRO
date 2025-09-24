import 'dart:convert';
import 'dart:io';

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
import '../../../model/sale_transaction_model.dart';
import '../../Customers/Provider/customer_provider.dart';

class SaleRepo {
  Future<List<SalesTransactionModel>> fetchSalesList({bool? salesReturn}) async {
    final uri = Uri.parse('${APIConfig.url}/sales${(salesReturn ?? false) ? "?returned-sales=true" : ''}');

    print('=== SALES REPORT API DEBUG ===');
    print('Sales API URL: $uri');
    print('Sales Return: $salesReturn');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('Sales API Response Status: ${response.statusCode}');
    print('Sales API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Parsed Sales Data: $parsedData');

      final partyList = parsedData['data'] as List<dynamic>;
      print('Sales List Count: ${partyList.length}');
      
      // Print each sale record
      for (int i = 0; i < partyList.length; i++) {
        print('Sale $i: ${partyList[i]}');
      }

      return partyList.map((category) => SalesTransactionModel.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      print('Sales API Error: ${response.statusCode}');
      print('Sales API Error Body: ${response.body}');
      throw Exception('Failed to fetch Sales List');
    }
  }

  Future<SalesTransactionModel?> createSale({
    required WidgetRef ref,
    required BuildContext context,
    required num? partyId,
    required String? customerPhone,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num unRoundedTotalAmount,
    required num totalAmount,
    required num roundingAmount,
    required num dueAmount,
    required num vatAmount,
    required num vatPercent,
    required num? vatId,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required String roundedOption,
    required List<CartSaleProducts> products,
    required String discountType,
    required num shippingCharge,
    String? note,
    File? image,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales');

    try {
      var request = http.MultipartRequest("POST", uri);

      CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), ref: ref, context: context);
      request.headers.addAll({
        "Accept": 'application/json',
        'Authorization': await getAuthToken(),
        'Content-Type': 'multipart/form-data',
      });

      // JSON data fields
      request.fields.addAll({
        'party_id': partyId?.toString() ?? '',
        'customer_phone': customerPhone ?? '',
        'saleDate': purchaseDate,
        'discountAmount': discountAmount.toString(),
        'discount_percent': discountPercent.toString(),
        'totalAmount': totalAmount.toString(),
        'dueAmount': dueAmount.toString(),
        'paidAmount': (totalAmount - dueAmount).toString(),
        'change_amount': changeAmount.toString(),
        'vat_amount': vatAmount.toString(),
        'vat_percent': vatPercent.toString(),
        'isPaid': isPaid.toString(),
        'payment_type_id': paymentType,
        'discount_type': discountType,
        'shipping_charge': shippingCharge.toString(),
        'rounding_option': roundedOption,
        'rounding_amount': roundingAmount.toStringAsFixed(2),
        'actual_total_amount': unRoundedTotalAmount.toString(),
        'note': note ?? '',
        'products': jsonEncode(
          products.map((product) => product.toJson()).toList(),
        ),
      });
      if (vatId != null) {
        request.fields.addAll({
          'vat_id': vatId.toString(),
        });
      }
      // If an image is provided, attach it to the request
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      print('=== SALES CREATE DEBUG ===');
      print('Request URL: $uri');
      print('Request Fields: ${request.fields}');
      print('Party ID: $partyId');
      print('Customer Phone: $customerPhone');
      print('Total Amount: $totalAmount');
      print('Due Amount: $dueAmount');
      print('Payment Type: $paymentType');
      print('Is Paid: $isPaid');
      print('Products JSON: ${request.fields['products']}');
      print('Products Count: ${products.length}');
      
      var streamedResponse = await customHttpClient.uploadFile(url: uri, file: image, fileFieldName: 'image', fields: request.fields, countentType: 'multipart/form-data');
      var response = await http.Response.fromStream(streamedResponse);
      final parsedData = jsonDecode(response.body);
      print('Sales Post Status: ${response.statusCode}');
      print('Sales Post Response: ${response.body}');

      if (response.statusCode == 200) {
        await ref.refresh(productProvider);
        await ref.refresh(partiesProvider);
        await ref.refresh(salesTransactionProvider);
        await ref.refresh(businessInfoProvider);
        await ref.refresh(getExpireDateProvider(ref));
        await ref.refresh(summaryInfoProvider);
        print('${parsedData['data']}');
        final data = SalesTransactionModel.fromJson(parsedData['data']);
        return data;
      } else {
        print('Sales creation failed with status: ${response.statusCode}');
        print('Error message: ${parsedData['message'] ?? 'Unknown error'}');
        print('Full response: ${response.body}');
        
        EasyLoading.dismiss().then(
          (value) {
            String errorMessage = 'Sales creation failed';
            if (parsedData['message'] != null) {
              errorMessage = 'Sales creation failed: ${parsedData['message']}';
            } else if (parsedData['errors'] != null) {
              // Handle validation errors
              var errors = parsedData['errors'] as Map<String, dynamic>;
              var errorList = <String>[];
              errors.forEach((key, value) {
                if (value is List) {
                  errorList.addAll(value.map((e) => e.toString()));
                } else {
                  errorList.add(value.toString());
                }
              });
              errorMessage = 'Validation errors: ${errorList.join(', ')}';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          },
        );
        return null;
      }
    } catch (error) {
      print('Sales creation exception: $error');
      EasyLoading.dismiss().then(
        (value) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
      return null;
    }
  }

  Future<void> updateSale({
    required WidgetRef ref,
    required BuildContext context,
    required num id,
    required num? partyId,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num unRoundedTotalAmount,
    required num totalAmount,
    required num dueAmount,
    required num vatAmount,
    required num vatPercent,
    required num? vatId,
    required num changeAmount,
    required num roundingAmount,
    required bool isPaid,
    required String paymentType,
    required String roundedOption,
    required List<CartSaleProducts> products,
    required String discountType,
    required num shippingCharge,
    String? note,
    File? image,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales/$id');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), ref: ref, context: context);
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = await getAuthToken()
      ..headers['Content-Type'] = 'application/json'
      ..fields['_method'] = 'put'
      ..fields['party_id'] = partyId.toString()
      ..fields['saleDate'] = purchaseDate
      ..fields['discountAmount'] = discountAmount.toString()
      ..fields['discount_percent'] = discountPercent.toString()
      ..fields['totalAmount'] = totalAmount.toString()
      ..fields['dueAmount'] = dueAmount.toString()
      ..fields['paidAmount'] = (totalAmount - dueAmount).toString()
      ..fields['change_amount'] = changeAmount.toString()
      ..fields['vat_amount'] = vatAmount.toString()
      ..fields['vat_percent'] = vatPercent.toString()
      ..fields['isPaid'] = isPaid.toString()
      ..fields['payment_type_id'] = paymentType
      ..fields['discount_type'] = discountType
      ..fields['shipping_charge'] = shippingCharge.toString()
      ..fields['note'] = note ?? ''
      ..fields['rounding_option'] = roundedOption
      ..fields['rounding_amount'] = roundingAmount.toStringAsFixed(2)
      ..fields['actual_total_amount'] = unRoundedTotalAmount.toString();

    // Convert the list of products to a JSON string
    String productJson = jsonEncode(products.map((product) => product.toJson()).toList());
    request.fields['products'] = productJson;

    if (vatId != null) {
      request.fields.addAll({'vat_id': vatId.toString()});
    }

    // Add image if it exists
    if (image != null) {
      var imageFile = await http.MultipartFile.fromPath('image', image.path);
      request.files.add(imageFile);
    }

    try {
      var response = await customHttpClient.uploadFile(url: uri, fields: request.fields, fileFieldName: 'image', file: image);

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!').then((value) async {
          await ref.refresh(productProvider);
          await ref.refresh(partiesProvider);
          await ref.refresh(salesTransactionProvider);
          await ref.refresh(businessInfoProvider);
          await ref.refresh(getExpireDateProvider(ref));
          Navigator.pop(context);
        });
      } else {
        var responseData = await http.Response.fromStream(response);
        final parsedData = jsonDecode(responseData.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sales creation failed: ${parsedData['message']}')));
      }
    } catch (error) {
      EasyLoading.dismiss().then((value) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      });
    }
  }
}

class CartSaleProducts {
  final int productId;
  final num? price;
  final num? lossProfit;
  final num? quantities;
  final int? stockId;

  CartSaleProducts({
    required this.productId,
    required this.price,
    required this.quantities,
    required this.lossProfit,
    this.stockId,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'price': price,
        'lossProfit': lossProfit,
        'quantities': quantities,
        'stock_id': stockId ?? productId, // Use provided stockId or fallback to productId
      };
}