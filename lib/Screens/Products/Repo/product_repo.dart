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
    final token = await getAuthToken();

    print('=== PRODUCTS API CALL ===');
    print('Products API URL: $uri');
    print('Products API Token: Bearer $token');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    print('Products API Response Status: ${response.statusCode}');
    print('Products API Response Headers: ${response.headers}');
    print('Products API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Products API Parsed Data: $parsedData');

      final partyList = parsedData['data'] as List<dynamic>;
      print('Products Count: ${partyList.length}');
      
      final products = partyList.map((category) => ProductModel.fromJson(category)).toList();
      print('Products Successfully Fetched: ${products.length} items');
      return products;
    } else {
      print('Products API Error: ${response.statusCode} - ${response.body}');
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
    final token = await getAuthToken();

    print('=== ADD PRODUCT API CALL ===');
    print('Add Product API URL: $uri');
    print('Add Product API Token: Bearer $token');
    print('Product Name: $productName');
    print('Category ID: $categoryId');
    print('Product Code: $productCode');
    print('Product Stock: $productStock');
    print('Sale Price: $productSalePrice');
    print('Purchase Price: $productPurchasePrice');

    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';
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
    
    print('Add Product API Response Status: ${response.statusCode}');
    print('Add Product API Response Headers: ${response.headers}');
    print('Add Product API Response Body: $responseData');
    print('Add Product API Parsed Data: $parsedData');
    
    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      print('Product Added Successfully!');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added successful!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      print('Product Creation Failed: ${parsedData['message']}');
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
    final token = await getAuthToken();

    print('=== DELETE PRODUCT API CALL ===');
    print('Delete Product API URL: $apiUrl');
    print('Delete Product API Token: Bearer $token');
    print('Product ID to Delete: $id');

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      print('Delete Product API Response Status: ${response.statusCode}');
      print('Delete Product API Response Headers: ${response.headers}');
      print('Delete Product API Response Body: ${response.body}');

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        print('Product Deleted Successfully!');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));

        var data1 = ref.refresh(productProvider);
      } else {
        final parsedData = jsonDecode(response.body);
        print('Product Deletion Failed: ${parsedData['message']}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete product: ${parsedData['message']}')));
      }
    } catch (e) {
      print('Delete Product Error: $e');
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
    final uri = Uri.parse('${APIConfig.url}/products/$productId');
    final token = await getAuthToken();
    
    print('=== UPDATE PRODUCT API CALL ===');
    print('Update Product API URL: $uri');
    print('Update Product API Token: Bearer $token');
    print('Product ID: $productId');
    print('Product Name: $productName');
    print('Product Code: $productCode');
    print('Category ID: $categoryId');
    print('Sale Price: $productSalePrice');
    print('Purchase Price: $productPurchasePrice');
    
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';

    request.fields['_method'] = 'put';
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
    if (productStock != null) request.fields['productStock'] = productStock;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('productPicture', image.readAsBytesSync(), filename: image.path));
    }
    if (lowStock != null) request.fields['alert_qty'] = lowStock;
    if (expDate != null) request.fields['expire_date'] = expDate;

    print('Update Product Request Fields: ${request.fields}');
    final response = await customHttpClient.uploadFile(
      url: uri,
      file: image,
      fileFieldName: 'productPicture',
      fields: request.fields,
    );
    final responseData = await response.stream.bytesToString();

    final parsedData = jsonDecode(responseData);
    
    print('Update Product API Response Status: ${response.statusCode}');
    print('Update Product API Response Headers: ${response.headers}');
    print('Update Product API Response Body: $responseData');
    print('Update Product API Parsed Data: $parsedData');

    if (response.statusCode == 200) {
      print('Product Updated Successfully!');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated Successfully!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      print('Product Update Failed: ${parsedData['message']}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product Update failed: ${parsedData['message']}')));
    }
  }
}
