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
  Future<List<ProductModel>> fetchAllProducts() async {
    final uri = Uri.parse('${APIConfig.url}/products');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => ProductModel.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch Products');
    }
  }

  Future<void> addProduct({
    required WidgetRef ref,
    required BuildContext context,
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
    String? vatId,
    String? vatType,
    String? vatAmount,
    String? profitMargin,
    String? lowStock,
    String? expDate,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/products');

    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();
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
    if (vatId != null) request.fields['vat_id'] = vatId;
    if (vatType != null) request.fields['vat_type'] = vatType;
    if (vatAmount != null) request.fields['vat_amount'] = vatAmount;
    if (profitMargin != null) request.fields['profit_percent'] = profitMargin;
    if (productWholeSalePrice != null) request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null) request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null) request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null) request.fields['productDiscount'] = productDiscount;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('productPicture', image.readAsBytesSync(), filename: image.path));
    }
    if (lowStock != null) request.fields['alert_qty'] = lowStock;
    if (expDate != null) request.fields['expire_date'] = expDate;

    // final response = await request.send();
    final response = await customHttpClient.uploadFile(url: uri, file: image, fileFieldName: 'productPicture', fields: request.fields);
    final responseData = await response.stream.bytesToString();
    final parsedData = jsonDecode(responseData);
    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added successful!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product creation failed: ${parsedData['message']}')));
    }
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
    final uri = Uri.parse('${APIConfig.url}/products');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();
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
    if (productWholeSalePrice != null) request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null) request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null) request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null) request.fields['productDiscount'] = productDiscount;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('productPicture', image.readAsBytesSync(), filename: image.path));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final parsedData = jsonDecode(responseData);

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<void> deleteProduct({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/products/$id';

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));

        var data1 = ref.refresh(productProvider);
      } else {
        final parsedData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete product: ${parsedData['message']}')));
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    String? profitMargin,
    String? lowStock,
    String? expDate,
  }) async {
    print('=== UPDATE PRODUCT START ===');
    print('Product ID: $productId');
    print('Stock Value: $productStock');
    print('Stock Value Type: ${productStock.runtimeType}');
    print('Stock Value Empty: ${productStock?.isEmpty}');
    print('Stock Value Null: ${productStock == null}');
    print('Stock Value Length: ${productStock?.length}');
    print('Stock Value Trimmed: "${productStock?.trim()}"');
    
    final uri = Uri.parse('${APIConfig.url}/products/$productId');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    // Try direct PUT request first
    try {
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
        if (productWholeSalePrice != null) 'productWholeSalePrice': productWholeSalePrice,
        if (productDealerPrice != null) 'productDealerPrice': productDealerPrice,
        if (productManufacturer != null) 'productManufacturer': productManufacturer,
        if (productDiscount != null) 'productDiscount': productDiscount,
        if (vatId != null) 'vat_id': vatId,
        if (vatType != null) 'vat_type': vatType,
        if (vatAmount != null) 'vat_amount': vatAmount,
        if (profitMargin != null) 'profit_percent': profitMargin,
        if (lowStock != null) 'alert_qty': lowStock,
        if (expDate != null) 'expire_date': expDate,
      };
      
      print('PUT Request Body: $requestBody');
      
      final putResponse = await http.put(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': await getAuthToken(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      print('PUT Response status: ${putResponse.statusCode}');
      print('PUT Response body: ${putResponse.body}');
      
      if (putResponse.statusCode == 200) {
        print('Product updated successfully via PUT');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated Successfully!')));
        await ref.refresh(productProvider);
        Navigator.pop(context);
        return;
      }
    } catch (e) {
      print('PUT request failed: $e');
    }

    // Fallback to multipart request
    print('Falling back to multipart request...');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();

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
    if (vatType != null) request.fields['vat_type'] = vatType;
    if (vatAmount != null) request.fields['vat_amount'] = vatAmount;
    if (profitMargin != null) request.fields['profit_percent'] = profitMargin;
    if (productWholeSalePrice != null) request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null) request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null) request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null) request.fields['productDiscount'] = productDiscount;
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
    print('All stock-related fields: productStock=${request.fields['productStock']}, stock=${request.fields['stock']}, quantity=${request.fields['quantity']}, qty=${request.fields['qty']}');
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('productPicture', image.readAsBytesSync(), filename: image.path));
    }
    if (lowStock != null) request.fields['alert_qty'] = lowStock;
    if (expDate != null) request.fields['expire_date'] = expDate;

    print('=== MULTIPART REQUEST DEBUG ===');
    print('Product ID: $productId');
    print('All request fields: ${request.fields}');
    print('Stock value in fields: ${request.fields['productStock']}');
    print('Stock value type: ${request.fields['productStock'].runtimeType}');
    
    final response = await customHttpClient.uploadFile(
      url: uri,
      file: image,
      fileFieldName: 'productPicture',
      fields: request.fields,
    );
    final responseData = await response.stream.bytesToString();

    print('Response status: ${response.statusCode}');
    print('Response body: $responseData');

    final parsedData = jsonDecode(responseData);

    if (response.statusCode == 200) {
      print('Product updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated Successfully!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      print('Product update failed: ${parsedData['message']}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product Update failed: ${parsedData['message']}')));
    }
  }
}
