import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/constant.dart';
import '../../Repository/constant_functions.dart';

class EditProductForm extends StatefulWidget {
  const EditProductForm({super.key, required this.product});

  final ProductModel product;

  @override
  State<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController productNameController;
  late TextEditingController productCodeController;
  late TextEditingController productStockController;
  late TextEditingController salePriceController;
  late TextEditingController purchasePriceController;
  late TextEditingController wholeSalePriceController;
  late TextEditingController dealerPriceController;
  late TextEditingController discountController;
  late TextEditingController manufacturerController;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with product data
    productNameController = TextEditingController(text: widget.product.productName ?? '');
    productCodeController = TextEditingController(text: widget.product.productCode ?? '');
    productStockController = TextEditingController(text: widget.product.productStock?.toString() ?? '0');
    salePriceController = TextEditingController(text: widget.product.productSalePrice?.toString() ?? '0');
    purchasePriceController = TextEditingController(text: widget.product.productPurchasePrice?.toString() ?? '0');
    wholeSalePriceController = TextEditingController(text: widget.product.productWholeSalePrice?.toString() ?? '0');
    dealerPriceController = TextEditingController(text: widget.product.productDealerPrice?.toString() ?? '0');
    discountController = TextEditingController(text: widget.product.productDiscount?.toString() ?? '0');
    manufacturerController = TextEditingController(text: widget.product.productManufacturer ?? '');
  }

  @override
  void dispose() {
    productNameController.dispose();
    productCodeController.dispose();
    productStockController.dispose();
    salePriceController.dispose();
    purchasePriceController.dispose();
    wholeSalePriceController.dispose();
    dealerPriceController.dispose();
    discountController.dispose();
    manufacturerController.dispose();
    super.dispose();
  }

  Future<void> updateProduct(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    EasyLoading.show(status: 'Updating Product...');

    try {
      // Get auth token
      final authToken = await getAuthToken();
      
      // API URL
      final apiUrl = '${APIConfig.url}/product/${widget.product.id}';
      
      // Prepare request body
      final requestBody = {
        'productName': productNameController.text.trim(),
        'productCode': productCodeController.text.trim(),
        'productStock': productStockController.text.trim(),
        'productSalePrice': salePriceController.text.trim(),
        'productPurchasePrice': purchasePriceController.text.trim(),
        'productWholeSalePrice': wholeSalePriceController.text.trim(),
        'productDealerPrice': dealerPriceController.text.trim(),
        'productDiscount': discountController.text.trim(),
        'productManufacturer': manufacturerController.text.trim(),
        'category_id': widget.product.categoryId?.toString(),
        'brand_id': widget.product.brandId?.toString(),
        'unit_id': widget.product.unitId?.toString(),
      };

      // Print request body to console
      print('╔════════════════════════════════════════════════════════════════╗');
      print('║                    UPDATE PRODUCT REQUEST                     ║');
      print('╚════════════════════════════════════════════════════════════════╝');
      print('');
      print('📤 REQUEST DETAILS:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🌐 API URL: $apiUrl');
      print('🔑 Method: POST');
      print('🕒 Timestamp: ${DateTime.now()}');
      print('');
      print('📋 REQUEST BODY:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(JsonEncoder.withIndent('  ').convert(requestBody));
      print('');
      print('📄 RAW JSON:');
      print(jsonEncode(requestBody));
      print('');

      // Make API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': authToken,
        },
        body: jsonEncode(requestBody),
      );

      // Print response to console
      print('╔════════════════════════════════════════════════════════════════╗');
      print('║                    UPDATE PRODUCT RESPONSE                     ║');
      print('╚════════════════════════════════════════════════════════════════╝');
      print('');
      print('📥 RESPONSE DETAILS:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📊 Status Message: ${response.reasonPhrase}');
      print('🕒 Response Time: ${DateTime.now()}');
      print('');
      print('📋 RESPONSE HEADERS:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      response.headers.forEach((key, value) {
        print('$key: $value');
      });
      print('');
      print('📄 RESPONSE BODY:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('RAW: ${response.body}');
      print('');

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        // Parse and print formatted response
        try {
          final responseData = jsonDecode(response.body);
          print('✅ FORMATTED RESPONSE:');
          print(JsonEncoder.withIndent('  ').convert(responseData));
          print('');
          print('╚════════════════════════════════════════════════════════════════╝');
          print('');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh product list
          final _ = ref.refresh(productProvider);

          // Go back
          Navigator.pop(context);
        } catch (e) {
          print('❌ Error parsing response: $e');
          print('╚════════════════════════════════════════════════════════════════╝');
          print('');
        }
      } else {
        // Parse error response
        try {
          final errorData = jsonDecode(response.body);
          print('❌ ERROR RESPONSE:');
          print(JsonEncoder.withIndent('  ').convert(errorData));
          print('');
          print('╚════════════════════════════════════════════════════════════════╝');
          print('');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update product: ${errorData['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          print('❌ Error parsing error response: $e');
          print('╚════════════════════════════════════════════════════════════════╝');
          print('');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update product. Status: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('╔════════════════════════════════════════════════════════════════╗');
      print('║                        EXCEPTION ERROR                         ║');
      print('╚════════════════════════════════════════════════════════════════╝');
      print('');
      print('❌ Exception: $e');
      print('🕒 Timestamp: ${DateTime.now()}');
      print('');
      print('╚════════════════════════════════════════════════════════════════╝');
      print('');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, __) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: kWhite,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              'Edit Product',
              style: const TextStyle(color: Colors.black),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  if (widget.product.productPicture != null)
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorderColorTextField),
                          image: DecorationImage(
                            image: NetworkImage(
                              '${APIConfig.domain}${widget.product.productPicture}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  // Product Name
                  Text(
                    'Product Name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: productNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter product name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Product Code
                  Text(
                    'Product Code',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: productCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter product code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category, Brand, Unit (Read-only display)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              width: double.infinity,
                              child: Text(
                                widget.product.category?.categoryName ?? 'N/A',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brand',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              width: double.infinity,
                              child: Text(
                                widget.product.brand?.brandName ?? 'N/A',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock
                  Text(
                    'Product Stock',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: productStockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter stock quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Purchase Price
                  Text(
                    'Purchase Price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: purchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter purchase price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter purchase price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sale Price
                  Text(
                    'Sale Price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: salePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter sale price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter sale price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Wholesale Price
                  Text(
                    'Wholesale Price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: wholeSalePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter wholesale price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dealer Price
                  Text(
                    'Dealer Price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: dealerPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter dealer price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Discount
                  Text(
                    'Discount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter discount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Manufacturer
                  Text(
                    'Manufacturer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: manufacturerController,
                    decoration: InputDecoration(
                      hintText: 'Enter manufacturer name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => updateProduct(ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Update Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

