//ignore_for_file: file_names, unused_element, unused_local_variable
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/product_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../Model/product_model.dart';

class ProductRepo {
  Map<String, String> _buildVariantFields(List<Map<String, dynamic>> variants) {
    final Map<String, String> fields = {};
    for (var i = 0; i < variants.length; i++) {
      final index = i + 1;
      final variant = variants[i];
      variant.forEach((key, value) {
        if (value == null) return;
        final stringValue = value.toString().trim();
        if (stringValue.isEmpty) return;
        fields['variants[$index][$key]'] = stringValue;
      });
    }
    return fields;
  }

  Future<List<ProductModel>> fetchAllProducts() async {
    final uri = Uri.parse('${APIConfig.url}/products');

    // Print API URL and request details
    print('=== PRODUCT LIST API CALL ===');
    print('API URL: ${uri.toString()}');
    print('HTTP Method: GET');
    print('Timestamp: ${DateTime.now()}');
    print('Base URL: ${APIConfig.url}');
    print('Full Endpoint: /products');
    print(
        'Purpose: Fetching products with tax information (VAT Type, VAT Amount, GST Rate, GST Amount from API)');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      // Debug: Print the actual API response to see if stock_id exists
      print('=== PRODUCTS API RESPONSE DEBUG ===');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final partyList = parsedData['data'] as List<dynamic>;

      // Print total products count
      print('=== PRODUCT LIST SUMMARY ===');
      print('Total Products Found: ${partyList.length}');
      print('API Response Status: ${response.statusCode}');
      print('API URL Used: ${uri.toString()}');

      // Debug: Print first product to see all available fields
      if (partyList.isNotEmpty) {
        print('=== FIRST PRODUCT DATA ===');
        print('Product 0: ${partyList[0]}');
        print('Available fields: ${partyList[0].keys.toList()}');
        print('Has stock_id: ${partyList[0].containsKey('stock_id')}');
        if (partyList[0].containsKey('stock_id')) {
          print('stock_id value: ${partyList[0]['stock_id']}');
        }

        // Print detailed product information
        print('=== DETAILED PRODUCT INFORMATION ===');
        var firstProduct = partyList[0];
        print('Product ID: ${firstProduct['id'] ?? 'N/A'}');
        print('Product Name: ${firstProduct['productName'] ?? 'N/A'}');
        print('Product Code: ${firstProduct['productCode'] ?? 'N/A'}');
        print('Product Stock: ${firstProduct['productStock'] ?? 'N/A'}');
        print(
            'Product Sale Price: ${firstProduct['productSalePrice'] ?? 'N/A'}');
        print(
            'Product Purchase Price: ${firstProduct['productPurchasePrice'] ?? 'N/A'}');
        print(
            'Product Whole Sale Price: ${firstProduct['productWholeSalePrice'] ?? 'N/A'}');
        print(
            'Product Dealer Price: ${firstProduct['productDealerPrice'] ?? 'N/A'}');
        print('Category ID: ${firstProduct['category_id'] ?? 'N/A'}');
        print('Brand ID: ${firstProduct['brand_id'] ?? 'N/A'}');
        print('Unit ID: ${firstProduct['unit_id'] ?? 'N/A'}');
        print('VAT ID: ${firstProduct['vat_id'] ?? 'N/A'}');
        print('Business ID: ${firstProduct['business_id'] ?? 'N/A'}');
        print('Product Picture: ${firstProduct['productPicture'] ?? 'N/A'}');
        print('Size: ${firstProduct['size'] ?? 'N/A'}');
        print('Color: ${firstProduct['color'] ?? 'N/A'}');
        print('Weight: ${firstProduct['weight'] ?? 'N/A'}');
        print('Capacity: ${firstProduct['capacity'] ?? 'N/A'}');
        print('Type: ${firstProduct['type'] ?? 'N/A'}');
        print(
            'Product Manufacturer: ${firstProduct['productManufacturer'] ?? 'N/A'}');
        print('Product Discount: ${firstProduct['productDiscount'] ?? 'N/A'}');
        print('VAT Type: ${firstProduct['vat_type'] ?? 'N/A'}');
        print('VAT Amount: ${firstProduct['vat_amount'] ?? 'N/A'}');
        print('GST Rate Select: ${firstProduct['gst_rate_select'] ?? 'N/A'}');
        print('GST Type: ${firstProduct['gst_type'] ?? 'N/A'}');
        print('Profit Margin: ${firstProduct['profit_percent'] ?? 'N/A'}');
        print('Alert Quantity: ${firstProduct['alert_qty'] ?? 'N/A'}');
        print('Expire Date: ${firstProduct['expire_date'] ?? 'N/A'}');
        print('Created At: ${firstProduct['created_at'] ?? 'N/A'}');
        print('Updated At: ${firstProduct['updated_at'] ?? 'N/A'}');

        // Print tax information prominently
        print('=== TAX INFORMATION ===');
        print('VAT Type: ${firstProduct['vat_type'] ?? 'N/A'}');
        print('VAT Amount: ${firstProduct['vat_amount'] ?? 'N/A'}');
        print('GST Rate Select: ${firstProduct['gst_rate_select'] ?? 'N/A'}');
        print('GST Type: ${firstProduct['gst_type'] ?? 'N/A'}');
        print('VAT ID: ${firstProduct['vat_id'] ?? 'N/A'}');

        // Print GST amount from API (vat_amount field contains GST amount)
        num? apiGstAmount = firstProduct['vat_amount'];
        String? gstRate = firstProduct['gst_rate_select'];
        num? salePrice = firstProduct['productSalePrice'];

        print('GST Amount from API: ${apiGstAmount ?? 'N/A'}');
        print('GST Rate from API: ${gstRate ?? 'N/A'}');
        print('Sale Price: ${salePrice ?? 'N/A'}');

        // Also show calculated amount for comparison
        if (salePrice != null && gstRate != null && gstRate != 'N/A') {
          try {
            num gstRateNum = num.parse(gstRate.toString());
            num calculatedGstAmount = (salePrice * gstRateNum) / 100;
            print(
                'Calculated GST Amount: ${calculatedGstAmount.toStringAsFixed(2)}');
            print(
                'API vs Calculated: ${apiGstAmount ?? 'N/A'} vs ${calculatedGstAmount.toStringAsFixed(2)}');
          } catch (e) {
            print('GST Calculation Error: $e');
          }
        }
        print('========================');

        // Print related objects if available
        if (firstProduct['category'] != null) {
          print('Category Details: ${firstProduct['category']}');
        }
        if (firstProduct['brand'] != null) {
          print('Brand Details: ${firstProduct['brand']}');
        }
        if (firstProduct['unit'] != null) {
          print('Unit Details: ${firstProduct['unit']}');
        }
      }

      // Print all products summary with tax information
      print('=== ALL PRODUCTS SUMMARY WITH TAX INFO ===');
      for (int i = 0; i < partyList.length; i++) {
        var product = partyList[i];

        // Use GST amount from API (vat_amount field)
        String gstAmountStr = 'N/A';
        num? apiGstAmount = product['vat_amount'];
        if (apiGstAmount != null) {
          gstAmountStr = apiGstAmount.toStringAsFixed(2);
        }

        print(
            'Product $i: ID=${product['id']}, Name=${product['productName']}, Code=${product['productCode']}, Stock=${product['productStock']}, Sale Price=${product['productSalePrice']}, VAT Type=${product['vat_type'] ?? 'N/A'}, VAT Amount=${product['vat_amount'] ?? 'N/A'}, GST Rate=${product['gst_rate_select'] ?? 'N/A'}, GST Amount=${gstAmountStr}');
      }

      // Print GST summary statistics using API data
      print('=== GST SUMMARY STATISTICS ===');
      int productsWithGST = 0;
      int productsWithoutGST = 0;
      num totalGSTAmount = 0;
      Map<String, int> gstRateCount = {};

      for (var product in partyList) {
        String? gstRate = product['gst_rate_select'];
        num? apiGstAmount = product['vat_amount'];

        if (gstRate != null && gstRate != 'N/A' && gstRate != '0') {
          productsWithGST++;
          if (apiGstAmount != null) {
            totalGSTAmount += apiGstAmount;
          }

          try {
            num gstRateNum = num.parse(gstRate.toString());
            String rateKey = '${gstRateNum}%';
            gstRateCount[rateKey] = (gstRateCount[rateKey] ?? 0) + 1;
          } catch (e) {
            // Skip invalid GST rates
          }
        } else {
          productsWithoutGST++;
        }
      }

      print('Total Products: ${partyList.length}');
      print('Products with GST: $productsWithGST');
      print('Products without GST: $productsWithoutGST');
      print(
          'Total GST Amount (if all products sold): ${totalGSTAmount.toStringAsFixed(2)}');
      print('GST Rate Distribution:');
      gstRateCount.forEach((rate, count) {
        print('  $rate: $count products');
      });
      print('===============================');

      final allProducts =
          partyList.map((category) => ProductModel.fromJson(category)).toList();

      // Filter out inactive combos from the product list
      final filteredProducts = allProducts.where((product) {
        // If it's a combo (product_type == 'combo'), check if it's active
        if (product.productType?.toLowerCase() == 'combo') {
          final status = product.productStatus?.toLowerCase().trim();
          // Only include active combos
          return status == 'active';
        }
        // Include all non-combo products
        return true;
      }).toList();

      print('=== PRODUCT FILTERING ===');
      print('Total products: ${allProducts.length}');
      print(
          'Combos found: ${allProducts.where((p) => p.productType?.toLowerCase() == 'combo').length}');
      print(
          'Inactive combos filtered: ${allProducts.where((p) => p.productType?.toLowerCase() == 'combo' && p.productStatus?.toLowerCase().trim() != 'active').length}');
      print('Products after filtering: ${filteredProducts.length}');

      return filteredProducts;
      // Parse into Party objects
    } else {
      print('=== API ERROR ===');
      print('Failed to fetch products. Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('API URL: ${uri.toString()}');
      throw Exception('Failed to fetch Products');
    }
  }

  Future<void> addProduct({
    required WidgetRef ref,
    required BuildContext context,
    required String productName,
    String? categoryId,
    required String productCode,
    required String productStock,
    required String productSalePrice,
    required String productPurchasePrice,
    String? exclusivePrice,
    String? inclusivePrice,
    File? image,
    String? size,
    String? color,
    String? weight,
    String? capacity,
    String? type,
    String? brandId,
    String? unitId,
    String? productWholeSalePrice,
    String? productDealerPrice,
    String? productManufacturer,
    String? productDiscount,
    String? vatId,
    String? vatType,
    String? vatAmount,
    String? vatRate,
    String? gstType,
    String? gstRate,
    String? cgstRate,
    String? sgstRate,
    String? igstRate,
    String? profitMargin,
    String? lowStock,
    String? expDate,
    String? productType,
    List<Map<String, dynamic>>? variants,
    String? hsnCode,
  }) async {
    print('=== ADD PRODUCT API CALL START ===');
    print('API URL: ${APIConfig.url}/products');
    print('HTTP Method: POST');
    print('Content-Type: multipart/form-data');
    print('Timestamp: ${DateTime.now()}');

    final uri = Uri.parse('${APIConfig.url}/products');
    final authToken = await getAuthToken();
    print('Authorization Token: $authToken');

    print('=== PRODUCT DATA TO BE SENT ===');
    print('Product Name: $productName');
    print('Category ID: $categoryId');
    print('Product Code: $productCode');
    print('Product Stock: $productStock');
    print('Product Sale Price: $productSalePrice');
    print('Product Purchase Price: $productPurchasePrice');
    print('Size: $size');
    print('Color: $color');
    print('Weight: $weight');
    print('Capacity: $capacity');
    print('Type: $type');
    print('Brand ID: $brandId');
    print('Unit ID: $unitId');
    print('Product Whole Sale Price: $productWholeSalePrice');
    print('Product Dealer Price: $productDealerPrice');
    print('Product Manufacturer: $productManufacturer');
    print('Product Discount: $productDiscount');
    print('VAT ID: $vatId');
    print('VAT Type: $vatType');
    print('VAT Amount: $vatAmount');
    print('GST Rate (gst_rate): $gstRate');
    print('CGST Rate: $cgstRate');
    print('SGST Rate: $sgstRate');
    print('IGST Rate: $igstRate');
    print('Profit Margin: $profitMargin');
    print('Low Stock Alert: $lowStock');
    print('Expiry Date: $expDate');
    print('Product Type: $productType');
    print('HSN Code: $hsnCode');
    print('Variants Count: ${variants?.length ?? 0}');
    if (variants != null && variants.isNotEmpty) {
      print('Variants Payload: ${jsonEncode(variants)}');
    }
    print('Image File: ${image?.path ?? 'No image'}');

    CustomHttpClient customHttpClient =
        CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = authToken;

    print('=== REQUEST HEADERS ===');
    print('Accept: application/json');
    print('Authorization: $authToken');
    print('Content-Type: multipart/form-data');

    request.fields.addAll({
      "productName": productName,
      "productCode": productCode,
      "productStock": productStock,
      "productSalePrice": productSalePrice,
      "productPurchasePrice": productPurchasePrice,
    });
    if (categoryId != null && categoryId.isNotEmpty) {
      request.fields['category_id'] = categoryId;
    }
    if (size != null) request.fields['size'] = size;
    if (color != null) request.fields['color'] = color;
    if (weight != null) request.fields['weight'] = weight;
    if (capacity != null) request.fields['capacity'] = capacity;
    if (type != null) request.fields['type'] = type;
    if (brandId != null) request.fields['brand_id'] = brandId.toString();
    if (unitId != null) request.fields['unit_id'] = unitId;
    if (vatId != null) request.fields['vat_id'] = vatId;
    // Send vat_type in lowercase as the API expects
    if (vatType != null) request.fields['vat_type'] = vatType.toLowerCase();
    // gst_rate_select should be the GST rate (0, 5, 12, 18, 28, etc.)
    if (vatRate != null) request.fields['gst_rate_select'] = vatRate;
    // gst_type should be Taxable or Non-Taxable
    if (gstType != null) request.fields['gst_type'] = gstType;
    print('🔵 [ADD PRODUCT] GST Rate Select Value: $vatRate');
    print('🔵 [ADD PRODUCT] GST Type Value: $gstType');
    if (gstRate != null) request.fields['gst_rate'] = gstRate;
    if (cgstRate != null) request.fields['cgst_rate'] = cgstRate;
    if (sgstRate != null) request.fields['sgst_rate'] = sgstRate;
    if (igstRate != null) request.fields['igst_rate'] = igstRate;
    if (productType != null) request.fields['product_type'] = productType;
    if (hsnCode != null) request.fields['hsn_code'] = hsnCode;
    if (variants != null && variants.isNotEmpty) {
      final variantFields = _buildVariantFields(variants);
      request.fields.addAll(variantFields);
      request.fields['variants_json'] = jsonEncode(variants);
      request.fields['variant_count'] = variants.length.toString();
    }
    if (vatAmount != null) request.fields['vat_amount'] = vatAmount;
    if (exclusivePrice != null)
      request.fields['exclusive_price'] = exclusivePrice;
    if (inclusivePrice != null)
      request.fields['inclusive_price'] = inclusivePrice;
    if (profitMargin != null) request.fields['profit_percent'] = profitMargin;
    if (productWholeSalePrice != null)
      request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null)
      request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null)
      request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null)
      request.fields['productDiscount'] = productDiscount;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
          'productPicture', image.readAsBytesSync(),
          filename: image.path));
      print('Image file attached: ${image.path}');
    }
    if (lowStock != null) request.fields['alert_qty'] = lowStock;
    if (expDate != null) request.fields['expire_date'] = expDate;

    print('=== REQUEST BODY (Form Fields) ===');
    print(
        '🔵 gst_rate_select in request: ${request.fields['gst_rate_select']}');
    print('Total Fields Count: ${request.fields.length}');
    print('\n📤 ==========================================');
    print('📤 COMPLETE REQUEST BODY (ADD PRODUCT)');
    print('📤 ==========================================');
    request.fields.forEach((key, value) {
      print('📤 $key: $value');
    });
    print('📤 ==========================================');
    print('📤 Request Body as JSON: ${jsonEncode(request.fields)}');
    print('📤 ==========================================\n');

    if (request.files.isNotEmpty) {
      print('=== FILE ATTACHMENTS ===');
      for (var file in request.files) {
        print('Field Name: ${file.field}');
        print('File Name: ${file.filename}');
        print('File Size: ${file.length} bytes');
      }
    }

    print('=== SENDING REQUEST ===');
    // final response = await request.send();
    final response = await customHttpClient.uploadFile(
        url: uri,
        file: image,
        fileFieldName: 'productPicture',
        fields: request.fields);
    final responseData = await response.stream.bytesToString();

    print('\n📥 ==========================================');
    print('API RESPONSE RECEIVED (ADD PRODUCT)');
    print('📥 ==========================================');
    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Headers: ${response.headers}');
    print('📥 Response Body Length: ${responseData.length} characters');
    print('COMPLETE RESPONSE BODY:');
    print('📥 ==========================================');
    print('📥 $responseData');
    print('📥 ==========================================\n');

    final parsedData = jsonDecode(responseData);
    print('📥 PARSED RESPONSE DATA:');
    print('📥 ==========================================');
    print('📥 $parsedData');
    print('📥 ==========================================\n');

    // Print specific response fields
    print('📥 RESPONSE FIELD BREAKDOWN:');
    print('📥 ==========================================');
    print('📥 Status: ${parsedData['status'] ?? 'N/A'}');
    print('📥 Message: ${parsedData['message'] ?? 'N/A'}');
    print('📥 Errors: ${parsedData['errors'] ?? 'N/A'}');
    if (parsedData['data'] != null) {
      print('📥 Data Object:');
      print('📥   ${parsedData['data']}');
    } else {
      print('📥 Data: N/A');
    }
    print('📥 ==========================================');

    if (parsedData['data'] != null) {
      print('=== PRODUCT DATA IN RESPONSE ===');
      var productData = parsedData['data'];
      print('Product ID: ${productData['id'] ?? 'N/A'}');
      print('Product Name: ${productData['productName'] ?? 'N/A'}');
      print('Product Code: ${productData['productCode'] ?? 'N/A'}');
      print('Product Stock: ${productData['productStock'] ?? 'N/A'}');
      print('Product Sale Price: ${productData['productSalePrice'] ?? 'N/A'}');
      print(
          'Product Purchase Price: ${productData['productPurchasePrice'] ?? 'N/A'}');
      print('Category ID: ${productData['category_id'] ?? 'N/A'}');
      print('Brand ID: ${productData['brand_id'] ?? 'N/A'}');
      print('Unit ID: ${productData['unit_id'] ?? 'N/A'}');
      print('Created At: ${productData['created_at'] ?? 'N/A'}');
      print('Updated At: ${productData['updated_at'] ?? 'N/A'}');
    }

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      print('\n✅ ==========================================');
      print('✅ SUCCESS - PRODUCT ADDED!');
      print('✅ ==========================================');
      print('✅ Status Code: ${response.statusCode}');
      print(
          '✅ Message: ${parsedData['message'] ?? 'Product created successfully'}');
      print('✅ Created Product ID: ${parsedData['data']?['id'] ?? 'N/A'}');
      print('✅ Product Name: ${parsedData['data']?['productName'] ?? 'N/A'}');
      print('✅ Product Code: ${parsedData['data']?['productCode'] ?? 'N/A'}');
      print('✅ Stock: ${parsedData['data']?['productStock'] ?? 'N/A'}');
      print(
          '✅ Sale Price: ${parsedData['data']?['productSalePrice'] ?? 'N/A'}');
      print(
          '✅ Purchase Price: ${parsedData['data']?['productPurchasePrice'] ?? 'N/A'}');
      print(
          '✅ 🔵 GST Rate: ${parsedData['data']?['gst_rate_select'] ?? 'N/A'}');
      print('✅ ==========================================');
      print('✅ PRODUCT SUCCESSFULLY SAVED TO SERVER!');
      print('✅ ==========================================\n');

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added successful!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      print('\n❌ ==========================================');
      print('❌ ERROR - PRODUCT CREATION FAILED!');
      print('❌ ==========================================');
      print('❌ Status Code: ${response.statusCode}');
      print('Error Status: ${response.statusCode}');
      print('Error Message: ${parsedData['message'] ?? 'Unknown error'}');
      print('Error Details: ${parsedData['errors'] ?? 'No error details'}');
      print('Full Error Response: $parsedData');

      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Product creation failed: ${parsedData['message']}')));
    }

    print('=== ADD PRODUCT API CALL END ===');
  }

  Future<bool> addForBulkUpload({
    required String productName,
    required String categoryId,
    required String productCode,
    required String productStock,
    required String productSalePrice,
    required String productPurchasePrice,
    File? image,
    String? size,
    String? color,
    String? weight,
    String? capacity,
    String? type,
    String? brandId,
    String? unitId,
    String? productWholeSalePrice,
    String? productDealerPrice,
    String? productManufacturer,
    String? productDiscount,
  }) async {
    print('=== BULK UPLOAD ADD PRODUCT API CALL START ===');
    print('API URL: ${APIConfig.url}/products');
    print('HTTP Method: POST');
    print('Content-Type: multipart/form-data');

    final uri = Uri.parse('${APIConfig.url}/products');
    final authToken = await getAuthToken();
    print('Authorization Token: $authToken');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = authToken;

    print('=== REQUEST HEADERS ===');
    print('Accept: application/json');
    print('Authorization: $authToken');
    print('Content-Type: multipart/form-data');

    request.fields.addAll({
      "productName": productName,
      "category_id": categoryId,
      "productCode": productCode,
      "productStock": productStock,
      "productSalePrice": productSalePrice,
      "productPurchasePrice": productPurchasePrice,
    });
    if (size != null) request.fields['size'] = size;
    if (color != null) request.fields['color'] = color;
    if (weight != null) request.fields['weight'] = weight;
    if (capacity != null) request.fields['capacity'] = capacity;
    if (type != null) request.fields['type'] = type;
    if (brandId != null) request.fields['brand_id'] = brandId.toString();
    if (unitId != null) request.fields['unit_id'] = unitId;
    if (productWholeSalePrice != null)
      request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null)
      request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null)
      request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null)
      request.fields['productDiscount'] = productDiscount;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
          'productPicture', image.readAsBytesSync(),
          filename: image.path));
      print('Image file attached: ${image.path}');
    }

    print('=== REQUEST BODY (Form Fields) ===');
    request.fields.forEach((key, value) {
      print('$key: $value');
    });

    if (request.files.isNotEmpty) {
      print('=== FILE ATTACHMENTS ===');
      for (var file in request.files) {
        print('File: ${file.filename}, Length: ${file.length}');
      }
    }

    print('=== SENDING REQUEST ===');
    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    print('=== RESPONSE RECEIVED ===');
    print('Response Status Code: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: $responseData');

    final parsedData = jsonDecode(responseData);
    print('=== PARSED RESPONSE DATA ===');
    print('Parsed Data: $parsedData');

    if (response.statusCode == 200) {
      print('=== SUCCESS ===');
      print('Bulk product added successfully!');
      print('Product ID: ${parsedData['data']?['id'] ?? 'N/A'}');
      print('Product Name: ${parsedData['data']?['productName'] ?? 'N/A'}');
      print('Product Code: ${parsedData['data']?['productCode'] ?? 'N/A'}');
      return true;
    } else {
      print('=== ERROR ===');
      print('Bulk product creation failed!');
      print('Error Status: ${response.statusCode}');
      print('Error Message: ${parsedData['message'] ?? 'Unknown error'}');
      print('Error Details: ${parsedData['errors'] ?? 'No error details'}');
    }

    print('=== BULK UPLOAD ADD PRODUCT API CALL END ===');
    return false;
  }

  Future<void> deleteProduct({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/products/$id';

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

  Future<void> updateProduct({
    required String productId,
    required WidgetRef ref,
    required BuildContext context,
    required String productName,
    required String productCode,
    String? categoryId,
    required String productSalePrice,
    required String productPurchasePrice,
    String? exclusivePrice,
    String? inclusivePrice,
    File? image,
    String? size,
    String? color,
    String? weight,
    String? capacity,
    String? type,
    String? brandId,
    String? unitId,
    String? productWholeSalePrice,
    String? productDealerPrice,
    String? productManufacturer,
    String? productDiscount,
    String? productStock,
    String? vatId,
    String? vatType,
    String? vatAmount,
    String? vatRate,
    String? gstType,
    String? gstRate,
    String? cgstRate,
    String? sgstRate,
    String? igstRate,
    String? profitMargin,
    String? lowStock,
    String? expDate,
    String? productType,
    List<Map<String, dynamic>>? variants,
    String? hsnCode,
  }) async {
    print('=== UPDATE PRODUCT API CALL START ===');
    print('Timestamp: ${DateTime.now()}');
    print('API URL: ${APIConfig.url}/products/$productId');
    print('HTTP Method: PUT (with POST fallback)');
    print('Content-Type: application/json (PUT) / multipart/form-data (POST)');

    // Print all input parameters first
    print('=== INPUT PARAMETERS ===');
    print('Product ID: $productId');
    print('Product Name: $productName');
    print('Product Code: $productCode');
    print('Category ID: $categoryId');
    print('Sale Price: $productSalePrice');
    print('Purchase Price: $productPurchasePrice');
    print('Stock Value: $productStock');
    print('Stock Value Type: ${productStock.runtimeType}');
    print('Stock Value Empty: ${productStock?.isEmpty}');
    print('Stock Value Null: ${productStock == null}');
    print('Stock Value Length: ${productStock?.length}');
    print('Stock Value Trimmed: "${productStock?.trim()}"');
    print('Brand ID: $brandId');
    print('Unit ID: $unitId');
    print('Size: $size');
    print('Color: $color');
    print('Weight: $weight');
    print('Capacity: $capacity');
    print('Type: $type');
    print('Whole Sale Price: $productWholeSalePrice');
    print('Dealer Price: $productDealerPrice');
    print('Manufacturer: $productManufacturer');
    print('Discount: $productDiscount');
    print('VAT ID: $vatId');
    print('VAT Type: $vatType');
    print('VAT Amount: $vatAmount');
    print('GST Rate (gst_rate): $gstRate');
    print('CGST Rate: $cgstRate');
    print('SGST Rate: $sgstRate');
    print('IGST Rate: $igstRate');
    print('Profit Margin: $profitMargin');
    print('Low Stock Alert: $lowStock');
    print('Expiry Date: $expDate');
    print('Product Type: $productType');
    print('HSN Code: $hsnCode');
    print('Variants Count: ${variants?.length ?? 0}');
    if (variants != null && variants.isNotEmpty) {
      print('Variants Payload: ${jsonEncode(variants)}');
    }
    print('Has Image: ${image != null}');
    if (image != null) {
      print('Image Path: ${image.path}');
      print('Image Size: ${image.lengthSync()} bytes');
    }

    final uri = Uri.parse('${APIConfig.url}/products/$productId');
    final authToken = await getAuthToken();
    print('Authorization Token: $authToken');

    CustomHttpClient customHttpClient =
        CustomHttpClient(client: http.Client(), context: context, ref: ref);

    // Try direct PUT request first
    try {
      print('=== ATTEMPTING PUT REQUEST ===');
      print('Trying direct PUT request...');

      // Process stock value for PUT request
      String processedStock = '0';
      if (productStock != null && productStock.isNotEmpty) {
        processedStock = productStock.trim();
        try {
          double.parse(processedStock);
        } catch (e) {
          print('Invalid stock value for PUT: $processedStock, using 0');
          processedStock = '0';
        }
      }
      print('PUT Request - Processed Stock: "$processedStock"');

      final requestBody = {
        'productName': productName,
        'productCode': productCode,
        'productSalePrice': productSalePrice,
        'productPurchasePrice': productPurchasePrice,
        'productStock': processedStock,
        if (categoryId != null) 'category_id': categoryId,
        if (brandId != null) 'brand_id': brandId,
        if (unitId != null) 'unit_id': unitId,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
        if (weight != null) 'weight': weight,
        if (capacity != null) 'capacity': capacity,
        if (type != null) 'type': type,
        if (productWholeSalePrice != null)
          'productWholeSalePrice': productWholeSalePrice,
        if (productDealerPrice != null)
          'productDealerPrice': productDealerPrice,
        if (productManufacturer != null)
          'productManufacturer': productManufacturer,
        if (productDiscount != null) 'productDiscount': productDiscount,
        if (vatId != null) 'vat_id': vatId,
        if (vatType != null) 'vat_type': vatType.toLowerCase(),
        if (vatRate != null) 'gst_rate_select': vatRate,
        if (gstType != null) 'gst_type': gstType,
        if (gstRate != null) 'gst_rate': gstRate,
        if (cgstRate != null) 'cgst_rate': cgstRate,
        if (sgstRate != null) 'sgst_rate': sgstRate,
        if (igstRate != null) 'igst_rate': igstRate,
        if (vatAmount != null) 'vat_amount': vatAmount,
        if (exclusivePrice != null) 'exclusive_price': exclusivePrice,
        if (inclusivePrice != null) 'inclusive_price': inclusivePrice,
        if (profitMargin != null) 'profit_percent': profitMargin,
        if (lowStock != null) 'alert_qty': lowStock,
        if (expDate != null) 'expire_date': expDate,
        if (productType != null) 'product_type': productType,
        if (hsnCode != null) 'hsn_code': hsnCode,
        if (variants != null && variants.isNotEmpty) 'variants': variants,
      };

      print('=== PUT REQUEST HEADERS ===');
      print('Accept: application/json');
      print('Authorization: $authToken');
      print('Content-Type: application/json');

      print('=== PUT REQUEST BODY ===');
      print('🔵 [UPDATE PRODUCT - PUT] GST Rate Select Value: $vatRate');
      print(
          '🔵 gst_rate_select in PUT body: ${requestBody['gst_rate_select']}');
      print('🔵 [UPDATE PRODUCT - PUT] GST Rate Value: $gstRate');
      print('🔵 [UPDATE PRODUCT - PUT] CGST Rate: $cgstRate');
      print('🔵 [UPDATE PRODUCT - PUT] SGST Rate: $sgstRate');
      print('🔵 [UPDATE PRODUCT - PUT] IGST Rate: $igstRate');
      print('🔵 [UPDATE PRODUCT - PUT] Product Type: $productType');
      print(
          '🔵 [UPDATE PRODUCT - PUT] Variants Count: ${variants?.length ?? 0}');
      print('Request Body JSON: ${jsonEncode(requestBody)}');
      requestBody.forEach((key, value) {
        print('$key: $value');
      });

      print('=== SENDING PUT REQUEST ===');
      print('PUT Request URL: ${uri.toString()}');
      print(
          'PUT Request Headers: {Accept: application/json, Authorization: $authToken, Content-Type: application/json}');
      final putResponse = await http.put(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': authToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('=== PUT RESPONSE RECEIVED ===');
      print('PUT Response Status Code: ${putResponse.statusCode}');
      print('PUT Response Headers: ${putResponse.headers}');
      print('PUT Response Body: ${putResponse.body}');

      final putParsedData = jsonDecode(putResponse.body);
      print('=== PUT PARSED RESPONSE DATA ===');
      print('PUT Parsed Data: $putParsedData');

      if (putResponse.statusCode == 200) {
        print('=== PUT SUCCESS ===');
        print('Product updated successfully via PUT!');
        print('Updated Product ID: ${putParsedData['data']?['id'] ?? 'N/A'}');
        print(
            'Updated Product Name: ${putParsedData['data']?['productName'] ?? 'N/A'}');
        print(
            'Updated Product Code: ${putParsedData['data']?['productCode'] ?? 'N/A'}');

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated Successfully!')));
        var data1 = ref.refresh(productProvider);
        Navigator.pop(context);
        print('=== UPDATE PRODUCT API CALL END (PUT SUCCESS) ===');
        return;
      } else {
        print('=== PUT ERROR ===');
        print('PUT request failed with status: ${putResponse.statusCode}');
        print(
            'PUT Error Message: ${putParsedData['message'] ?? 'Unknown error'}');
        print(
            'PUT Error Details: ${putParsedData['errors'] ?? 'No error details'}');
      }
    } catch (e) {
      print('=== PUT REQUEST EXCEPTION ===');
      print('PUT request failed with exception: $e');
    }

    // Fallback to multipart request
    print('=== FALLBACK TO MULTIPART REQUEST ===');
    print('Falling back to multipart request...');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = authToken;

    print('=== MULTIPART REQUEST HEADERS ===');
    print('Accept: application/json');
    print('Authorization: $authToken');
    print('Content-Type: multipart/form-data');

    request.fields['_method'] = 'PUT';
    request.fields.addAll({
      "productName": productName,
      "productCode": productCode,
      "productSalePrice": productSalePrice,
      "productPurchasePrice": productPurchasePrice,
    });

    if (size != null) request.fields['size'] = size;
    if (color != null) request.fields['color'] = color;
    if (weight != null) request.fields['weight'] = weight;
    if (capacity != null) request.fields['capacity'] = capacity;
    if (type != null) request.fields['type'] = type;
    request.fields['brand_id'] = brandId != null ? brandId.toString() : '';
    request.fields['unit_id'] = unitId != null ? unitId.toString() : '';
    if (categoryId != null) request.fields['category_id'] = categoryId;
    if (vatId != null) request.fields['vat_id'] = vatId;
    // Send vat_type in lowercase as the API expects
    if (vatType != null) request.fields['vat_type'] = vatType.toLowerCase();
    // gst_rate_select should be the GST rate (0, 5, 12, 18, 28, etc.)
    if (vatRate != null) request.fields['gst_rate_select'] = vatRate;
    // gst_type should be Taxable or Non-Taxable
    if (gstType != null) request.fields['gst_type'] = gstType;
    if (gstRate != null) request.fields['gst_rate'] = gstRate;
    if (cgstRate != null) request.fields['cgst_rate'] = cgstRate;
    if (sgstRate != null) request.fields['sgst_rate'] = sgstRate;
    if (igstRate != null) request.fields['igst_rate'] = igstRate;
    if (vatAmount != null) request.fields['vat_amount'] = vatAmount;
    if (exclusivePrice != null)
      request.fields['exclusive_price'] = exclusivePrice;
    if (inclusivePrice != null)
      request.fields['inclusive_price'] = inclusivePrice;
    if (profitMargin != null) request.fields['profit_percent'] = profitMargin;
    if (productWholeSalePrice != null)
      request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null)
      request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null)
      request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null)
      request.fields['productDiscount'] = productDiscount;
    if (productType != null) request.fields['product_type'] = productType;
    if (hsnCode != null) request.fields['hsn_code'] = hsnCode;
    if (variants != null && variants.isNotEmpty) {
      final variantFields = _buildVariantFields(variants);
      request.fields.addAll(variantFields);
      request.fields['variants_json'] = jsonEncode(variants);
      request.fields['variant_count'] = variants.length.toString();
    }

    // Handle stock value properly
    String stockValue = '0';
    if (productStock != null && productStock.isNotEmpty) {
      stockValue = productStock.trim();
      // Convert to double to ensure it's a valid number
      try {
        double.parse(stockValue);
        print('Valid stock value: $stockValue');
      } catch (e) {
        print('Invalid stock value: $stockValue, using 0');
        stockValue = '0';
      }
    } else {
      print('Stock value is null or empty, using 0');
    }

    // Try different field names that the API might expect
    request.fields['productStock'] = stockValue;
    request.fields['stock'] = stockValue;
    request.fields['quantity'] = stockValue;
    request.fields['qty'] = stockValue;

    print('Final stock value being sent: $stockValue');
    print(
        'All stock-related fields: productStock=${request.fields['productStock']}, stock=${request.fields['stock']}, quantity=${request.fields['quantity']}, qty=${request.fields['qty']}');

    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
          'productPicture', image.readAsBytesSync(),
          filename: image.path));
      print('Image file attached: ${image.path}');
    }
    if (lowStock != null) request.fields['alert_qty'] = lowStock;
    if (expDate != null) request.fields['expire_date'] = expDate;

    print('=== MULTIPART REQUEST BODY (Form Fields) ===');
    print('Total Fields: ${request.fields.length}');
    print('Request Fields JSON: ${jsonEncode(request.fields)}');
    request.fields.forEach((key, value) {
      print('$key: $value');
    });

    if (request.files.isNotEmpty) {
      print('=== FILE ATTACHMENTS ===');
      for (var file in request.files) {
        print('File: ${file.filename}, Length: ${file.length}');
      }
    }

    print('=== MULTIPART REQUEST SUMMARY ===');
    print('Method: POST (with _method=PUT)');
    print('URL: ${uri.toString()}');
    print('Product ID: $productId');
    print('Product Name: $productName');
    print('Product Code: $productCode');
    print('Sale Price: $productSalePrice');
    print('Purchase Price: $productPurchasePrice');
    print('Stock: $stockValue');
    print('Category ID: $categoryId');
    print('Brand ID: $brandId');
    print('Unit ID: $unitId');
    print('Has Image: ${image != null}');
    print(
        'Request Headers: {Accept: application/json, Authorization: $authToken}');

    print('=== SENDING MULTIPART REQUEST ===');
    final response = await customHttpClient.uploadFile(
      url: uri,
      file: image,
      fileFieldName: 'productPicture',
      fields: request.fields,
    );
    final responseData = await response.stream.bytesToString();

    print('=== MULTIPART RESPONSE RECEIVED ===');
    print('Response Status Code: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body Length: ${responseData.length} characters');
    print('Response Body: $responseData');

    final parsedData = jsonDecode(responseData);
    print('=== MULTIPART PARSED RESPONSE DATA ===');
    print('Parsed Data: $parsedData');

    // Print specific response fields
    print('=== RESPONSE FIELD BREAKDOWN ===');
    print('Status: ${parsedData['status'] ?? 'N/A'}');
    print('Message: ${parsedData['message'] ?? 'N/A'}');
    print('Data: ${parsedData['data'] ?? 'N/A'}');
    print('Errors: ${parsedData['errors'] ?? 'N/A'}');

    if (parsedData['data'] != null) {
      print('=== UPDATED PRODUCT DETAILS ===');
      print('Product ID: ${parsedData['data']['id'] ?? 'N/A'}');
      print('Product Name: ${parsedData['data']['productName'] ?? 'N/A'}');
      print('Product Code: ${parsedData['data']['productCode'] ?? 'N/A'}');
      print('Sale Price: ${parsedData['data']['productSalePrice'] ?? 'N/A'}');
      print(
          'Purchase Price: ${parsedData['data']['productPurchasePrice'] ?? 'N/A'}');
      print('Stock: ${parsedData['data']['productStock'] ?? 'N/A'}');
      print('Category: ${parsedData['data']['category_id'] ?? 'N/A'}');
      print('Brand: ${parsedData['data']['brand_id'] ?? 'N/A'}');
      print('Unit: ${parsedData['data']['unit_id'] ?? 'N/A'}');
    }

    if (response.statusCode == 200) {
      print('=== MULTIPART SUCCESS ===');
      print('Product updated successfully via multipart!');
      print('Updated Product ID: ${parsedData['data']?['id'] ?? 'N/A'}');
      print(
          'Updated Product Name: ${parsedData['data']?['productName'] ?? 'N/A'}');
      print(
          'Updated Product Code: ${parsedData['data']?['productCode'] ?? 'N/A'}');

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Updated Successfully!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      print('=== MULTIPART ERROR ===');
      print('Product update failed via multipart!');
      print('Error Status: ${response.statusCode}');
      print('Error Message: ${parsedData['message'] ?? 'Unknown error'}');
      print('Error Details: ${parsedData['errors'] ?? 'No error details'}');

      // Print detailed error information
      if (parsedData['errors'] != null) {
        print('=== DETAILED ERROR BREAKDOWN ===');
        if (parsedData['errors'] is Map) {
          parsedData['errors'].forEach((key, value) {
            print('$key: $value');
          });
        } else {
          print('Errors: ${parsedData['errors']}');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Product Update failed: ${parsedData['message']}')));
    }

    print('=== UPDATE PRODUCT API CALL END ===');
    print('Timestamp: ${DateTime.now()}');
    print('==========================================');
  }
}
