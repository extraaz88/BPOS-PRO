import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/Screens/Products/Repo/product_repo.dart';
import 'package:mobile_pos/Screens/product_category/category_list_screen.dart';
import 'package:mobile_pos/Screens/product_unit/model/unit_model.dart' as unit;
import 'package:mobile_pos/Screens/product_unit/unit_list.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import '../../Const/api_config.dart';
import '../../GlobalComponents/bar_code_scaner_widget.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart';
import '../product_brand/brands_list.dart';
import '../product_brand/model/brands_model.dart' as brand;
import '../product_category/model/category_model.dart';
import '../vat_&_tax/model/vat_model.dart';
import '../vat_&_tax/provider/text_repo.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key, this.productModel});

  final ProductModel? productModel;

  @override
  AddProductState createState() => AddProductState();
}

class AddProductState extends State<AddProduct> {
  CategoryModel? selectedCategory;
  brand.Brand? selectedBrand;
  unit.Unit? selectedUnit;
  late String productName,
      productStock,
      productSalePrice,
      productPurchasePrice,
      productCode;
  String? selectedDate;
  TextEditingController nameController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController productUnitController = TextEditingController();
  TextEditingController productStockController = TextEditingController();
  TextEditingController salePriceController = TextEditingController();
  TextEditingController discountPriceController = TextEditingController();
  TextEditingController purchaseExclusivePriceController =
      TextEditingController();
  TextEditingController profitMarginController =
      TextEditingController(text: '0');
  TextEditingController purchaseInclusivePriceController =
      TextEditingController();
  TextEditingController productCodeController = TextEditingController();
  TextEditingController wholeSalePriceController = TextEditingController();
  TextEditingController dealerPriceController = TextEditingController();
  TextEditingController manufacturerController = TextEditingController();
  TextEditingController sizeController = TextEditingController();
  TextEditingController colorController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController capacityController = TextEditingController();
  TextEditingController stockAlertController = TextEditingController();
  TextEditingController fromDateTextEditingController = TextEditingController();
  TextEditingController hsnCodeController = TextEditingController();

  bool isVariantProduct = false;
  final List<VariantFormData> variantForms = [];
  int productNameCharCount = 0;

  void initializeControllers() {
    if (widget.productModel != null) {
      nameController =
          TextEditingController(text: widget.productModel?.productName ?? '');
      if (widget.productModel?.category != null) {
        final givenCategory = widget.productModel;
        categoryController = TextEditingController(
            text: widget.productModel?.category?.categoryName ?? '');
        selectedCategory = CategoryModel(
          id: widget.productModel?.category?.id,
          variationCapacity: givenCategory?.capacity != null,
          variationColor: givenCategory?.color != null,
          variationSize: givenCategory?.size != null,
          variationType: givenCategory?.type != null,
          variationWeight: givenCategory?.weight != null,
        );
      }
      if (widget.productModel?.brand != null) {
        brandController = TextEditingController(
            text: widget.productModel?.brand?.brandName ?? '');
        selectedBrand = brand.Brand(id: widget.productModel?.brand?.id);
      }
      if (widget.productModel?.unit != null) {
        productUnitController = TextEditingController(
            text: widget.productModel?.unit?.unitName ?? '');
        selectedUnit = unit.Unit(id: widget.productModel?.unit?.id);
      }

      productStockController = TextEditingController(
          text: widget.productModel?.productStock?.toString() ?? '');
      salePriceController = TextEditingController(
          text: widget.productModel?.productSalePrice?.toString() ?? '');
      selectedTaxType = widget.productModel?.vatType ?? "Exclusive";
      // Ensure the value matches the dropdown items exactly
      if (selectedTaxType.toLowerCase() == 'exclusive') {
        selectedTaxType = 'Exclusive';
      } else if (selectedTaxType.toLowerCase() == 'inclusive') {
        selectedTaxType = 'Inclusive';
      }
      if (widget.productModel?.vatType?.toLowerCase() == 'exclusive') {
        purchaseExclusivePriceController = TextEditingController(
            text:
                widget.productModel?.productPurchasePrice?.toStringAsFixed(2));
        purchaseInclusivePriceController = TextEditingController(
            text: ((widget.productModel?.productPurchasePrice ?? 0) +
                    (widget.productModel?.vatAmount ?? 0))
                .toStringAsFixed(2));
      } else {
        purchaseInclusivePriceController = TextEditingController(
            text:
                widget.productModel?.productPurchasePrice?.toStringAsFixed(2));
        purchaseExclusivePriceController = TextEditingController(
            text: ((widget.productModel?.productPurchasePrice ?? 0) -
                    (widget.productModel?.vatAmount ?? 0))
                .toStringAsFixed(2));
      }
      profitMarginController = TextEditingController(
          text: widget.productModel?.profitMargin?.toStringAsFixed(2) ?? '0');
      productCodeController =
          TextEditingController(text: widget.productModel?.productCode ?? '');
      wholeSalePriceController = TextEditingController(
          text:
              widget.productModel?.productWholeSalePrice?.toStringAsFixed(2) ??
                  '');
      dealerPriceController = TextEditingController(
          text: widget.productModel?.productDealerPrice?.toStringAsFixed(2) ??
              '');
      manufacturerController = TextEditingController(
          text: widget.productModel?.productManufacturer ?? '');
      sizeController =
          TextEditingController(text: widget.productModel?.size ?? '');
      colorController =
          TextEditingController(text: widget.productModel?.color ?? '');
      weightController =
          TextEditingController(text: widget.productModel?.weight ?? '');
      typeController =
          TextEditingController(text: widget.productModel?.type ?? '');
      capacityController =
          TextEditingController(text: widget.productModel?.capacity ?? '');
      stockAlertController = TextEditingController(
          text: widget.productModel?.alertQty.toString() ?? '');
      if (widget.productModel?.expireDate != null) {
        fromDateTextEditingController.text = DateFormat.yMd().format(
            DateTime.parse(widget.productModel?.expireDate.toString() ?? ''));
        selectedDate = widget.productModel?.expireDate?.toString();
      }
      // Initialize GST Rate and GST Type
      selectedGstRate = widget.productModel?.gstRateSelect;
      selectedGstType = widget.productModel?.gstType;

      // Initialize VAT from existing product model
      if (widget.productModel?.vatId != null) {
        // We'll need to fetch the VAT details from the API to get the rate
        // For now, we'll set a placeholder that will be updated when VAT data loads
        selectedTax = VatModel(
          id: widget.productModel?.vatId,
          name: 'VAT',
          rate: 0, // Will be updated when VAT data loads
          status: true,
        );
        selectedVatRate = null; // Will be updated when VAT data loads
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    brandController.dispose();
    productUnitController.dispose();
    productStockController.dispose();
    salePriceController.dispose();
    discountPriceController.dispose();
    purchaseExclusivePriceController.dispose();
    profitMarginController.dispose();
    purchaseInclusivePriceController.dispose();
    productCodeController.dispose();
    wholeSalePriceController.dispose();
    dealerPriceController.dispose();
    manufacturerController.dispose();
    sizeController.dispose();
    colorController.dispose();
    weightController.dispose();
    typeController.dispose();
    capacityController.dispose();
    stockAlertController.dispose();
    fromDateTextEditingController.dispose();
    hsnCodeController.dispose();
    for (final variant in variantForms) {
      variant.dispose();
    }
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();
  XFile? pickedImage;
  VatModel? selectedTax;
  String selectedTaxType = 'Exclusive';
  String? selectedVatRate;
  String? selectedGstRate; // GST Rate percentage (0, 5, 12, 18, 28)
  String? selectedGstType; // GST Type (Taxable/Non-Taxable)
  List<String> codeList = [];
  String promoCodeHint = 'Enter Product Code';

  void calculatePurchaseAndMrp({String? from}) {
    num taxRate = selectedTax?.rate ?? 0;
    num purchaseExc = 0;
    num purchaseInc = 0;
    num profitMargin = num.tryParse(profitMarginController.text) ?? 0;
    num salePrice = 0;

    // Calculate Purchase Exclusive Price if input is 'purchase_inc'
    if (from == 'purchase_inc') {
      purchaseExc = (num.tryParse(purchaseInclusivePriceController.text) ?? 0) /
          (1 + taxRate / 100);
      purchaseExclusivePriceController.text = purchaseExc.toStringAsFixed(2);
    } else {
      purchaseExc = num.tryParse(purchaseExclusivePriceController.text) ?? 0;
      // Calculate Purchase Inclusive Price if not 'purchase_inc'
      purchaseInc = purchaseExc + (purchaseExc * taxRate / 100);
      purchaseInclusivePriceController.text = purchaseInc.toStringAsFixed(2);
    }

    purchaseInc = num.tryParse(purchaseInclusivePriceController.text) ?? 0;

    // If input is 'mrp', recalculate profit margin based on sale price
    if (from == 'mrp') {
      salePrice = num.tryParse(salePriceController.text) ?? 0;

      // Calculate profit margin as a percentage
      profitMargin = ((salePrice -
                  (selectedTaxType.toLowerCase() == 'exclusive'
                      ? purchaseExc
                      : purchaseInc)) /
              (selectedTaxType.toLowerCase() == 'exclusive'
                  ? purchaseExc
                  : purchaseInc)) *
          100;

      // Update the profit margin text field with percentage
      profitMarginController.text = profitMargin.toStringAsFixed(2);
    } else {
      // Calculate Sale Price based on Tax Type
      salePrice = (selectedTaxType.toLowerCase() == 'exclusive')
          ? purchaseExc + (purchaseExc * profitMargin / 100)
          : purchaseInc + (purchaseInc * profitMargin / 100);

      // Update the sale price text field
      salePriceController.text = salePrice.toStringAsFixed(2);
    }

    setState(() {});
  }

  void _toggleVariantProduct(bool value) {
    if (value == isVariantProduct) return;
    if (!value) {
      for (final variant in variantForms) {
        variant.dispose();
      }
      variantForms.clear();
    } else if (variantForms.isEmpty) {
      variantForms.add(VariantFormData());
    }
    setState(() {
      isVariantProduct = value;
    });
  }

  void _addVariantForm() {
    setState(() {
      variantForms.add(VariantFormData());
    });
  }

  void _removeVariantForm(int index) {
    if (index < 0 || index >= variantForms.length) return;
    setState(() {
      variantForms[index].dispose();
      variantForms.removeAt(index);
    });
  }

  String? _validateVariants() {
    if (!isVariantProduct) return null;
    if (variantForms.isEmpty) {
      return 'Please add at least one variant.';
    }
    for (var i = 0; i < variantForms.length; i++) {
      final validationMessage = variantForms[i].validationMessage();
      if (validationMessage != null) {
        return 'Variant ${i + 1}: $validationMessage';
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _collectVariantPayload() {
    if (!isVariantProduct) return [];
    return variantForms.map((variant) => variant.toJson()).toList();
  }

  Map<String, dynamic> _buildDebugRequestPayload({
    required String productStockValue,
    required String salePriceValue,
    required String exclusivePriceValue,
    required String inclusivePriceValue,
    required String vatAmountValue,
    required List<Map<String, dynamic>>? variantsList,
    required String? productTypeValue,
    required String? sizeValue,
    required String? colorValue,
    required String? weightValue,
    required String? capacityValue,
    required String? typeValue,
    required String? dealerPriceValue,
    required String? discountValue,
    required String? manufacturerValue,
    required String? wholeSalePriceValue,
    required String? lowStockValue,
    required GstBreakdown gstBreakdown,
    required String? hsnCode,
    String? productId,
  }) {
    return {
      if (productId != null) 'productId': productId,
      'productName': nameController.text,
      'category_id': selectedCategory?.id,
      'brand_id': selectedBrand?.id,
      'unit_id': selectedUnit?.id,
      'productCode': productCodeController.text,
      'productStock': productStockValue,
      'productSalePrice': salePriceValue,
      'productPurchasePrice': selectedTaxType.toLowerCase() == 'exclusive'
          ? exclusivePriceValue
          : inclusivePriceValue,
      'exclusive_price': exclusivePriceValue,
      'inclusive_price': inclusivePriceValue,
      'size': sizeValue,
      'color': colorValue,
      'weight': weightValue,
      'capacity': capacityValue,
      'type': typeValue,
      'dealerPrice': dealerPriceValue,
      'discount': discountValue,
      'manufacturer': manufacturerValue,
      'wholeSalePrice': wholeSalePriceValue,
      'vat_id': selectedTax?.id,
      'vat_type': selectedTaxType,
      'gst_rate_select': selectedGstRate,
      'gst_type': selectedGstType,
      'gst_rate': gstBreakdown.gstRate,
      'cgst_rate': gstBreakdown.cgstRate,
      'sgst_rate': gstBreakdown.sgstRate,
      'igst_rate': gstBreakdown.igstRate,
      'profit_margin': profitMarginController.text,
      'vat_amount': vatAmountValue,
      'low_stock': lowStockValue,
      'exp_date': selectedDate,
      'product_type': productTypeValue,
      'variants': variantsList,
      'hsn_code': hsnCode,
    };
  }

  VariantPricingSummary _buildVariantPricingSummary(
      List<Map<String, dynamic>> variantsPayload) {
    if (variantsPayload.isEmpty) {
      return const VariantPricingSummary();
    }

    num totalStock = 0;
    for (final variant in variantsPayload) {
      totalStock += (variant['stock'] as num?) ?? 0;
    }

    final firstVariant = variantsPayload.first;
    final purchasePrice =
        (firstVariant['purchase_price'] as num?)?.toDouble() ?? 0;
    final mrp = (firstVariant['mrp'] as num?)?.toDouble() ?? 0;

    num vatRate = selectedTax?.rate ?? 0;
    if (selectedVatRate != null) {
      vatRate = num.tryParse(selectedVatRate!) ?? vatRate;
    }
    final inclusivePrice =
        purchasePrice + (purchasePrice * (vatRate.toDouble()) / 100);

    return VariantPricingSummary(
      totalStock: totalStock.toDouble(),
      exclusivePrice: purchasePrice,
      inclusivePrice: inclusivePrice,
      mrp: mrp,
    );
  }

  GstBreakdown _calculateGstBreakdown() {
    final rateValue = double.tryParse(selectedGstRate ?? '') ?? 0;
    final hasRate = rateValue > 0;
    final cgst = hasRate ? rateValue / 2 : 0;
    final sgst = hasRate ? rateValue / 2 : 0;
    final igst = hasRate ? rateValue : 0;

    return GstBreakdown(
      gstRate: hasRate ? rateValue.toString() : null,
      cgstRate: hasRate ? cgst.toString() : null,
      sgstRate: hasRate ? sgst.toString() : null,
      igstRate: hasRate ? igst.toString() : null,
    );
  }

  String? _getControllerValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _resolveSizeValue(List<Map<String, dynamic>> variantsPayload) {
    final value = _getControllerValue(sizeController);
    if (value != null) return value;
    if (variantsPayload.isNotEmpty) {
      final variantSize = variantsPayload.first['size'];
      if (variantSize is String && variantSize.trim().isNotEmpty) {
        return variantSize.trim();
      }
    }
    return null;
  }

  String? _resolveWeightValue(List<Map<String, dynamic>> variantsPayload) {
    final value = _getControllerValue(weightController);
    if (value != null) return value;
    if (variantsPayload.isNotEmpty) {
      final variantWeight = variantsPayload.first['weight'];
      if (variantWeight is String && variantWeight.trim().isNotEmpty) {
        return variantWeight.trim();
      }
    }
    return null;
  }

  String? _resolveColorValue(List<Map<String, dynamic>> variantsPayload) {
    final value = _getControllerValue(colorController);
    if (value != null) return value;
    if (variantsPayload.isNotEmpty) {
      final variantColor = variantsPayload.first['color'];
      if (variantColor is String && variantColor.trim().isNotEmpty) {
        return variantColor.trim();
      }
    }
    return null;
  }

  String? _resolveCapacityValue(List<Map<String, dynamic>> variantsPayload) {
    final value = _getControllerValue(capacityController);
    if (value != null) return value;
    if (variantsPayload.isNotEmpty) {
      final variantCapacity = variantsPayload.first['capacity'];
      if (variantCapacity is String && variantCapacity.trim().isNotEmpty) {
        return variantCapacity.trim();
      }
    }
    return null;
  }

  String? _resolveTypeValue(List<Map<String, dynamic>> variantsPayload) {
    final value = _getControllerValue(typeController);
    if (value != null) return value;
    if (variantsPayload.isNotEmpty) {
      final variantType = variantsPayload.first['type'];
      if (variantType is String && variantType.trim().isNotEmpty) {
        return variantType.trim();
      }
    }
    return null;
  }

  Widget _buildVariantField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: kInputDecoration.copyWith(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }

  @override
  void initState() {
    initializeControllers();
    // Initialize character count
    final initialText = nameController.text;
    if (initialText.isNotEmpty) {
      productNameCharCount = initialText.length;
    }
    super.initState();
  }

  GlobalKey<FormState> key = GlobalKey();

  bool isAlreadyBuild = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          surfaceTintColor: kWhite,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            lang.S.of(context).addNewProduct,
          ),
          centerTitle: true,
        ),
        body: Consumer(builder: (context, ref, __) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: Form(
                key: key,
                child: Column(
                  children: [
                    ///___________Name_____________________________
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: kInputDecoration.copyWith(
                              labelText: '${lang.S.of(context).productName} *',
                              hintText: lang.S.of(context).enterProductName,
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(15),
                            ],
                            onChanged: (value) {
                              setState(() {
                                productNameCharCount = value.length;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return lang.S.of(context).pleaseEnterAValidProductName;
                              }
                              if (value.length > 15) {
                                return 'Product name should not exceed 15 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$productNameCharCount / 15 characters',
                            style: TextStyle(
                              fontSize: 12,
                              color: productNameCharCount > 15 ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    ///_______Category__________________________________
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        readOnly: true,
                        controller: categoryController,
                        validator: (value) {
                          return null;
                        },
                        onTap: () async {
                          selectedCategory = await const CategoryList(
                            isFromProductList: false,
                          ).launch(context);
                          setState(() {
                            categoryController.text =
                                selectedCategory?.categoryName ?? '';
                            // selectedCategory = data.categoryName;
                          });
                        },
                        decoration: kInputDecoration.copyWith(
                          suffixIcon: selectedCategory != null
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = null;
                                      categoryController.clear();
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                )
                              : const Icon(Icons.keyboard_arrow_down),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          //labelText: 'Product Category',
                          labelText: lang.S.of(context).productCategory,
                          //hintText: 'Select Product Category',
                          hintText: lang.S.of(context).selectProductCategory,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),

                    ///________Size__Color_________________________
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                          controller: sizeController,
                          label: lang.S.of(context).size,
                          hint: lang.S.of(context).enterSize,
                        )).visible(!isVariantProduct &&
                            (selectedCategory?.variationSize ?? false)),
                        Expanded(
                            child: _buildTextField(
                          controller: colorController,
                          label: lang.S.of(context).color,
                          hint: lang.S.of(context).enterColor,
                        )).visible(!isVariantProduct &&
                            (selectedCategory?.variationColor ?? false)),
                      ],
                    ),

                    ///________Capacity_and_weight_____________________________
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                          controller: weightController,
                          label: lang.S.of(context).weight,
                          hint: lang.S.of(context).enterWeight,
                        )).visible(!isVariantProduct &&
                            (selectedCategory?.variationWeight ?? false)),
                        Expanded(
                            child: _buildTextField(
                          controller: capacityController,
                          label: lang.S.of(context).capacity,
                          hint: lang.S.of(context).enterCapacity,
                        )).visible(!isVariantProduct &&
                            (selectedCategory?.variationCapacity ?? false)),
                      ],
                    ),

                    ///___________Type______________________________________
                    _buildTextField(
                      controller: typeController,
                      label: lang.S.of(context).type,
                      hint: lang.S.of(context).enterType,
                    ).visible(!isVariantProduct &&
                        (selectedCategory?.variationType ?? false)),

                    _buildTextField(
                      controller: hsnCodeController,
                      label: 'HSN Code',
                      hint: 'Enter HSN Code',
                    ),

                    SwitchListTile.adaptive(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10.0),
                      title: const Text('Enable Variants'),
                      subtitle: const Text(
                          'Use multiple sizes or weights for this product'),
                      value: isVariantProduct,
                      onChanged: (value) => _toggleVariantProduct(value),
                    ),

                    if (isVariantProduct)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children:
                                List.generate(variantForms.length, (index) {
                              final variant = variantForms[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Variant ${index + 1}',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          if (variantForms.length > 1)
                                            IconButton(
                                              onPressed: () =>
                                                  _removeVariantForm(index),
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red),
                                            ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildVariantField(
                                              controller:
                                                  variant.sizeController,
                                              label: 'Size',
                                              hint: 'e.g. Small',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildVariantField(
                                              controller:
                                                  variant.colorController,
                                              label: 'Color',
                                              hint: 'e.g. Blue',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildVariantField(
                                              controller:
                                                  variant.weightController,
                                              label: 'Weight',
                                              hint: 'e.g. 20 g',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildVariantField(
                                              controller:
                                                  variant.capacityController,
                                              label: 'Capacity',
                                              hint: 'e.g. 50 ml',
                                            ),
                                          ),
                                        ],
                                      ),
        //-----------------------------------------------------------------//

                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildVariantField(
                                              controller: variant.typeController,
                                              label: 'Type',
                                              hint: 'e.g. Premium',
                                            ),
                                          ),
                                           Expanded(
                          child: AbsorbPointer(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                readOnly: true,
                                controller: productUnitController,
                                validator: (value) {
                                  return null;
                                },
                                onTap: () async {
                                  selectedUnit = await const UnitList(
                                    isFromProductList: false,
                                  ).launch(context);
                                  setState(() {
                                    productUnitController.text =
                                        selectedUnit?.unitName ?? '';
                                  });
                                },
                                decoration: kInputDecoration.copyWith(
                                  suffixIcon: selectedUnit != null
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedUnit = null;
                                              productUnitController.clear();
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                        )
                                      : const Icon(Icons.keyboard_arrow_down),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  //labelText: 'Product Unit',
                                  labelText: lang.S.of(context).productUnit,
                                  // hintText: 'Select Product Unit',
                                  hintText: lang.S.of(context).selectProductUnit,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ),
                                        ],
                                      ),

                //-----------------------------------------------------------------//
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildVariantField(
                                              controller: variant
                                                  .purchasePriceController,
                                              label: 'Purchase Price',
                                              hint: '0.00',
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'^\d*\.?\d{0,2}'))
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildVariantField(
                                              controller: variant.mrpController,
                                              label: 'MRP',
                                              hint: '0.00',
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'^\d*\.?\d{0,2}'))
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildVariantField(
                                              controller:
                                                  variant.stockController,
                                              label: 'Stock',
                                              hint: '0',
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'^\d*'))
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildVariantField(
                                              controller:
                                                  variant.lowStockController,
                                              label: 'Low Stock Alert',
                                              hint: '0',
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'^\d*'))
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: TextButton.icon(
                                onPressed: _addVariantForm,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Variant'),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => _toggleVariantProduct(false),
                                icon: const Icon(Icons.clear),
                                label: const Text('Remove Variants'),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ///_______Brand__________________________________
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        readOnly: true,
                        controller: brandController,
                        validator: (value) {
                          return null;
                        },
                        onTap: () async {
                          selectedBrand = await const BrandsList(
                            isFromProductList: false,
                          ).launch(context);
                          setState(() {
                            brandController.text =
                                selectedBrand?.brandName ?? '';
                          });
                        },
                        decoration: kInputDecoration.copyWith(
                          suffixIcon: selectedBrand != null
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedBrand = null;
                                      brandController.clear();
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                )
                              : const Icon(Icons.keyboard_arrow_down),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          // labelText: 'Product Brand',
                          labelText: lang.S.of(context).productBrand,
                          // hintText: 'Select a brand',
                          hintText: lang.S.of(context).selectABrand,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),

                    ///__________Code__________________________
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: productCodeController,
                              onChanged: (value) {
                                setState(() {
                                  productCode = value;
                                  promoCodeHint = value;
                                });
                              },
                              onFieldSubmitted: (value) {
                                if (codeList.contains(value)) {
                                  EasyLoading.showError(
                                    lang.S.of(context).thisProductAlreadyAdded,
                                    // 'This Product Already added!'
                                  );
                                  productCodeController.clear();
                                } else {
                                  setState(() {
                                    productCode = value;
                                    promoCodeHint = value;
                                  });
                                }
                              },
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).productCode,
                                hintText: lang.S.of(context).enterProductCode,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) => BarcodeScannerWidget(
                                    onBarcodeFound: (String code) {
                                      productCodeController.text = code;
                                    },
                                  ),
                                );
                              },
                              child: const BarCodeButton(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    ///_____________Stock__&_Unit__________________________
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: productStockController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              readOnly: isVariantProduct,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText:
                                    '${lang.S.of(context).stock}${selectedUnit?.unitName != null && selectedUnit!.unitName!.isNotEmpty ? ' (${selectedUnit!.unitName})' : ''}',
                                // hintText: 'Enter stock',
                                hintText: lang.S.of(context).enterStock,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: productUnitController,
                              validator: (value) {
                                return null;
                              },
                              onTap: () async {
                                selectedUnit = await const UnitList(
                                  isFromProductList: false,
                                ).launch(context);
                                setState(() {
                                  productUnitController.text =
                                      selectedUnit?.unitName ?? '';
                                });
                              },
                              decoration: kInputDecoration.copyWith(
                                suffixIcon: selectedUnit != null
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedUnit = null;
                                            productUnitController.clear();
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      )
                                    : const Icon(Icons.keyboard_arrow_down),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                //labelText: 'Product Unit',
                                labelText: lang.S.of(context).productUnit,
                                // hintText: 'Select Product Unit',
                                hintText: lang.S.of(context).selectProductUnit,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    ///-----------Applicable tax and Type-----------------------------
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final vatsData = ref.watch(taxProvider);
                                return vatsData.when(
                                  data: (vats) {
                                    // Print API response for debugging
                                    print('=== VAT API RESPONSE ===');
                                    print(
                                        'Number of VATs fetched: ${vats.length}');
                                    for (var vat in vats) {
                                      print(
                                          'VAT ID: ${vat.id}, Name: ${vat.name}, Rate: ${vat.rate}%');
                                    }
                                    print('=== END VAT API RESPONSE ===');

                                    // Initialize VAT selection for existing product
                                    VatModel? currentVat = selectedTax;
                                    if (widget.productModel?.vatId != null &&
                                        selectedTax?.id ==
                                            widget.productModel?.vatId) {
                                      // Find the matching VAT from API data
                                      currentVat = vats.firstWhere(
                                        (vat) =>
                                            vat.id ==
                                            widget.productModel?.vatId,
                                        orElse: () => selectedTax!,
                                      );
                                      if (currentVat != selectedTax) {
                                        // Update the selected tax with the correct data from API
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          setState(() {
                                            selectedTax = currentVat;
                                            selectedVatRate =
                                                currentVat?.rate?.toString();
                                          });
                                        });
                                      }
                                    }

                                    return DropdownButtonFormField<VatModel>(
                                      hint: const Text(
                                        'Select VAT',
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            color: kGreyTextColor),
                                      ),
                                      icon: selectedTax != null
                                          ? GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedTax = null;
                                                  selectedVatRate = null;
                                                });
                                                calculatePurchaseAndMrp();
                                              },
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                            )
                                          : const Icon(Icons
                                              .keyboard_arrow_down_outlined),
                                      decoration: kInputDecoration.copyWith(
                                        labelText: "Select VAT",
                                      ),
                                      value: currentVat,
                                      items: vats
                                          .map((vat) =>
                                              DropdownMenuItem<VatModel>(
                                                value: vat,
                                                child: Text(
                                                  '${vat.rate}%',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedTax = value!;
                                          selectedVatRate =
                                              value.rate?.toString();
                                        });
                                        calculatePurchaseAndMrp();
                                      },
                                    );
                                  },
                                  loading: () =>
                                      DropdownButtonFormField<String>(
                                    hint: const Text(
                                      'Loading VATs...',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: kGreyTextColor),
                                    ),
                                    icon: const Icon(
                                        Icons.keyboard_arrow_down_outlined),
                                    decoration: kInputDecoration.copyWith(
                                      labelText: "Select VAT",
                                    ),
                                    items: const [],
                                    onChanged: null,
                                  ),
                                  error: (error, stack) {
                                    print('=== VAT API ERROR ===');
                                    print('Error: $error');
                                    print('Stack: $stack');
                                    print('=== END VAT API ERROR ===');

                                    return DropdownButtonFormField<String>(
                                      hint: const Text(
                                        'Error loading VATs',
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            color: Colors.red),
                                      ),
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down_outlined),
                                      decoration: kInputDecoration.copyWith(
                                        labelText: "Select VAT",
                                      ),
                                      items: const [],
                                      onChanged: null,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),

                        // Tax type
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<String?>(
                              hint: const Text('Select Type'),
                              decoration: kInputDecoration.copyWith(
                                  labelText: "Vat Type"),
                              value: selectedTaxType == 'exclusive'
                                  ? 'Exclusive'
                                  : selectedTaxType == 'inclusive'
                                      ? 'Inclusive'
                                      : selectedTaxType,
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_outlined),
                              items: ["Inclusive", "Exclusive"]
                                  .map((type) => DropdownMenuItem<String?>(
                                        value: type,
                                        child: Text(
                                          type,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                selectedTaxType = value!;
                                calculatePurchaseAndMrp();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // GST Rate Dropdown
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DropdownButtonFormField<String>(
                        hint: const Text(
                          'Select GST Rate',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: kGreyTextColor,
                          ),
                        ),
                        decoration: kInputDecoration.copyWith(
                          labelText: "GST Rate (%)",
                        ),
                        value: selectedGstRate,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        items: ["0", "5", "12", "18", "28"]
                            .map((rate) => DropdownMenuItem<String>(
                                  value: rate,
                                  child: Text(
                                    '$rate%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGstRate = value;
                          });
                        },
                      ),
                    ),

                    // GST Type Dropdown
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DropdownButtonFormField<String>(
                        hint: const Text(
                          'Select GST Type',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: kGreyTextColor,
                          ),
                        ),
                        decoration: kInputDecoration.copyWith(
                          labelText: "GST Type *",
                        ),
                        value: selectedGstType,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a GST Type';
                          }
                          return null;
                        },
                        icon: selectedGstType != null
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedGstType = null;
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              )
                            : const Icon(Icons.keyboard_arrow_down_outlined),
                        items: [
                          DropdownMenuItem<String>(
                            value: "taxable",
                            child: Text(
                              "Taxable",
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: "exempt",
                            child: Text(
                              "Non-Taxable",
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGstType = value;
                          });
                        },
                      ),
                    ),

                    ///_____________Tax System Type__________________________
                    // Padding(
                    //   padding: const EdgeInsets.all(10.0),
                    //   child: DropdownButtonFormField<String>(
                    //     hint: const Text('Select Tax System'),
                    //     decoration: kInputDecoration.copyWith(
                    //       labelText: "Tax System Type",
                    //       floatingLabelBehavior: FloatingLabelBehavior.always,
                    //     ),
                    //     value: selectedGstType,
                    //     icon: const Icon(Icons.keyboard_arrow_down_outlined),
                    //     items: [
                    //       DropdownMenuItem<String>(
                    //         value: "vat",
                    //         child: Text(
                    //           'VAT',
                    //           style: const TextStyle(
                    //               fontWeight: FontWeight.normal),
                    //         ),
                    //       ),
                    //       DropdownMenuItem<String>(
                    //         value: "gst",
                    //         child: Text(
                    //           'GST',
                    //           style: const TextStyle(
                    //               fontWeight: FontWeight.normal),
                    //         ),
                    //       ),
                    //     ],
                    //     onChanged: (value) {
                    //       setState(() {
                    //         selectedGstType = value!;
                    //       });
                    //     },
                    //   ),
                    // ),

                    ///_________Purchase_price_exclusive_&&_Inclusive____________________
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: purchaseExclusivePriceController,
                              onChanged: (value) => calculatePurchaseAndMrp(),
                              validator: (value) {
                                if (isVariantProduct) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  //return 'Please enter a valid purchase price';
                                  return lang.S
                                      .of(context)
                                      .pleaseEnterAValidProductName;
                                }
                                // You can add more validation logic as needed
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: 'Purchase Price Exc. *',
                                hintText: lang.S.of(context).enterPurchasePrice,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: purchaseInclusivePriceController,
                              validator: (value) {
                                if (isVariantProduct) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  //return 'Please enter a valid Sale price';
                                  return lang.S
                                      .of(context)
                                      .pleaseEnterAValidSalePrice;
                                }
                                // You can add more validation logic as needed
                                return null;
                              },
                              onChanged: (value) =>
                                  calculatePurchaseAndMrp(from: "purchase_inc"),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: 'Purchase Price Inc. *',
                                //hintText: 'Enter selling price',
                                hintText: lang.S.of(context).enterSaltingPrice,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    ///__________Profit_margin___________________________________________

                    ///_________Purchase_price__&&______mrp_____________________
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: profitMarginController,
                              onChanged: (value) {
                                // If empty or only whitespace, set to 0
                                if (value.isEmpty || value.trim().isEmpty) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (profitMarginController.text.isEmpty ||
                                        profitMarginController.text
                                            .trim()
                                            .isEmpty) {
                                      profitMarginController.text = '0';
                                      profitMarginController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset: profitMarginController
                                                .text.length),
                                      );
                                    }
                                  });
                                }
                                calculatePurchaseAndMrp();
                              },
                              validator: (value) {
                                // Always valid, defaults to 0
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: 'Profit Margin (%) *',
                                hintText: '0',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: salePriceController,
                              onChanged: (value) =>
                                  calculatePurchaseAndMrp(from: 'mrp'),
                              validator: (value) {
                                if (isVariantProduct) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  return lang.S
                                      .of(context)
                                      .pleaseEnterAValidSalePrice;
                                }
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: '${lang.S.of(context).mrp} *',
                                //hintText: 'Enter selling price',
                                hintText: lang.S.of(context).enterSaltingPrice,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    ///_______-wholesalePrice_dealerprice_________________
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: wholeSalePriceController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).wholeSalePrice,
                                //hintText: 'Enter wholesale price',
                                hintText:
                                    lang.S.of(context).enterWholesalePrice,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: dealerPriceController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).dealerPrice,
                                //hintText: 'Enter dealer price',
                                hintText: lang.S.of(context).enterDealerPrice,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stockAlertController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: 'Low Stock',
                                hintText: 'Enter low stock',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              readOnly: true,
                              controller: fromDateTextEditingController,
                              decoration: kInputDecoration.copyWith(
                                labelText: 'Exp. Date',
                                hintText: 'Select Date',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  padding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  onPressed: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2015, 8),
                                      lastDate: DateTime(2101),
                                      context: context,
                                    );
                                    setState(() {
                                      if (picked != null) {
                                        fromDateTextEditingController.text =
                                            DateFormat.yMd().format(picked);
                                        selectedDate = picked.toString();
                                      } else {
                                        fromDateTextEditingController.text =
                                            fromDateTextEditingController.text;
                                      }
                                    });
                                  },
                                  icon: const Icon(IconlyLight.calendar,
                                      size: 22),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            controller: discountPriceController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ],
                            keyboardType: TextInputType.number,
                            decoration: kInputDecoration.copyWith(
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              labelText: lang.S.of(context).discount,
                              //hintText: 'Enter discount',
                              hintText: lang.S.of(context).enterDiscount,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        )).visible(false),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: manufacturerController,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).manufacturer,
                                //hintText: 'Enter manufacturer name',
                                hintText:
                                    lang.S.of(context).enterManufacturerName,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    // ignore: sized_box_for_whitespace
                                    child: Container(
                                      height: 200.0,
                                      width: MediaQuery.of(context).size.width -
                                          80,
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                pickedImage =
                                                    await _picker.pickImage(
                                                        source: ImageSource
                                                            .gallery);

                                                setState(() {});

                                                Future.delayed(
                                                    const Duration(
                                                        milliseconds: 100), () {
                                                  Navigator.pop(context);
                                                });
                                              },
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.photo_library_rounded,
                                                    size: 60.0,
                                                    color: kMainColor,
                                                  ),
                                                  Text(
                                                    lang.S.of(context).gallery,
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      color: kGreyTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 40.0),
                                            GestureDetector(
                                              onTap: () async {
                                                pickedImage =
                                                    await _picker.pickImage(
                                                        source:
                                                            ImageSource.camera);
                                                setState(() {});
                                                Future.delayed(
                                                    const Duration(
                                                        milliseconds: 100), () {
                                                  Navigator.pop(context);
                                                });
                                              },
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.camera,
                                                    size: 60.0,
                                                    color: kGreyTextColor,
                                                  ),
                                                  Text(
                                                    lang.S.of(context).camera,
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      color: kGreyTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                });
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black54, width: 1),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(120)),
                                  image: pickedImage == null
                                      ? widget.productModel?.productPicture ==
                                              null
                                          ? DecorationImage(
                                              image:
                                                  AssetImage(noProductImageUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : DecorationImage(
                                              image: NetworkImage(
                                                  '${APIConfig.domain}${widget.productModel?.productPicture ?? ''}'),
                                              fit: BoxFit.cover,
                                            )
                                      : DecorationImage(
                                          image: FileImage(
                                              File(pickedImage!.path)),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 35,
                                  width: 35,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(120)),
                                    color: kMainColor,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final variantValidationMessage = _validateVariants();
                        if (variantValidationMessage != null) {
                          EasyLoading.showError(variantValidationMessage);
                          return;
                        }
                        if (key.currentState!.validate()) {
                          print('=== FORM VALIDATION PASSED ===');
                          print(
                              'Stock value before processing: "${productStockController.text}"');
                          try {
                            final variantsPayload = _collectVariantPayload();
                            final variantSummary =
                                _buildVariantPricingSummary(variantsPayload);
                            final gstBreakdown = _calculateGstBreakdown();

                            String productStockValue =
                                productStockController.text.trim();
                            String exclusivePriceValue =
                                purchaseExclusivePriceController.text;
                            String inclusivePriceValue =
                                purchaseInclusivePriceController.text;
                            String salePriceValue = salePriceController.text;

                            if (isVariantProduct &&
                                variantsPayload.isNotEmpty) {
                              productStockValue =
                                  variantSummary.totalStockString;
                              exclusivePriceValue =
                                  variantSummary.exclusivePriceString;
                              inclusivePriceValue =
                                  variantSummary.inclusivePriceString;
                              salePriceValue = variantSummary.mrpString;

                              productStockController.text = productStockValue;
                              purchaseExclusivePriceController.text =
                                  exclusivePriceValue;
                              purchaseInclusivePriceController.text =
                                  inclusivePriceValue;
                              salePriceController.text = salePriceValue;
                            }

                            if (productStockValue.trim().isEmpty) {
                              productStockValue = '0';
                              productStockController.text = productStockValue;
                            }

                            final vatAmountValue =
                                ((num.tryParse(inclusivePriceValue) ?? 0) -
                                        (num.tryParse(exclusivePriceValue) ??
                                            0))
                                    .toString();

                            final hsnCode =
                                hsnCodeController.text.trim().isEmpty
                                    ? null
                                    : hsnCodeController.text.trim();

                            final productTypeValue =
                                isVariantProduct ? 'variant' : null;

                            final variantsListForApi = variantsPayload.isEmpty
                                ? null
                                : variantsPayload;

                            final sizeValue =
                                _resolveSizeValue(variantsPayload);
                            final weightValue =
                                _resolveWeightValue(variantsPayload);
                            final colorValue =
                                _resolveColorValue(variantsPayload);
                            final capacityValue =
                                _resolveCapacityValue(variantsPayload);
                            final typeValue =
                                _resolveTypeValue(variantsPayload);
                            final dealerPriceValue =
                                _getControllerValue(dealerPriceController);
                            final discountValue =
                                _getControllerValue(discountPriceController);
                            final manufacturerValue =
                                _getControllerValue(manufacturerController);
                            final wholeSalePriceValue =
                                _getControllerValue(wholeSalePriceController);
                            final lowStockValue =
                                _getControllerValue(stockAlertController);
                            final debugPayload = _buildDebugRequestPayload(
                              productStockValue: productStockValue,
                              salePriceValue: salePriceValue,
                              exclusivePriceValue: exclusivePriceValue,
                              inclusivePriceValue: inclusivePriceValue,
                              vatAmountValue: vatAmountValue,
                              variantsList: variantsListForApi,
                              productTypeValue: productTypeValue,
                              sizeValue: sizeValue,
                              colorValue: colorValue,
                              weightValue: weightValue,
                              capacityValue: capacityValue,
                              typeValue: typeValue,
                              dealerPriceValue: dealerPriceValue,
                              discountValue: discountValue,
                              manufacturerValue: manufacturerValue,
                              wholeSalePriceValue: wholeSalePriceValue,
                              lowStockValue: lowStockValue,
                              gstBreakdown: gstBreakdown,
                              hsnCode: hsnCode,
                              productId: widget.productModel?.id?.toString(),
                            );
                            ProductRepo product = ProductRepo();
                            if (widget.productModel == null) {
                              print('=== ADD PRODUCT REQUEST BODY ===');
                              print(const JsonEncoder.withIndent('  ')
                                  .convert(debugPayload));
                              EasyLoading.show(
                                  status: lang.S.of(context).adding);
                              await product.addProduct(
                                ref: ref,
                                context: context,
                                productName: nameController.text,
                                categoryId:
                                    selectedCategory?.id.toString() ?? '',
                                brandId: selectedBrand?.id.toString(),
                                unitId: selectedUnit?.id.toString(),
                                productCode: productCodeController.text,
                                productStock: productStockValue,
                                productSalePrice: salePriceValue,
                                productPurchasePrice:
                                    selectedTaxType.toLowerCase() == 'exclusive'
                                        ? exclusivePriceValue
                                        : inclusivePriceValue,
                                exclusivePrice: exclusivePriceValue,
                                inclusivePrice: inclusivePriceValue,
                                color: colorValue,
                                size: sizeValue,
                                type: typeValue,
                                weight: weightValue,
                                capacity: capacityValue,
                                productDealerPrice: dealerPriceValue,
                                productDiscount: discountValue,
                                productManufacturer: manufacturerValue,
                                productWholeSalePrice: wholeSalePriceValue,
                                image: pickedImage == null
                                    ? null
                                    : File(pickedImage!.path),
                                vatId: selectedTax?.id.toString(),
                                vatType: selectedTaxType,
                                vatRate: selectedGstRate,
                                gstType: selectedGstType,
                                gstRate: gstBreakdown.gstRate,
                                cgstRate: gstBreakdown.cgstRate,
                                sgstRate: gstBreakdown.sgstRate,
                                igstRate: gstBreakdown.igstRate,
                                profitMargin: profitMarginController
                                            .text.isEmpty ||
                                        profitMarginController.text.trim() == ''
                                    ? '0'
                                    : profitMarginController.text,
                                vatAmount: vatAmountValue,
                                lowStock: lowStockValue,
                                expDate: selectedDate,
                                productType: productTypeValue,
                                variants: variantsListForApi,
                                hsnCode: hsnCode,
                              );
                              EasyLoading.dismiss();
                            } else {
                              print('=== ADD PRODUCT UPDATE DEBUG ===');
                              print('Product ID: ${widget.productModel?.id}');
                              print(
                                  'Stock Controller Value: "${productStockController.text}"');
                              print(
                                  'Stock Controller Empty: ${productStockController.text.isEmpty}');
                              print(
                                  'Stock Controller Length: ${productStockController.text.length}');
                              print(
                                  'Stock Controller Trimmed: "${productStockController.text.trim()}"');

                              String stockValue = productStockValue.trim();
                              if (stockValue.isEmpty) {
                                stockValue = '0';
                              }
                              print('Processed stock value: "$stockValue"');

                              EasyLoading.show(
                                  status: lang.S.of(context).updating);
                              print('=== UPDATE PRODUCT REQUEST BODY ===');
                              print(const JsonEncoder.withIndent('  ')
                                  .convert(debugPayload));
                              await product.updateProduct(
                                ref: ref,
                                context: context,
                                productId:
                                    widget.productModel?.id.toString() ?? '',
                                productName: nameController.text,
                                categoryId:
                                    selectedCategory?.id.toString() ?? '',
                                brandId: selectedBrand?.id.toString(),
                                unitId: selectedUnit?.id.toString(),
                                productStock: stockValue,
                                productCode: productCodeController.text,
                                productSalePrice: salePriceValue,
                                productPurchasePrice:
                                    selectedTaxType.toLowerCase() == 'exclusive'
                                        ? exclusivePriceValue
                                        : inclusivePriceValue,
                                exclusivePrice: exclusivePriceValue,
                                inclusivePrice: inclusivePriceValue,
                                color: colorValue,
                                size: sizeValue,
                                type: typeValue,
                                weight: weightValue,
                                capacity: capacityValue,
                                productDealerPrice: dealerPriceValue,
                                productDiscount: discountValue,
                                productManufacturer: manufacturerValue,
                                productWholeSalePrice: wholeSalePriceValue,
                                image: pickedImage == null
                                    ? null
                                    : File(pickedImage!.path),
                                vatId: selectedTax?.id.toString(),
                                vatType: selectedTaxType,
                                vatRate: selectedGstRate,
                                gstType: selectedGstType,
                                gstRate: gstBreakdown.gstRate,
                                cgstRate: gstBreakdown.cgstRate,
                                sgstRate: gstBreakdown.sgstRate,
                                igstRate: gstBreakdown.igstRate,
                                profitMargin: profitMarginController
                                            .text.isEmpty ||
                                        profitMarginController.text.trim() == ''
                                    ? '0'
                                    : profitMarginController.text,
                                vatAmount: vatAmountValue,
                                lowStock: lowStockValue,
                                expDate: selectedDate,
                                productType: productTypeValue,
                                variants: variantsListForApi,
                                hsnCode: hsnCode,
                              );
                              EasyLoading.dismiss();
                            }
                          } catch (e, stackTrace) {
                            EasyLoading.dismiss();
                            EasyLoading.showError("Something went wrong!");
                            debugPrint("Error: $e\nStackTrace: $stackTrace");
                          }
                        }
                      },
                      child: Text(lang.S.of(context).saveNPublish),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  bool readOnly = false,
  bool? icon,
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      decoration: kInputDecoration.copyWith(
        labelText: label,
        hintText: hint,
        suffixIcon: (icon ?? false)
            ? const Icon(Icons.keyboard_arrow_down_outlined)
            : null,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}


class VariantPricingSummary {
  final double totalStock;
  final double exclusivePrice;
  final double inclusivePrice;
  final double mrp;

  const VariantPricingSummary({
    this.totalStock = 0,
    this.exclusivePrice = 0,
    this.inclusivePrice = 0,
    this.mrp = 0,
  });

  String get totalStockString => _formatNumber(totalStock);
  String get exclusivePriceString => inclusivePrice == 0 && exclusivePrice == 0
      ? '0'
      : exclusivePrice.toStringAsFixed(2);
  String get inclusivePriceString => inclusivePrice.toStringAsFixed(2);
  String get mrpString => mrp.toStringAsFixed(2);

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class GstBreakdown {
  final String? gstRate;
  final String? cgstRate;
  final String? sgstRate;
  final String? igstRate;

  const GstBreakdown({
    this.gstRate,
    this.cgstRate,
    this.sgstRate,
    this.igstRate,
  });
}

class VariantFormData {
  VariantFormData()
      : sizeController = TextEditingController(),
        colorController = TextEditingController(),
        weightController = TextEditingController(),
        capacityController = TextEditingController(),
        typeController = TextEditingController(),
        purchasePriceController = TextEditingController(),
        mrpController = TextEditingController(),
        stockController = TextEditingController(),
        lowStockController = TextEditingController();

  final TextEditingController sizeController;
  final TextEditingController colorController;
  final TextEditingController weightController;
  final TextEditingController capacityController;
  final TextEditingController typeController;
  final TextEditingController purchasePriceController;
  final TextEditingController mrpController;
  final TextEditingController stockController;
  final TextEditingController lowStockController;

  Map<String, dynamic> toJson() {
    return {
      'size': sizeController.text.trim(),
      'color': colorController.text.trim(),
      'weight': weightController.text.trim(),
      'capacity': capacityController.text.trim(),
      'type': typeController.text.trim(),
      'purchase_price':
          double.tryParse(purchasePriceController.text.trim()) ?? 0,
      'mrp': double.tryParse(mrpController.text.trim()) ?? 0,
      'stock': int.tryParse(stockController.text.trim()) ?? 0,
      'low_stock': int.tryParse(lowStockController.text.trim()) ?? 0,
    };
  }

  String? validationMessage() {
    if (purchasePriceController.text.trim().isEmpty) {
      return 'Please enter a purchase price.';
    }
    if (double.tryParse(purchasePriceController.text.trim()) == null) {
      return 'Purchase price must be a number.';
    }
    if (mrpController.text.trim().isEmpty) {
      return 'Please enter an MRP.';
    }
    if (double.tryParse(mrpController.text.trim()) == null) {
      return 'MRP must be a number.';
    }
    if (stockController.text.trim().isEmpty) {
      return 'Please enter stock.';
    }
    if (int.tryParse(stockController.text.trim()) == null) {
      return 'Stock must be a whole number.';
    }
    return null;
  }

  void dispose() {
    sizeController.dispose();
    colorController.dispose();
    weightController.dispose();
    capacityController.dispose();
    typeController.dispose();
    purchasePriceController.dispose();
    mrpController.dispose();
    stockController.dispose();
    lowStockController.dispose();
  }
}
