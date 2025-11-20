import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../Model/combo_model.dart';

class ComboRepo {
  double _roundToTwo(num value) => double.parse(value.toStringAsFixed(2));

  double _calculateTaxAmount(ProductModel product) {
    final gstType = product.gstType?.toLowerCase().trim();
    if (gstType == 'non-taxable' ||
        gstType == 'non taxable' ||
        gstType == 'exempt') {
      return 0;
    }

    double taxAmount = (product.vatAmount ?? 0).toDouble();

    if (taxAmount == 0) {
      final rateStr = product.gstRateSelect?.toString().trim();
      if (rateStr != null &&
          rateStr.isNotEmpty &&
          rateStr.toLowerCase() != 'n/a' &&
          rateStr.toLowerCase() != 'null') {
        final rate = num.tryParse(rateStr);
        if (rate != null && rate > 0) {
          final basePrice = (product.productSalePrice ?? 0).toDouble();
          taxAmount = (basePrice * rate.toDouble()) / 100.0;
        }
      }
    }

    return _roundToTwo(taxAmount);
  }

  double _priceWithTax(ProductModel product) {
    final basePrice = (product.productSalePrice ?? 0).toDouble();
    final taxAmount = _calculateTaxAmount(product);
    final vatType = product.vatType?.toLowerCase().trim();

    if (vatType == 'inclusive') {
      return _roundToTwo(basePrice);
    }

    return _roundToTwo(basePrice + taxAmount);
  }

  // Helper: find the actual list of combo entries inside various payload shapes
  List<dynamic> _extractComboListFromPayload(dynamic payload) {
    if (payload == null) return <dynamic>[];

    // If payload is already a list, return it
    if (payload is List) return payload;

    if (payload is Map) {
      // Common API shape: { success: true, data: { current_page:..., data: [ ... ] } }
      final dataNode = payload['data'] ?? payload['records'] ?? payload['combos'];
      if (dataNode is List) return dataNode;

      if (dataNode is Map) {
        // nested 'data' field
        if (dataNode['data'] is List) return dataNode['data'];
        // first List among values (e.g. keyed children)
        for (var v in dataNode.values) {
          if (v is List) return v;
        }
        // collection of map values (e.g. { "16": {...}, "15": {...} })
        final maps = dataNode.values.where((v) => v is Map).toList();
        if (maps.isNotEmpty) return maps;
      }

      // If top-level map contains the inner list directly under 'data' key as above didn't match,
      // search for the first List anywhere in payload values (handles many variants)
      for (var v in payload.values) {
        if (v is List) return v;
      }

      // If payload itself looks like a single combo object, wrap it
      if (payload.containsKey('id') ||
          payload.containsKey('combo_name') ||
          payload.containsKey('product_id')) {
        return [payload];
      }

      // As a last resort, use map values (will filter later)
      return payload.values.toList();
    }

    // Other shapes: wrap single value
    return [payload];
  }

  // Replace the existing fetchAllCombos implementation with this defensive version
  Future<List<ComboModel>> fetchAllCombos() async {
    try {
      final uri = Uri.parse('${APIConfig.url}/combo-kits');

      print('=== COMBO LIST API CALL ===');
      print('Method: GET');
      print('URL: ${uri.toString()}');
      print('Timestamp: ${DateTime.now()}');

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': await getAuthToken(),
      });

      print('=== COMBO LIST API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final dynamic payload = jsonDecode(response.body);

      if (payload == null) return <ComboModel>[];

      final listCandidate = _extractComboListFromPayload(payload);

      // Map to ComboModel defensively
      final combos = <ComboModel>[];
      for (var entry in listCandidate) {
        if (entry == null) continue;
        try {
          if (entry is Map) {
            combos.add(ComboModel.fromJson(entry));
          } else if (entry is List) {
            // flatten nested lists of maps
            for (var sub in entry) {
              if (sub is Map) {
                combos.add(ComboModel.fromJson(sub));
              }
            }
          } else if (entry is num) {
            combos.add(ComboModel.fromJson({'id': entry}));
          } else if (entry is String) {
            // skip pagination URLs or parse numeric strings
            final parsed = num.tryParse(entry);
            if (parsed != null) {
              combos.add(ComboModel.fromJson({'id': parsed}));
            } else {
              print('Skipping non-parseable string entry in combos: $entry');
            }
          } else {
            print('Skipping unsupported combo entry type: ${entry.runtimeType}');
          }
        } catch (ex, stx) {
          print('Skipping invalid combo entry due to error: $ex\n$stx');
        }
      }

      return combos;
    } catch (e, st) {
      print('Error in fetchAllCombos: $e\n$st');
      rethrow;
    }
  }

  Future<ComboModel?> getComboById(num comboId) async {
    final uri = Uri.parse('${APIConfig.url}/combo-kits/$comboId');

    print('=== GET COMBO BY ID API CALL ===');
    print('Method: GET');
    print('URL: ${uri.toString()}');
    print('Combo ID: $comboId');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('=== GET COMBO BY ID RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      return ComboModel.fromJson(parsedData['data']);
    } else {
      throw Exception('Failed to load combo');
    }
  }

  Future<void> createCombo({
    required WidgetRef ref,
    required BuildContext context,
    required String comboName,
    required List<ProductModel> selectedProducts,
    required Map<String, int> productQuantities,
    required num subtotal,
    required String discountType,
    required num discountValue,
    required num finalPrice,
    required num comboQuantity, // renamed param
    File? image,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/combo-kits');

    print('=== CREATE COMBO API CALL ===');
    print('Method: POST');
    print('URL: ${uri.toString()}');
    print('Timestamp: ${DateTime.now()}');

    try {
      var request = http.MultipartRequest("POST", uri);
      CustomHttpClient customHttpClient =
          CustomHttpClient(client: http.Client(), ref: ref, context: context);

      request.headers.addAll({
        "Accept": 'application/json',
        'Authorization': await getAuthToken(),
      });

      // Basic fields - matching API format
      request.fields['combo name'] = comboName;
      request.fields['discount_type'] = discountType;
      request.fields['discountAmount'] = discountValue.toString();
      request.fields['subtotal'] = subtotal.toString();
      request.fields['combo_price'] = finalPrice.toString();
      request.fields['combo_quantity'] = comboQuantity.toString(); // send as combo_quantity

      // Products array - format: [{"product_id":14,"product_price":300,"quantity":1}]
      final productsJson = selectedProducts.map((product) {
        final productIdStr = product.id?.toString() ?? '';
        final quantityForProduct = productQuantities[productIdStr] ?? 1;
        final priceWithTax = _priceWithTax(product);
        return {
          'product_id': product.id?.toInt() ?? 0,
          'product_price': priceWithTax,
          'quantity': quantityForProduct,
        };
      }).toList();
      request.fields['products'] = jsonEncode(productsJson);

      // Add image if provided
      if (image != null) {
        request.files.add(http.MultipartFile.fromBytes(
            'combo_image', image.readAsBytesSync(),
            filename: image.path.split('/').last));
        print('Image attached: ${image.path.split('/').last}');
      }

      // Log request body
      print('=== CREATE COMBO REQUEST BODY ===');
      print('Form Fields:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });
      print('Total Fields: ${request.fields.length}');
      print('Files Count: ${request.files.length}');
      if (request.files.isNotEmpty) {
        for (var file in request.files) {
          print(
              '  File: ${file.field} - ${file.filename} (${file.length} bytes)');
        }
      }
      print('=== END REQUEST BODY ===');

      final response = await customHttpClient.uploadFile(
        url: uri,
        file: image,
        fileFieldName: 'combo_image',
        fields: request.fields,
      );

      final responseData = await response.stream.bytesToString();

      print('=== CREATE COMBO API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: $responseData');
      print('=== END RESPONSE ===');

      final parsedData = jsonDecode(responseData);
      print('Parsed Response: $parsedData'); // explicit parsed response log

      if (response.statusCode == 200 || response.statusCode == 201) {
        EasyLoading.showSuccess('Combo created successfully!');
        Navigator.pop(context);
        Navigator.pop(context); // Pop twice to go back to combo list
      } else {
        EasyLoading.showError(
            parsedData['message'] ?? 'Failed to create combo');
      }
    } catch (e, stackTrace) {
      print('=== CREATE COMBO ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      EasyLoading.showError('Error creating combo: $e');
    }
  }

  Future<void> updateCombo({
    required WidgetRef ref,
    required BuildContext context,
    required num comboId,
    required String comboName,
    required List<ProductModel> selectedProducts,
    required Map<String, int> productQuantities,
    required num subtotal,
    required String discountType,
    required num discountValue,
    required num finalPrice,
    required num comboQuantity, // renamed param
    File? image,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/combo-kits/$comboId');

    print('=== UPDATE COMBO API CALL ===');
    print('Method: PUT (via POST with _method)');
    print('URL: ${uri.toString()}');
    print('Combo ID: $comboId');
    print('Timestamp: ${DateTime.now()}');

    try {
      var request = http.MultipartRequest("POST", uri);
      CustomHttpClient customHttpClient =
          CustomHttpClient(client: http.Client(), ref: ref, context: context);

      request.headers.addAll({
        "Accept": 'application/json',
        'Authorization': await getAuthToken(),
      });

      request.fields['_method'] = 'PUT';

      // Basic fields - matching API format
      request.fields['combo name'] = comboName;
      request.fields['discount_type'] = discountType;
      request.fields['discountAmount'] = discountValue.toString();
      request.fields['subtotal'] = subtotal.toString();
      request.fields['combo_price'] = finalPrice.toString();
      request.fields['combo_quantity'] = comboQuantity.toString(); // send as combo_quantity

      // Products array - format: [{"product_id":14,"product_price":300,"quantity":1}]
      final productsJson = selectedProducts.map((product) {
        final productIdStr = product.id?.toString() ?? '';
        final quantityForProduct = productQuantities[productIdStr] ?? 1;
        final priceWithTax = _priceWithTax(product);
        return {
          'product_id': product.id?.toInt() ?? 0,
          'product_price': priceWithTax,
          'quantity': quantityForProduct,
        };
      }).toList();
      request.fields['products'] = jsonEncode(productsJson);

      // Add image if provided
      if (image != null) {
        request.files.add(http.MultipartFile.fromBytes(
            'combo_image', image.readAsBytesSync(),
            filename: image.path.split('/').last));
        print('Image attached: ${image.path.split('/').last}');
      }

      // Log request body
      print('=== UPDATE COMBO REQUEST BODY ===');
      print('Form Fields:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });
      print('Total Fields: ${request.fields.length}');
      print('Files Count: ${request.files.length}');
      if (request.files.isNotEmpty) {
        for (var file in request.files) {
          print(
              '  File: ${file.field} - ${file.filename} (${file.length} bytes)');
        }
      }
      print('=== END REQUEST BODY ===');

      final response = await customHttpClient.uploadFile(
        url: uri,
        file: image,
        fileFieldName: 'combo_image',
        fields: request.fields,
      );

      final responseData = await response.stream.bytesToString();

      print('=== UPDATE COMBO API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: $responseData');
      print('=== END RESPONSE ===');

      final parsedData = jsonDecode(responseData);
      print('Parsed Response: $parsedData'); // explicit parsed response log

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Combo updated successfully!');
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        EasyLoading.showError(
            parsedData['message'] ?? 'Failed to update combo');
      }
    } catch (e, stackTrace) {
      print('=== UPDATE COMBO ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      EasyLoading.showError('Error updating combo: $e');
    }
  }

  Future<void> deleteCombo({
    required WidgetRef ref,
    required BuildContext context,
    required num comboId,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/combo-kits/$comboId');

    print('=== DELETE COMBO API CALL ===');
    print('Method: DELETE');
    print('URL: ${uri.toString()}');
    print('Combo ID: $comboId');
    print('Timestamp: ${DateTime.now()}');

    try {
      final response = await http.delete(uri, headers: {
        'Accept': 'application/json',
        'Authorization': await getAuthToken(),
      });

      print('=== DELETE COMBO API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== END RESPONSE ===');

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Combo deleted successfully!');
      } else {
        final parsedData = jsonDecode(response.body);
        EasyLoading.showError(
            parsedData['message'] ?? 'Failed to delete combo');
      }
    } catch (e, stackTrace) {
      print('=== DELETE COMBO ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      EasyLoading.showError('Error deleting combo: $e');
    }
  }

  Future<void> updateComboStatus({
    required num comboId,
    required num productId,
    required String status, // 'active' or 'inactive'
    num? comboProductId, // The ID of the combo_product relationship
  }) async {
    final uri = Uri.parse('${APIConfig.url}/combo-kits/$comboId/status');

    print('=== UPDATE COMBO STATUS API CALL ===');
    print('Method: POST');
    print('URL: ${uri.toString()}');
    print('Combo ID: $comboId');
    print('Product ID: $productId');
    if (comboProductId != null) {
      print('Combo Product ID: $comboProductId');
    }
    print('Status: $status');
    print('Timestamp: ${DateTime.now()}');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': await getAuthToken(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'status': status,
        }),
      );

      print('=== UPDATE COMBO STATUS API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Combo ID: $comboId');
      print('Product ID: $productId');
      if (comboProductId != null) {
        print('Combo Product ID: $comboProductId');
      }
      print('=== END RESPONSE ===');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsedData = jsonDecode(response.body);
        print('Success: ${parsedData.toString()}');
      } else {
        final parsedData = jsonDecode(response.body);
        print('Error: ${parsedData.toString()}');
        throw Exception(
            parsedData['message'] ?? 'Failed to update combo status');
      }
    } catch (e, stackTrace) {
      print('=== UPDATE COMBO STATUS ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('Combo ID: $comboId');
      print('Product ID: $productId');
      if (comboProductId != null) {
        print('Combo Product ID: $comboProductId');
      }
      throw Exception('Error updating combo status: $e');
    }
  }

  Future<void> updateComboKitStatus({
    required num productId, // Outer product id (not combo_kit id)
    required String status, // 'active' or 'inactive'
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/combo-kits/$productId/status');

    print('=== UPDATE COMBO KIT STATUS API CALL ===');
    print('Method: PUT');
    print('URL: ${uri.toString()}');
    print('Product ID: $productId');
    print('Status: $status');
    print('Timestamp: ${DateTime.now()}');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': await getAuthToken(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      print('=== UPDATE COMBO KIT STATUS API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== END RESPONSE ===');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsedData = jsonDecode(response.body);
        print('Success: ${parsedData.toString()}');
        EasyLoading.showSuccess('Status updated successfully!');
      } else {
        final parsedData = jsonDecode(response.body);
        print('Error: ${parsedData.toString()}');
        EasyLoading.showError(
            parsedData['message'] ?? 'Failed to update combo status');
        throw Exception(
            parsedData['message'] ?? 'Failed to update combo status');
      }
    } catch (e, stackTrace) {
      print('=== UPDATE COMBO KIT STATUS ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      EasyLoading.showError('Error updating combo status: $e');
      throw Exception('Error updating combo status: $e');
    }
  }
}