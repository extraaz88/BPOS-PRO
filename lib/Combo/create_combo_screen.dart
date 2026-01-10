import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_pos/Combo/Model/combo_model.dart';
import 'package:mobile_pos/Combo/Repo/combo_repo.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/product_category/model/category_model.dart';
import 'package:mobile_pos/Screens/product_category/provider/product_category_provider/product_unit_provider.dart';
import 'package:mobile_pos/Screens/product_brand/model/brands_model.dart'
    as brand;
import 'package:mobile_pos/Screens/product_brand/product_brand_provider/product_brand_provider.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../Screens/Products/Model/product_model.dart';

class CreateComboScreen extends StatefulWidget {
  const CreateComboScreen({super.key, this.comboModel});

  final ComboModel? comboModel;

  @override
  State<CreateComboScreen> createState() => _CreateComboScreenState();
}

class _CreateComboScreenState extends State<CreateComboScreen> {
  final TextEditingController _comboNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountValueController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // New quantity controller and default combo quantity
  final TextEditingController _quantityController = TextEditingController(text: '1');
  num _comboQuantity = 1;

  XFile? _pickedImage;
  Map<String, int> _productQuantities = {};
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  CategoryModel? _selectedCategory;
  brand.Brand? _selectedBrand;
  String _selectedDiscountType = 'flat';

  List<CategoryModel> _availableCategories = [];
  List<brand.Brand> _availableBrands = [];

  num _subtotal = 0;
  num _discountValue = 0;
  num _finalPrice = 0;

  bool _isEditMode = false;
  bool _isProductsInitialized = false;
  bool _areCategoriesExtracted = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.comboModel != null;

    if (_isEditMode) {
      _comboNameController.text = widget.comboModel?.comboName ?? '';
      _selectedDiscountType = widget.comboModel?.discountType ?? 'flat';
      _discountValueController.text =
          (widget.comboModel?.discountValue ?? 0).toString();
      _discountValue = widget.comboModel?.discountValue ?? 0;
      _finalPrice = widget.comboModel?.finalPrice ?? 0;
      _subtotal = widget.comboModel?.subtotal ?? 0;
      // Note: if ComboModel has a quantity field, you can fill it here safely.
      // _quantityController.text = widget.comboModel?.quantity?.toString() ?? '1';
    }

    _discountValueController.addListener(_calculateFinalPrice);
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _comboNameController.dispose();
    _searchController.dispose();
    _discountValueController.dispose();
    _quantityController.dispose(); // dispose new controller
    super.dispose();
  }

  void _calculateFinalPrice() {
    final discountValue = num.tryParse(_discountValueController.text) ?? 0;
    _discountValue = discountValue;

    if (_selectedDiscountType == 'flat') {
      _finalPrice = _subtotal - discountValue;
    } else {
      _finalPrice = _subtotal - (_subtotal * discountValue / 100);
    }

    if (_finalPrice < 0) _finalPrice = 0;
    _finalPrice = _roundToTwo(_finalPrice);

    setState(() {});
  }

  void _extractCategoriesAndBrandsFromProducts(
    List<ProductModel> products,
    AsyncValue<List<CategoryModel>> categoriesData,
    AsyncValue<List<brand.Brand>> brandsData,
  ) {
    // Only extract once to prevent infinite rebuilds
    if (_areCategoriesExtracted) return;

    final categoryIds = products
        .where((p) => p.categoryId != null)
        .map((p) => p.categoryId)
        .toSet();

    categoriesData.whenData((allCategories) {
      if (mounted) {
        setState(() {
          _availableCategories =
              allCategories.where((cat) => categoryIds.contains(cat.id)).toList();
        });
      }
    });

    final brandIds =
        products.where((p) => p.brandId != null).map((p) => p.brandId).toSet();

    brandsData.whenData((allBrands) {
      if (mounted) {
        setState(() {
          _availableBrands =
              allBrands.where((br) => brandIds.contains(br.id)).toList();
          _areCategoriesExtracted = true;
        });
      }
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        if (product.productType?.toLowerCase() == 'combo') {
          return false;
        }

        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            (product.productName?.toLowerCase().contains(searchQuery) ?? false);

        final matchesCategory = _selectedCategory == null ||
            product.categoryId == _selectedCategory?.id;

        final matchesBrand =
            _selectedBrand == null || product.brandId == _selectedBrand?.id;

        return matchesSearch && matchesCategory && matchesBrand;
      }).toList();
    });
  }

  int _getProductQuantity(ProductModel product) {
    final productId = product.id?.toString() ?? '';
    return _productQuantities[productId] ?? 0;
  }

  void _increaseQuantity(ProductModel product) {
    setState(() {
      final currentQuantity = _getProductQuantity(product);
      final productId = product.id?.toString() ?? '';
      if (productId.isNotEmpty) {
        _productQuantities[productId] = currentQuantity + 1;
        _updateSubtotal();
      }
    });
  }

  void _decreaseQuantity(ProductModel product) {
    setState(() {
      final currentQuantity = _getProductQuantity(product);
      if (currentQuantity > 0) {
        final newQuantity = currentQuantity - 1;
        final productId = product.id?.toString() ?? '';
        if (productId.isNotEmpty) {
          if (newQuantity == 0) {
            _productQuantities.remove(productId);
          } else {
            _productQuantities[productId] = newQuantity;
          }
          _updateSubtotal();
        }
      }
    });
  }

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

  double _getPriceWithTax(ProductModel product) {
    final basePrice = (product.productSalePrice ?? 0).toDouble();
    final taxAmount = _calculateTaxAmount(product);
    final vatType = product.vatType?.toLowerCase().trim();

    if (vatType == 'inclusive') {
      // Price already includes tax
      return _roundToTwo(basePrice);
    }

    return _roundToTwo(basePrice + taxAmount);
  }

  void _updateSubtotal() {
    _subtotal = _productQuantities.entries.fold<double>(
      0.0,
      (sum, entry) {
        final productId = num.tryParse(entry.key);
        if (productId == null) return sum;

        final product = _allProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => _filteredProducts.firstWhere(
            (p) => p.id == productId,
          ),
        );
        final priceWithTax = _getPriceWithTax(product);
        return sum + (priceWithTax * entry.value);
      },
    );
    _subtotal = _roundToTwo(_subtotal);
    _calculateFinalPrice();
  }

  List<ProductModel> get _selectedProducts {
    return _productQuantities.keys
        .map((productIdStr) {
          final productId = num.tryParse(productIdStr);
          if (productId == null) return null;
          return _allProducts.firstWhere(
            (p) => p.id == productId,
            orElse: () => _filteredProducts.firstWhere(
              (p) => p.id == productId,
            ),
          );
        })
        .whereType<ProductModel>()
        .toList();
  }

  int get _totalItemsCount {
    return _productQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveCombo(WidgetRef ref) async {
    if (_comboNameController.text.isEmpty) {
      EasyLoading.showError('Please enter combo name');
      return;
    }

    if (_productQuantities.isEmpty) {
      EasyLoading.showError('Please select at least one product');
      return;
    }

    // Parse and validate combo quantity
    final parsedQty = num.tryParse(_quantityController.text) ?? 1;
    _comboQuantity = parsedQty <= 0 ? 1 : parsedQty;

    final comboRepo = ComboRepo();

    // API expects 'flat' and 'percent' (lowercase) - same as sales/purchase
    final apiDiscountType = _selectedDiscountType.toLowerCase();

    if (_isEditMode && widget.comboModel != null) {
      await comboRepo.updateCombo(
        ref: ref,
        context: context,
        comboId: widget.comboModel!.id!,
        comboName: _comboNameController.text,
        selectedProducts: _selectedProducts,
        productQuantities: _productQuantities,
        subtotal: _subtotal,
        discountType: apiDiscountType,
        discountValue: _discountValue,
        finalPrice: _finalPrice,
        comboQuantity: _comboQuantity, // changed parameter name
        image: _pickedImage != null ? File(_pickedImage!.path) : null,
      );
    } else {
      await comboRepo.createCombo(
        ref: ref,
        context: context,
        comboName: _comboNameController.text,
        selectedProducts: _selectedProducts,
        productQuantities: _productQuantities,
        subtotal: _subtotal,
        discountType: apiDiscountType,
        discountValue: _discountValue,
        finalPrice: _finalPrice,
        comboQuantity: _comboQuantity, // changed parameter name
        image: _pickedImage != null ? File(_pickedImage!.path) : null,
      );
    }
  }

  void _resetForm() {
    setState(() {
      _comboNameController.clear();
      _productQuantities.clear();
      _pickedImage = null;
      _discountValueController.clear();
      _selectedDiscountType = 'flat';
      _subtotal = 0;
      _discountValue = 0;
      _finalPrice = 0;
      _selectedCategory = null;
      _selectedBrand = null;
      _searchController.clear();
      _quantityController.clear(); // reset new controller
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: kWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            _isEditMode ? 'Edit Combo Kit' : 'Create Combo Kit',
            style: const TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          actions: [
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.black),
                onPressed: () {
                  // Save functionality
                },
              ),
          ],
        ),
        body: Consumer(
          builder: (context, ref, __) {
            final productsData = ref.watch(productProvider);
            final categoriesData = ref.watch(categoryProvider);
            final brandsData = ref.watch(brandsProvider);

            return productsData.when(
              data: (products) {
                // Initialize products only once
                if (!_isProductsInitialized) {
                  _allProducts = products.where((product) {
                    return product.productType?.toLowerCase() != 'combo';
                  }).toList();
                  _filteredProducts = _allProducts;
                  _isProductsInitialized = true;

                  // Initialize product quantities in edit mode only once
                  if (_isEditMode &&
                      widget.comboModel?.products != null &&
                      _productQuantities.isEmpty) {
                    for (var comboProduct in widget.comboModel!.products!) {
                      final productIdStr =
                          comboProduct.productId?.toString() ?? '';
                      if (productIdStr.isNotEmpty) {
                        _productQuantities[productIdStr] = 1;
                      }
                    }
                    _updateSubtotal();
                  }
                }

                // Extract categories and brands once
                _extractCategoriesAndBrandsFromProducts(
                    _allProducts, categoriesData, brandsData);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Combo Name
                        TextFormField(
                          controller: _comboNameController,
                          decoration: kInputDecoration.copyWith(
                            labelText: 'Combo Name',
                            hintText: 'Enter combo kit name',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter combo name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // NEW: Quantity Field
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: kInputDecoration.copyWith(
                            labelText: 'Quantity',
                            hintText: 'Enter combo quantity (default 1)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Combo Image
                        Text(
                          'Combo Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: kGreyTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: kGreyTextColor.withOpacity(0.3),
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _pickedImage != null ||
                                    (widget.comboModel?.comboImage != null &&
                                        _pickedImage == null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _pickedImage != null
                                        ? Image.file(
                                            File(_pickedImage!.path),
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            '${APIConfig.domain}${widget.comboModel?.comboImage}',
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return _buildImagePlaceholder();
                                            },
                                          ),
                                  )
                                : _buildImagePlaceholder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Search and Filters
                        TextFormField(
                          controller: _searchController,
                          decoration: kInputDecoration.copyWith(
                            labelText: 'Search Products',
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category and Brand Filters
                        Row(
                          children: [
                            Expanded(
                              child: categoriesData.when(
                                data: (categories) {
                                  final categoriesList =
                                      _availableCategories.isEmpty
                                          ? categories
                                          : _availableCategories;

                                  return DropdownButtonFormField<
                                      CategoryModel?>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    decoration: kInputDecoration.copyWith(
                                      labelText: 'All Categories',
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<CategoryModel?>(
                                        value: null,
                                        child: Text('All Categories'),
                                      ),
                                      ...categoriesList.map(
                                        (category) =>
                                            DropdownMenuItem<CategoryModel?>(
                                          value: category,
                                          child: SizedBox(
                                            width: 150,
                                            child: Text(
                                              category.categoryName ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                      _filterProducts();
                                    },
                                  );
                                },
                                loading: () =>
                                    DropdownButtonFormField<CategoryModel?>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  decoration: kInputDecoration.copyWith(
                                    labelText: 'Loading...',
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: const [],
                                  onChanged: null,
                                ),
                                error: (_, __) =>
                                    DropdownButtonFormField<CategoryModel?>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  decoration: kInputDecoration.copyWith(
                                    labelText: 'Error loading categories',
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: const [],
                                  onChanged: null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: brandsData.when(
                                data: (brands) {
                                  final brandsList = _availableBrands.isEmpty
                                      ? brands
                                      : _availableBrands;

                                  return DropdownButtonFormField<brand.Brand?>(
                                    value: _selectedBrand,
                                    isExpanded: true,
                                    decoration: kInputDecoration.copyWith(
                                      labelText: 'All Brands',
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<brand.Brand?>(
                                        value: null,
                                        child: Text('All Brands'),
                                      ),
                                      ...brandsList.map(
                                        (br) => DropdownMenuItem<brand.Brand?>(
                                          value: br,
                                          child: SizedBox(
                                            width: 150,
                                            child: Text(
                                              br.brandName ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedBrand = value;
                                      });
                                      _filterProducts();
                                    },
                                  );
                                },
                                loading: () =>
                                    DropdownButtonFormField<brand.Brand?>(
                                  value: _selectedBrand,
                                  isExpanded: true,
                                  decoration: kInputDecoration.copyWith(
                                    labelText: 'Loading...',
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: const [],
                                  onChanged: null,
                                ),
                                error: (_, __) =>
                                    DropdownButtonFormField<brand.Brand?>(
                                  value: _selectedBrand,
                                  isExpanded: true,
                                  decoration: kInputDecoration.copyWith(
                                    labelText: 'Error loading brands',
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: const [],
                                  onChanged: null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Select Products Section
                        Text(
                          'Select Products',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final quantity = _getProductQuantity(product);
                            return _buildProductCard(product, quantity);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Combo Summary
                        Text(
                          'Combo Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSummaryRow(
                          'Subtotal incl. tax (${_totalItemsCount} items)',
                          '$currency${_subtotal.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Discount',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDiscountType,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                isDense: true,
                                items: [
                                  DropdownMenuItem(
                                    value: 'flat',
                                    child: SizedBox(
                                      width: 60,
                                      child: Text(
                                        'Flat $currency',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'percent',
                                    child: SizedBox(
                                      width: 60,
                                      child: Text(
                                        'Per %',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDiscountType = value!;
                                  });
                                  _calculateFinalPrice();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _discountValueController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  hintText: '0.00',
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildSummaryRow(
                          'Final Price',
                          '$currency${_finalPrice.toStringAsFixed(2)}',
                          isFinalPrice: true,
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetForm,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: kMainColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Reset',
                                  style: TextStyle(
                                    color: kMainColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () => _saveCombo(ref),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMainColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Combo Kit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading products: $error'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 40,
          color: kGreyTextColor,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload image',
          style: TextStyle(
            color: kGreyTextColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product, int quantity) {
    final isSelected = quantity > 0;
    final priceWithTax = _getPriceWithTax(product);
    final basePrice = _roundToTwo(product.productSalePrice ?? 0);
    final taxAmount = _calculateTaxAmount(product);
    final vatType = product.vatType?.toLowerCase().trim();
    final hasTax = taxAmount > 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: kMainColor, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: product.productPicture != null
                  ? Image.network(
                      '${APIConfig.domain}${product.productPicture}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: kGreyTextColor.withOpacity(0.1),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            color: kGreyTextColor,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: kGreyTextColor.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image,
                        color: kGreyTextColor,
                      ),
                    ),
            ),
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency${priceWithTax.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kMainColor,
                  ),
                ),
                if (hasTax)
                  Text(
                    vatType == 'inclusive'
                        ? 'Tax included: $currency${taxAmount.toStringAsFixed(2)}'
                        : 'Base: $currency${basePrice.toStringAsFixed(2)} + Tax: $currency${taxAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: kGreyTextColor,
                    ),
                  ),
                const SizedBox(height: 8),
                // Quantity Controls or Add Button
                isSelected
                    ? Row(
                        children: [
                          Expanded(
                            child: IconButton(
                              onPressed: () => _decreaseQuantity(product),
                              icon: const Icon(Icons.remove),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: IconButton(
                              onPressed: () => _increaseQuantity(product),
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: kMainColor.withOpacity(0.2),
                                foregroundColor: kMainColor,
                                padding: const EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _increaseQuantity(product),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isFinalPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: isFinalPrice ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: isFinalPrice ? kMainColor : Colors.black87,
            fontWeight: isFinalPrice ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}