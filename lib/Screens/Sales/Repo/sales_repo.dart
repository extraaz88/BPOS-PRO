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
  Future<List<SalesTransactionModel>> fetchSalesList(
      {bool? salesReturn}) async {
    final uri = Uri.parse(
        '${APIConfig.url}/sales${(salesReturn ?? false) ? "?returned-sales=true" : ''}');

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

      return partyList
          .map((category) => SalesTransactionModel.fromJson(category))
          .toList();
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
    required num serviceCharge,
    required String? taxType,
    String? note,
    File? image,
    bool? isSplitPayment,
    Map<int, double>? splitPaymentAmounts,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales');

    try {
      var request = http.MultipartRequest("POST", uri);

      CustomHttpClient customHttpClient =
          CustomHttpClient(client: http.Client(), ref: ref, context: context);
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
        'service_charge': serviceCharge.toString(),
        'tax_type': taxType ?? '',
        'total_tax_amount': products
            .fold(0.0, (sum, product) => sum + (product.taxAmount ?? 0))
            .toString(),
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

      // Split payment data
      if (isSplitPayment == true &&
          splitPaymentAmounts != null &&
          splitPaymentAmounts.isNotEmpty) {
        // Convert Map<int, double> to Map<String, dynamic> for JSON encoding
        final Map<String, dynamic> splitPaymentJson = {};
        splitPaymentAmounts.forEach((key, value) {
          splitPaymentJson[key.toString()] = value;
        });

        // Debug: Print split payment data being sent to API
        print('🔴 Sales API - Split Payment Data:');
        print('  is_split_payment: true');
        print('  split_payment_amounts: ${jsonEncode(splitPaymentJson)}');
        splitPaymentAmounts.forEach((key, value) {
          print('    Payment Type ID: $key, Amount: ₹$value');
        });

        request.fields.addAll({
          'is_split_payment': 'true',
          'split_payment_amounts': jsonEncode(splitPaymentJson),
        });

        // Detailed Request Body Logging for Split Payment
        print('\n🔵 ===== SPLIT PAYMENT REQUEST BODY =====');
        print('📤 Request URL: $uri');
        print('📤 Request Method: POST');
        print('📤 is_split_payment: true');
        print(
            '📤 split_payment_amounts (JSON): ${jsonEncode(splitPaymentJson)}');
        print('📤 Split Payment Details:');
        splitPaymentAmounts.forEach((key, value) {
          print('   → Payment Type ID: $key, Amount: ₹$value');
        });
        print(
            '📤 Total Split Amount: ₹${splitPaymentAmounts.values.fold(0.0, (sum, amount) => sum + amount)}');
        print('📤 Total Amount (Expected): ₹$totalAmount');
        print('🔵 ===========================================\n');
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
      print('Products JSON String: ${request.fields['products']}');

      // Print complete request body AFTER all fields are added
      print('\n=== COMPLETE REQUEST BODY ===');
      print('Total Request Fields: ${request.fields.length}');
      print('Total Request Files: ${request.files.length}');

      // Check if split payment is added
      print('\n🔍 SPLIT PAYMENT CHECK:');
      print('  isSplitPayment: $isSplitPayment');
      print('  splitPaymentAmounts: $splitPaymentAmounts');
      print(
          '  splitPaymentAmounts.isEmpty: ${splitPaymentAmounts?.isEmpty ?? true}');
      print(
          '  is_split_payment in fields: ${request.fields.containsKey('is_split_payment')}');
      print(
          '  split_payment_amounts in fields: ${request.fields.containsKey('split_payment_amounts')}');

      // Print all request fields with split payment details
      print('\n📋 ALL REQUEST FIELDS (${request.fields.length} fields):');
      if (request.fields.isEmpty) {
        print('  ⚠️ WARNING: Request fields are EMPTY!');
      } else {
        int fieldIndex = 0;
        request.fields.forEach((key, value) {
          fieldIndex++;
          if (key == 'split_payment_amounts') {
            print('  [$fieldIndex] ✅ $key: ${value}');
            try {
              final decoded = jsonDecode(value);
              if (decoded is Map) {
                print('      └─ Decoded Split Payments:');
                decoded.forEach((k, v) {
                  print('         • Payment Type $k: ₹$v');
                });
              }
            } catch (e) {
              print('      └─ ⚠️ Error decoding: $e');
            }
          } else if (key == 'products') {
            print('  [$fieldIndex] 📦 $key: [${products.length} products]');
          } else if (key == 'is_split_payment') {
            print('  [$fieldIndex] 🔵 $key: $value');
          } else {
            // Truncate long values
            String displayValue = value.toString();
            if (displayValue.length > 100) {
              displayValue = '${displayValue.substring(0, 100)}...';
            }
            print('  [$fieldIndex] 📄 $key: $displayValue');
          }
        });
      }

      if (request.files.isNotEmpty) {
        print('\n📎 REQUEST FILES:');
        for (var file in request.files) {
          print('  📎 ${file.field}: ${file.filename}');
        }
      }

      // Print each field individually for better readability
      print('=== REQUEST FIELDS BREAKDOWN ===');
      request.fields.forEach((key, value) {
        if (key == 'split_payment_amounts') {
          print('Field: $key = ${value} (Split Payment JSON)');
          try {
            final decoded = jsonDecode(value);
            if (decoded is Map) {
              decoded.forEach((k, v) {
                print('  └─ Payment Type $k: ₹$v');
              });
            }
          } catch (e) {
            print('  └─ Error decoding: $e');
          }
        } else {
          print('Field: $key = $value');
        }
      });

      // Print files if any
      if (request.files.isNotEmpty) {
        print('=== REQUEST FILES ===');
        for (var file in request.files) {
          print('File: ${file.field} = ${file.filename}');
        }
      }

      // Parse and pretty print the products JSON
      try {
        var productsJsonString = request.fields['products'];
        if (productsJsonString != null) {
          var productsJson = jsonDecode(productsJsonString);
          print('Parsed Products JSON: $productsJson');
          for (int i = 0; i < productsJson.length; i++) {
            print('Parsed Product $i: ${productsJson[i]}');
            print(
                '  - Has stock_id: ${productsJson[i].containsKey('stock_id')}');
            print('  - stock_id value: ${productsJson[i]['stock_id']}');
          }
        }
      } catch (e) {
        print('Error parsing products JSON: $e');
      }
      print('Products Count: ${products.length}');
      print('=== PRODUCTS BEING SENT ===');
      for (int i = 0; i < products.length; i++) {
        var productJson = products[i].toJson();
        print('Product $i: $productJson');
        print('  - Product ID: ${products[i].productId}');
        print('  - Stock ID: ${products[i].stockId}');
        print('  - Price: ${products[i].price}');
        print('  - Quantities: ${products[i].quantities}');
        print('  - GST Rate Select: ${products[i].gstRateSelect}');
        print('  - Tax Amount: ${products[i].taxAmount}');
        print(
            '  - Has stock_id in JSON: ${productJson.containsKey('stock_id')}');
        print(
            '  - Has gst_rate_select in JSON: ${productJson.containsKey('gst_rate_select')}');
        print(
            '  - Has tax_amount in JSON: ${productJson.containsKey('tax_amount')}');
        if (productJson.containsKey('stock_id')) {
          print('  - stock_id value: ${productJson['stock_id']}');
          print('  - stock_id type: ${productJson['stock_id'].runtimeType}');
        } else {
          print('  - stock_id: NOT INCLUDED (null value)');
        }
        if (productJson.containsKey('gst_rate_select')) {
          print('  - gst_rate_select value: ${productJson['gst_rate_select']}');
        } else {
          print('  - gst_rate_select: NOT INCLUDED (null value)');
        }
        if (productJson.containsKey('tax_amount')) {
          print('  - tax_amount value: ${productJson['tax_amount']}');
          print(
              '  - tax_amount type: ${productJson['tax_amount'].runtimeType}');
        } else {
          print('  - tax_amount: NOT INCLUDED (null value)');
        }
      }

      var streamedResponse = await customHttpClient.uploadFile(
          url: uri,
          file: image,
          fileFieldName: 'image',
          fields: request.fields,
          countentType: 'multipart/form-data');
      var response = await http.Response.fromStream(streamedResponse);
      final parsedData = jsonDecode(response.body);
      print('=== SALES CREATION API RESPONSE ===');
      print('Sales Post Status: ${response.statusCode}');
      print('Sales Post Response: ${response.body}');
      print('AUTHToken: ${await getAuthToken()}');

      // Split Payment Response Logging
      if (isSplitPayment == true && splitPaymentAmounts != null) {
        print('\n🔵 ===== SPLIT PAYMENT RESPONSE LOGS =====');
        print('📤 Split Payment Sent:');
        splitPaymentAmounts.forEach((key, value) {
          print('   Payment Type ID: $key, Amount: ₹$value');
        });
        print('📥 Split Payment Response:');
        if (parsedData['data'] != null) {
          final saleData = parsedData['data'];
          print('   Sale ID: ${saleData['id']}');
          print('   is_split_payment: ${saleData['is_split_payment']}');
          print(
              '   split_payment_amounts: ${saleData['split_payment_amounts']}');
          print('   payment_type_id: ${saleData['payment_type_id']}');
          print('   totalAmount: ${saleData['totalAmount']}');
          print('   paidAmount: ${saleData['paidAmount']}');
          print('   dueAmount: ${saleData['dueAmount']}');

          // Pretty print split payment amounts from response
          if (saleData['split_payment_amounts'] != null) {
            try {
              final responseSplitPayments = saleData['split_payment_amounts'];
              if (responseSplitPayments is String) {
                final decoded = jsonDecode(responseSplitPayments);
                print('   Decoded Split Payments:');
                if (decoded is Map) {
                  decoded.forEach((key, value) {
                    print('     Payment Type $key: ₹$value');
                  });
                }
              } else if (responseSplitPayments is Map) {
                print('   Split Payments:');
                responseSplitPayments.forEach((key, value) {
                  print('     Payment Type $key: ₹$value');
                });
              }
            } catch (e) {
              print('   Error parsing split payment amounts: $e');
            }
          }
        }
        print('🔵 ===========================================\n');
      }

      if (response.statusCode == 200) {
        try {
          ref.invalidate(productProvider);
          ref.invalidate(partiesProvider);
          ref.invalidate(salesTransactionProvider);
          ref.invalidate(businessInfoProvider);
          ref.invalidate(getExpireDateProvider(ref));
          ref.invalidate(summaryInfoProvider);
        } catch (e) {
          print('Error refreshing providers after sale creation: $e');
          // Continue execution even if provider refresh fails
        }

        // Print detailed response information
        print('=== SALES RESPONSE DETAILS ===');
        print('Response Data: ${parsedData['data']}');

        // Print tax information from response
        if (parsedData['data'] != null) {
          var saleData = parsedData['data'];
          print('Sale ID: ${saleData['id']}');
          print('Total Amount: ${saleData['totalAmount']}');
          print('VAT Amount: ${saleData['vat_amount']}');
          print('VAT Percent: ${saleData['vat_percent']}');
          print('Tax Type: ${taxType ?? 'Not specified'}');
          print(
              'Service Charge: ${saleData['service_charge'] ?? 'Not specified'}');
          print(
              'Total Tax Amount: ${saleData['total_tax_amount'] ?? 'Not specified'}');

          // Print product-wise tax information if available
          if (saleData['details'] != null) {
            print('=== PRODUCT TAX DETAILS ===');
            var details = saleData['details'] as List;
            for (int i = 0; i < details.length; i++) {
              var product = details[i];
              print('Product $i:');
              print('  - Product ID: ${product['product_id']}');
              print('  - Price: ${product['price']}');
              print('  - Quantities: ${product['quantities']}');
              print(
                  '  - GST Rate: ${product['gst_rate_select'] ?? 'Not specified'}');
              print(
                  '  - Tax Amount: ${product['tax_amount'] ?? 'Not specified'}');
              print(
                  '  - GST Amount: ${product['gst_amount'] ?? 'Not specified'}');
              print(
                  '  - Product Tax Amount: ${product['product_tax_amount'] ?? 'Not specified'}');
            }
          }
        }

        final data = SalesTransactionModel.fromJson(parsedData['data']);
        return data;
      } else {
        print('=== SALES CREATION ERROR ===');
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

  Future<SalesTransactionModel?> updateSale({
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
    required num serviceCharge,
    required String? taxType,
    String? note,
    File? image,
    bool? isSplitPayment,
    Map<int, double>? splitPaymentAmounts,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales/$id');
    CustomHttpClient customHttpClient =
        CustomHttpClient(client: http.Client(), ref: ref, context: context);
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
      ..fields['service_charge'] = serviceCharge.toString()
      ..fields['tax_type'] = taxType ?? ''
      ..fields['total_tax_amount'] = products
          .fold(0.0, (sum, product) => sum + (product.taxAmount ?? 0))
          .toString()
      ..fields['note'] = note ?? ''
      ..fields['rounding_option'] = roundedOption
      ..fields['rounding_amount'] = roundingAmount.toStringAsFixed(2)
      ..fields['actual_total_amount'] = unRoundedTotalAmount.toString();

    // Convert the list of products to a JSON string
    String productJson =
        jsonEncode(products.map((product) => product.toJson()).toList());
    request.fields['products'] = productJson;

    if (vatId != null) {
      request.fields.addAll({'vat_id': vatId.toString()});
    }

    // Split payment data
    if (isSplitPayment == true &&
        splitPaymentAmounts != null &&
        splitPaymentAmounts.isNotEmpty) {
      // Convert Map<int, double> to Map<String, dynamic> for JSON encoding
      final Map<String, dynamic> splitPaymentJson = {};
      splitPaymentAmounts.forEach((key, value) {
        splitPaymentJson[key.toString()] = value;
      });

      request.fields.addAll({
        'is_split_payment': 'true',
        'split_payment_amounts': jsonEncode(splitPaymentJson),
      });

      // Detailed Request Body Logging for Split Payment Update
      print('\n🔵 ===== SPLIT PAYMENT UPDATE REQUEST BODY =====');
      print('📤 Request URL: $uri');
      print('📤 Request Method: PUT');
      print('📤 Sale ID: $id');
      print('📤 is_split_payment: true');
      print('📤 split_payment_amounts (JSON): ${jsonEncode(splitPaymentJson)}');
      print('📤 Split Payment Details:');
      splitPaymentAmounts.forEach((key, value) {
        print('   → Payment Type ID: $key, Amount: ₹$value');
      });
      print(
          '📤 Total Split Amount: ₹${splitPaymentAmounts.values.fold(0.0, (sum, amount) => sum + amount)}');
      print('📤 Total Amount (Expected): ₹$totalAmount');
      print('🔵 ===========================================\n');
    }

    // Add image if it exists
    if (image != null) {
      var imageFile = await http.MultipartFile.fromPath('image', image.path);
      request.files.add(imageFile);
    }

    try {
      var response = await customHttpClient.uploadFile(
          url: uri,
          fields: request.fields,
          fileFieldName: 'image',
          file: image);

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        final parsedData = jsonDecode(responseData.body);

        print('=== SALES UPDATE API RESPONSE ===');
        print('Sales Update Status: ${response.statusCode}');
        print('Sales Update Response: ${responseData.body}');

        // Split Payment Response Logging
        if (isSplitPayment == true && splitPaymentAmounts != null) {
          print('\n🔵 ===== SPLIT PAYMENT UPDATE RESPONSE LOGS =====');
          print('📤 Split Payment Sent:');
          splitPaymentAmounts.forEach((key, value) {
            print('   Payment Type ID: $key, Amount: ₹$value');
          });
          print('📥 Split Payment Response:');
          if (parsedData['data'] != null) {
            final saleData = parsedData['data'];
            print('   Sale ID: ${saleData['id']}');
            print('   is_split_payment: ${saleData['is_split_payment']}');
            print(
                '   split_payment_amounts: ${saleData['split_payment_amounts']}');

            if (saleData['split_payment_amounts'] != null) {
              try {
                final responseSplitPayments = saleData['split_payment_amounts'];
                if (responseSplitPayments is String) {
                  final decoded = jsonDecode(responseSplitPayments);
                  print('   Decoded Split Payments:');
                  if (decoded is Map) {
                    decoded.forEach((key, value) {
                      print('     Payment Type $key: ₹$value');
                    });
                  }
                } else if (responseSplitPayments is Map) {
                  print('   Split Payments:');
                  responseSplitPayments.forEach((key, value) {
                    print('     Payment Type $key: ₹$value');
                  });
                }
              } catch (e) {
                print('   Error parsing split payment amounts: $e');
              }
            }
          }
          print('🔵 ===========================================\n');
        }

        // Print detailed response information
        print('=== SALES UPDATE RESPONSE DETAILS ===');
        print('Response Data: ${parsedData['data']}');

        SalesTransactionModel? updatedSale;

        // Print tax information from response
        if (parsedData['data'] != null) {
          var saleData = parsedData['data'];
          updatedSale = SalesTransactionModel.fromJson(saleData);
          print('Updated Sale ID: ${saleData['id']}');
          print('Updated Total Amount: ${saleData['totalAmount']}');
          print('Updated VAT Amount: ${saleData['vat_amount']}');
          print('Updated VAT Percent: ${saleData['vat_percent']}');
          print('Updated Tax Type: ${taxType ?? 'Not specified'}');
          print(
              'Updated Service Charge: ${saleData['service_charge'] ?? 'Not specified'}');
          print(
              'Updated Total Tax Amount: ${saleData['total_tax_amount'] ?? 'Not specified'}');

          // Print product-wise tax information if available
          if (saleData['details'] != null) {
            print('=== UPDATED PRODUCT TAX DETAILS ===');
            var details = saleData['details'] as List;
            for (int i = 0; i < details.length; i++) {
              var product = details[i];
              print('Updated Product $i:');
              print('  - Product ID: ${product['product_id']}');
              print('  - Price: ${product['price']}');
              print('  - Quantities: ${product['quantities']}');
              print(
                  '  - GST Rate: ${product['gst_rate_select'] ?? 'Not specified'}');
              print(
                  '  - Tax Amount: ${product['tax_amount'] ?? 'Not specified'}');
              print(
                  '  - GST Amount: ${product['gst_amount'] ?? 'Not specified'}');
              print(
                  '  - Product Tax Amount: ${product['product_tax_amount'] ?? 'Not specified'}');
            }
          }
        }

        await EasyLoading.showSuccess('Sale updated!');
        try {
          ref.invalidate(productProvider);
          ref.invalidate(partiesProvider);
          ref.invalidate(salesTransactionProvider);
          ref.invalidate(businessInfoProvider);
          ref.invalidate(getExpireDateProvider(ref));
        } catch (e) {
          print('Error refreshing providers after sale update: $e');
          // Continue execution even if provider refresh fails
        }
        return updatedSale;
      } else {
        var responseData = await http.Response.fromStream(response);
        final parsedData = jsonDecode(responseData.body);
        print('=== SALES UPDATE ERROR ===');
        print('Sales update failed with status: ${response.statusCode}');
        print('Error message: ${parsedData['message'] ?? 'Unknown error'}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Sales creation failed: ${parsedData['message']}')));
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss().then((value) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      });
      return null;
    }
  }

  // Hold a sale - POST v1/sales/hold
  Future<Map<String, dynamic>?> holdSale({
    required WidgetRef ref,
    required BuildContext context,
    required num? partyId,
    required String? customerPhone,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num totalAmount,
    required num dueAmount,
    required num vatAmount,
    required num vatPercent,
    required num? vatId,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartSaleProducts> products,
    required String discountType,
    required num shippingCharge,
    required num serviceCharge,
    required String? taxType,
    String? note,
    bool? isSplitPayment,
    Map<int, double>? splitPaymentAmounts,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales/hold');

    print('\n=== HOLD SALE API REQUEST ===');
    print('🔗 URL: $uri');
    print('📅 Date: $purchaseDate');
    print('👤 Customer ID: $partyId');
    print('💰 Total Amount: $totalAmount');
    print('📦 Products Count: ${products.length}');

    try {
      var request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        "Accept": 'application/json',
        'Authorization': await getAuthToken(),
        'Content-Type': 'multipart/form-data',
      });

      // Prepare request data
      final requestData = {
        'type': 'Hold', // Important: Mark as Hold
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
        'service_charge': serviceCharge.toString(),
        'tax_type': taxType ?? '',
        'total_tax_amount': products
            .fold(0.0, (sum, product) => sum + (product.taxAmount ?? 0))
            .toString(),
        'note': note ?? '',
        'products': jsonEncode(
          products.map((product) => product.toJson()).toList(),
        ),
      };

      if (vatId != null) {
        requestData['vat_id'] = vatId.toString();
      }

      // Add split payment data if applicable
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

        // Detailed Request Body Logging for Split Payment Hold
        print('\n🔵 ===== SPLIT PAYMENT HOLD REQUEST BODY =====');
        print('📤 Request URL: $uri');
        print('📤 Request Method: POST (Hold)');
        print('📤 is_split_payment: 1');
        print(
            '📤 split_payment_amounts (JSON): ${jsonEncode(splitPaymentJson)}');
        print('📤 Split Payment Details:');
        splitPaymentAmounts.forEach((key, value) {
          print('   → Payment Type ID: $key, Amount: ₹$value');
        });
        print(
            '📤 Total Split Amount: ₹${splitPaymentAmounts.values.fold(0.0, (sum, amount) => sum + amount)}');
        print('📤 Total Amount (Expected): ₹$totalAmount');
        print('🔵 ===========================================\n');
      }

      request.fields.addAll(requestData);

      print('📤 Request Data:');
      requestData.forEach((key, value) {
        if (key == 'split_payment_amounts') {
          print('   $key: ${value} (Split Payment JSON)');
          try {
            final decoded = jsonDecode(value);
            if (decoded is Map) {
              decoded.forEach((k, v) {
                print('     └─ Payment Type $k: ₹$v');
              });
            }
          } catch (e) {
            print('     └─ Error decoding: $e');
          }
        } else if (key != 'products') {
          // Don't print full products JSON
          print('   $key: $value');
        } else {
          print('   products: ${products.length} items');
        }
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('\n📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('\n✅ HOLD SALE SUCCESS!');
        print('📋 Response Data:');
        responseData.forEach((key, value) {
          print('   $key: $value');
        });

        // Split Payment Response Logging
        if (isSplitPayment == true && splitPaymentAmounts != null) {
          print('\n🔵 ===== SPLIT PAYMENT HOLD RESPONSE LOGS =====');
          print('📤 Split Payment Sent:');
          splitPaymentAmounts.forEach((key, value) {
            print('   Payment Type ID: $key, Amount: ₹$value');
          });
          print('📥 Split Payment in Hold Response:');
          if (responseData['data'] != null) {
            final holdData = responseData['data'];
            print('   Hold Sale ID: ${holdData['id']}');
            print('   is_split_payment: ${holdData['is_split_payment']}');
            print(
                '   split_payment_amounts: ${holdData['split_payment_amounts']}');

            if (holdData['split_payment_amounts'] != null) {
              try {
                final responseSplitPayments = holdData['split_payment_amounts'];
                if (responseSplitPayments is String) {
                  final decoded = jsonDecode(responseSplitPayments);
                  print('   Decoded Split Payments:');
                  if (decoded is Map) {
                    decoded.forEach((key, value) {
                      print('     Payment Type $key: ₹$value');
                    });
                  }
                } else if (responseSplitPayments is Map) {
                  print('   Split Payments:');
                  responseSplitPayments.forEach((key, value) {
                    print('     Payment Type $key: ₹$value');
                  });
                }
              } catch (e) {
                print('   Error parsing split payment amounts: $e');
              }
            }
          }
          print('🔵 ===========================================\n');
        }
        print('=== HOLD SALE API COMPLETE ===\n');

        EasyLoading.showSuccess('Sale held successfully!');

        return responseData;
      } else {
        print('\n❌ HOLD SALE FAILED!');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        print('=== HOLD SALE API FAILED ===\n');

        EasyLoading.showError('Failed to hold sale: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('\n💥 HOLD SALE ERROR!');
      print('Exception: $e');
      print('=== HOLD SALE API ERROR ===\n');

      EasyLoading.showError('Error holding sale: $e');
      return null;
    }
  }

  // Fetch held sales - GET v1/sales?held=true
  Future<List<SalesTransactionModel>> fetchHeldSales() async {
    final uri = Uri.parse('${APIConfig.url}/sales?held=true');

    print('\n=== FETCH HELD SALES API REQUEST ===');
    print('🔗 URL: $uri');

    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': await getAuthToken(),
      });

      print('\n📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

        print('\n✅ HELD SALES FETCH SUCCESS!');
        print('📊 Parsed Data Keys: ${parsedData.keys.toList()}');

        final salesList = parsedData['data'] as List<dynamic>;
        print('📦 Held Sales Count: ${salesList.length}');

        // Print each held sale
        for (int i = 0; i < salesList.length; i++) {
          print('\n🛒 Held Sale #${i + 1}:');
          final sale = salesList[i] as Map<String, dynamic>;
          print('   ID: ${sale['id']}');
          print('   Invoice: ${sale['invoice_number'] ?? 'N/A'}');
          print('   Customer: ${sale['party']?['name'] ?? 'N/A'}');
          print('   Total: ${sale['totalAmount'] ?? 'N/A'}');
          print('   Date: ${sale['saleDate'] ?? 'N/A'}');
          print('   Type: ${sale['type'] ?? 'N/A'}');
        }

        print('\n=== HELD SALES FETCH COMPLETE ===\n');

        return salesList
            .map((sale) => SalesTransactionModel.fromJson(sale))
            .toList();
      } else {
        print('\n❌ HELD SALES FETCH FAILED!');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        print('=== HELD SALES FETCH FAILED ===\n');

        throw Exception('Failed to fetch held sales: ${response.statusCode}');
      }
    } catch (e) {
      print('\n💥 HELD SALES FETCH ERROR!');
      print('Exception: $e');
      print('=== HELD SALES FETCH ERROR ===\n');

      throw Exception('Error fetching held sales: $e');
    }
  }

  // Delete a held sale
  Future<bool> deleteHeldSale({required int saleId}) async {
    final uri = Uri.parse('${APIConfig.url}/sales/$saleId');

    print('\n=== DELETE HELD SALE API REQUEST ===');
    print('🔗 URL: $uri');
    print('🗑️ Sale ID: $saleId');

    try {
      final response = await http.delete(uri, headers: {
        'Accept': 'application/json',
        'Authorization': await getAuthToken(),
      });

      print('\n📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('\n✅ HELD SALE DELETED!');
        print('=== DELETE HELD SALE COMPLETE ===\n');
        return true;
      } else {
        print('\n❌ DELETE HELD SALE FAILED!');
        print('=== DELETE HELD SALE FAILED ===\n');
        return false;
      }
    } catch (e) {
      print('\n💥 DELETE HELD SALE ERROR!');
      print('Exception: $e');
      print('=== DELETE HELD SALE ERROR ===\n');
      return false;
    }
  }
}

class CartSaleProducts {
  final int productId;
  final num? price;
  final num? lossProfit;
  final num? quantities;
  final int? stockId;
  final String? gstRateSelect;
  final double? taxAmount;

  CartSaleProducts({
    required this.productId,
    required this.price,
    required this.quantities,
    required this.lossProfit,
    this.stockId,
    this.gstRateSelect,
    this.taxAmount,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'product_id': productId,
      'price': price,
      'lossProfit': lossProfit,
      'quantities': quantities,
    };

    // Only include stock_id if it's not null
    if (stockId != null) {
      json['stock_id'] = stockId;
    }

    // Only include gst_rate_select if it's not null
    if (gstRateSelect != null) {
      json['gst_rate_select'] = gstRateSelect;
    }

    // Only include tax_amount if it's not null
    if (taxAmount != null) {
      json['tax_amount'] = taxAmount;
      json['gst_amount'] = taxAmount; // Alternative field name
      json['product_tax_amount'] = taxAmount; // Another alternative
    }

    return json;
  }
}
