import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Const/api_config.dart';
import '../../GlobalComponents/bar_code_scaner_widget.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/add_to_cart.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';
import '../Products/Model/product_model.dart';

class _VariantResolutionResult {
  const _VariantResolutionResult({
    required this.variants,
    required this.stockMap,
  });

  final List<ProductVariant> variants;
  final Map<ProductVariant, StockModel> stockMap;
}

class SaleProductsList extends StatefulWidget {
  const SaleProductsList({super.key, this.customerModel});

  final Party? customerModel;

  @override
  // ignore: library_private_types_in_public_api
  _SaleProductsListState createState() => _SaleProductsListState();
}

class _SaleProductsListState extends State<SaleProductsList> {
  // String dropdownValue = '';
  String productCode = '0000';
  TextEditingController codeController = TextEditingController();
  num productPrice = 0;
  String sentProductPrice = '';

  // Multiple selection variables
  Map<int, int> selectedProducts = {}; // productId -> quantity
  bool _restrictZeroStockTransactions = false;

  @override
  void initState() {
    // widget.catName == null ? dropdownValue = 'Fashion' : dropdownValue = widget.catName;
    super.initState();
    _loadZeroStockRestriction();
  }

  Future<void> _loadZeroStockRestriction() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _restrictZeroStockTransactions =
          prefs.getBool(kZeroStockRestrictionKey) ?? false;
    });
  }

  // Method to show quantity input dialog for updating product
  void _showUpdateProductDialog(BuildContext context, ProductModel product,
      CartNotifier providerData, int currentQuantity) {
    TextEditingController quantityController =
        TextEditingController(text: currentQuantity.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update ${product.productName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Available Stock: ${product.productStock ?? 0}${product.unit?.unitName != null && product.unit!.unitName!.isNotEmpty ? ' (${product.unit!.unitName})' : ''}'),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                int quantity = int.tryParse(quantityController.text) ?? 1;
                final availableStock = (product.productStock ?? 0).toInt();
                final allowOversell =
                    !_restrictZeroStockTransactions || availableStock == 0;
                if (quantity > 0 &&
                    (allowOversell || quantity <= availableStock)) {
                  await _updateProductQuantity(
                      (product.id ?? 0).toInt(),
                      quantity,
                      (product.productStock ?? 0).toInt(),
                      product,
                      providerData);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  EasyLoading.showError('Invalid quantity or out of stock');
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Method to add product to cart with specified quantity
  Future<bool> _addProductToCart(
      ProductModel product, int quantity, CartNotifier providerData) async {
    if (_restrictZeroStockTransactions &&
        (product.productStock ?? 0) <= 0 &&
        !(product.variants?.isNotEmpty ?? false)) {
      EasyLoading.showError(
        '${product.productName ?? 'This product'} is out of stock and cannot be added to the sale.',
        duration: const Duration(seconds: 2),
      );
      return false;
    }

    String sentProductPrice;
    if (widget.customerModel != null && widget.customerModel!.type != null) {
      if (widget.customerModel!.type!.contains('Retailer')) {
        sentProductPrice = product.productSalePrice.toString();
      } else if (widget.customerModel!.type!.contains('Dealer')) {
        sentProductPrice = product.productDealerPrice.toString();
      } else if (widget.customerModel!.type!.contains('Wholesaler')) {
        sentProductPrice = product.productWholeSalePrice.toString();
      } else if (widget.customerModel!.type!.contains('Supplier')) {
        sentProductPrice = product.productPurchasePrice.toString();
      } else {
        sentProductPrice = product.productSalePrice.toString();
      }
    } else {
      sentProductPrice = product.productSalePrice.toString();
    }

    // Validate price is not zero
    num priceValue = num.tryParse(sentProductPrice) ?? 0;
    if (priceValue <= 0) {
      EasyLoading.showError(
        'Cannot add product with zero or negative price!\nPlease update the product price first.',
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    // Check for low stock and show warning
    num alertQty = product.alertQty ?? 0;
    num currentStock = product.productStock ?? 0;
    bool isLowStock = (currentStock <= alertQty) && alertQty > 0;

    if (_restrictZeroStockTransactions && isLowStock) {
      final added = await _showLowStockWarningDialog(
          product, quantity, providerData, sentProductPrice);
      return added;
    }

    AddToCartModel cartItem = AddToCartModel(
      productName: product.productName,
      unitPrice: sentProductPrice,
      productCode: product.productCode,
      productPurchasePrice: product.productPurchasePrice,
      stock: (product.productStock ?? 0),
      productId: product.id ?? 0,
      quantity: quantity,
      stockId: product.getFirstStockId(),
      gstRateSelect: product.gstRateSelect,
      gstType: product.gstType,
      vatType: product.vatType,
      unitName: product.unit?.unitName,
    );

    // Use the new bulk quantity method
    providerData.addToCartWithBulkQuantity(
        cartItem: cartItem, quantity: quantity, fromEditSales: false);
    return true;
  }

  // Method to show low stock warning dialog
  Future<bool> _showLowStockWarningDialog(ProductModel product, int quantity,
      CartNotifier providerData, String sentProductPrice) async {
    num alertQty = product.alertQty ?? 0;
    num currentStock = product.productStock ?? 0;

    final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('Low Stock Warning'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This product is running low on stock:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product: ${product.productName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Current Stock: ${currentStock.toInt()}'),
                        Text('Alert Quantity: ${alertQty.toInt()}'),
                        Text('Quantity to Add: $quantity'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Do you want to proceed with adding this product to cart?',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldProceed) {
      AddToCartModel cartItem = AddToCartModel(
        productName: product.productName,
        unitPrice: sentProductPrice,
        productCode: product.productCode,
        productPurchasePrice: product.productPurchasePrice,
        stock: (product.productStock ?? 0),
        productId: product.id ?? 0,
        quantity: quantity,
        stockId: product.getFirstStockId(),
        gstRateSelect: product.gstRateSelect,
        gstType: product.gstType,
        vatType: product.vatType,
        unitName: product.unit?.unitName,
      );

      providerData.addToCartWithBulkQuantity(
          cartItem: cartItem, quantity: quantity, fromEditSales: false);
    }

    return shouldProceed;
  }

  // Method to add/remove product from cart directly
  Future<void> _toggleProductSelection(int productId, int stock,
      ProductModel product, CartNotifier providerData) async {
    if (selectedProducts.containsKey(productId)) {
      // Remove from cart
      setState(() {
        selectedProducts.remove(productId);
        // Also remove from actual cart
        providerData.cartItemList
            .removeWhere((item) => item.productId == productId);
        providerData.calculatePrice();
      });
    } else {
      // Check price before adding
      String sentProductPrice;
      if (widget.customerModel != null && widget.customerModel!.type != null) {
        if (widget.customerModel!.type!.contains('Retailer')) {
          sentProductPrice = product.productSalePrice.toString();
        } else if (widget.customerModel!.type!.contains('Dealer')) {
          sentProductPrice = product.productDealerPrice.toString();
        } else if (widget.customerModel!.type!.contains('Wholesaler')) {
          sentProductPrice = product.productWholeSalePrice.toString();
        } else if (widget.customerModel!.type!.contains('Supplier')) {
          sentProductPrice = product.productPurchasePrice.toString();
        } else {
          sentProductPrice = product.productSalePrice.toString();
        }
      } else {
        sentProductPrice = product.productSalePrice.toString();
      }

      num priceValue = num.tryParse(sentProductPrice) ?? 0;
      if (priceValue <= 0) {
        EasyLoading.showError(
          'Cannot add product with zero or negative price!\nPlease update the product price first.',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Add to cart with default quantity 1
      final added = await _addProductToCart(product, 1, providerData);
      if (!mounted) return;
      if (added) {
        setState(() {
          selectedProducts[productId] = 1;
        });
      }
    }
  }

  // Method to update quantity for selected product
  Future<void> _updateProductQuantity(int productId, int quantity, int stock,
      ProductModel product, CartNotifier providerData) async {
    final allowOversell = !_restrictZeroStockTransactions ||
        (stock <= 0 && product.productStock != null);
    if (quantity > 0 && (allowOversell || quantity <= stock)) {
      final added = await _addProductToCart(product, quantity, providerData);
      if (!mounted) return;
      if (added) {
        setState(() {
          selectedProducts[productId] = quantity;
        });
      }
    }
  }

  bool _hasVariants(ProductModel product) {
    final isVariantType =
        (product.productType ?? '').trim().toLowerCase() == 'variant';
    if (!isVariantType) return false;

    if (product.variants?.isNotEmpty ?? false) {
      return true;
    }

    return product.stocks?.isNotEmpty ?? false;
  }

  _VariantResolutionResult _resolveProductVariants(ProductModel product) {
    final directVariants = product.variants;
    if (directVariants != null && directVariants.isNotEmpty) {
      return _VariantResolutionResult(
        variants: List<ProductVariant>.from(directVariants),
        stockMap: <ProductVariant, StockModel>{},
      );
    }

    final stocks = product.stocks;
    if (stocks == null || stocks.isEmpty) {
      return _VariantResolutionResult(
        variants: <ProductVariant>[],
        stockMap: <ProductVariant, StockModel>{},
      );
    }

    final generatedVariants = <ProductVariant>[];
    final generatedMap = <ProductVariant, StockModel>{};

    for (final stock in stocks) {
      final variant = _variantFromStock(product, stock);
      generatedVariants.add(variant);
      generatedMap[variant] = stock;
    }

    return _VariantResolutionResult(
      variants: generatedVariants,
      stockMap: generatedMap,
    );
  }

  ProductVariant _variantFromStock(ProductModel product, StockModel stock) {
    final parsedAttributes = _parseAttributesFromBatchNo(stock.batchNo);

    return ProductVariant(
      id: stock.id,
      size: parsedAttributes['Size'] ?? product.size,
      color: parsedAttributes['Color'] ?? product.color,
      weight: parsedAttributes['Weight'] ?? product.weight,
      capacity: parsedAttributes['Capacity'] ?? product.capacity,
      type: parsedAttributes['Type'] ?? product.type,
      purchasePrice: stock.productPurchasePrice,
      mrp: stock.productSalePrice,
      stock: stock.productStock,
      lowStock: stock.lowStock,
    );
  }

  Map<String, String> _parseAttributesFromBatchNo(String? batchNo) {
    final attributes = <String, String>{};
    if (batchNo == null || batchNo.trim().isEmpty) {
      return attributes;
    }

    final parts = batchNo.split('|');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final separatorIndex = trimmed.indexOf(':');
      if (separatorIndex == -1) continue;
      final key = trimmed.substring(0, separatorIndex).trim();
      final value = trimmed.substring(separatorIndex + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      attributes[key] = value;
    }

    return attributes;
  }

  String _buildVariantKey(ProductModel product, ProductVariant variant) {
    final parts = <String>[
      product.id?.toString() ?? '',
      variant.id?.toString() ?? '',
      variant.size ?? product.size ?? '',
      variant.weight ?? product.weight ?? '',
      variant.color ?? product.color ?? '',
      variant.capacity ?? product.capacity ?? '',
      variant.type ?? product.type ?? '',
    ];
    return parts.where((part) => part.trim().isNotEmpty).join('|');
  }

  String _buildVariantLabel(
    ProductModel product,
    ProductVariant variant, {
    StockModel? stock,
  }) {
    final attributes =
        _collectAttributes(product, variant, stock: stock).entries.toList();

    if (attributes.isEmpty) return '';

    return attributes
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' | ');
  }

  Map<String, String> _collectAttributes(
    ProductModel product,
    ProductVariant? variant, {
    StockModel? stock,
  }) {
    final attributes = <String, String>{};

    if (stock?.batchNo != null) {
      attributes.addAll(_parseAttributesFromBatchNo(stock!.batchNo));
    }

    void addAttribute(String key, String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      attributes.putIfAbsent(key, () => trimmed);
    }

    addAttribute('Size', variant?.size ?? product.size);
    addAttribute('Color', variant?.color ?? product.color);
    addAttribute('Weight', variant?.weight ?? product.weight);
    addAttribute('Capacity', variant?.capacity ?? product.capacity);
    addAttribute('Type', variant?.type ?? product.type);

    return attributes;
  }

  Future<bool> _addVariantToCart({
    required BuildContext sheetContext,
    required ProductModel product,
    required ProductVariant variant,
    StockModel? stockModel,
    required int quantity,
    required CartNotifier providerData,
    bool showSuccess = true,
  }) async {
    String sentProductPrice;
    final baseSalePrice = (stockModel?.productSalePrice ??
            variant.mrp ??
            product.productSalePrice ??
            0)
        .toDouble();
    final variantLabel =
        _buildVariantLabel(product, variant, stock: stockModel);

    if (widget.customerModel != null && widget.customerModel!.type != null) {
      final customerType = widget.customerModel!.type!;
      if (customerType.contains('Retailer')) {
        sentProductPrice = baseSalePrice.toString();
      } else if (customerType.contains('Dealer')) {
        sentProductPrice =
            (product.productDealerPrice ?? baseSalePrice).toString();
      } else if (customerType.contains('Wholesaler')) {
        sentProductPrice =
            (product.productWholeSalePrice ?? baseSalePrice).toString();
      } else if (customerType.contains('Supplier')) {
        sentProductPrice = (variant.purchasePrice ??
                stockModel?.productPurchasePrice ??
                product.productPurchasePrice ??
                0)
            .toString();
      } else {
        sentProductPrice = baseSalePrice.toString();
      }
    } else {
      sentProductPrice = baseSalePrice.toString();
    }

    num priceValue = num.tryParse(sentProductPrice) ?? 0;
    if (priceValue <= 0) {
      EasyLoading.showError(
        'Cannot add product with zero or negative price!\nPlease update the product price first.',
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    final currentStock =
        (stockModel?.productStock ?? variant.stock ?? product.productStock ?? 0)
            .toInt()
            .clamp(0, 999999);
    final alertQty =
        (stockModel?.lowStock ?? variant.lowStock ?? product.alertQty ?? 0)
            .toInt()
            .clamp(0, 999999);

    if (_restrictZeroStockTransactions && currentStock <= 0) {
      EasyLoading.showError(
        '${product.productName ?? 'This variant'} is out of stock and cannot be added to the sale.',
        duration: const Duration(seconds: 2),
      );
      return false;
    }

    if (currentStock > 0 && quantity > currentStock) {
      EasyLoading.showError(
          'Available stock is $currentStock. Reduce quantity to continue.');
      return false;
    }

    Future<void> proceed() async {
      final cartItem = AddToCartModel(
        productId: product.id ?? 0,
        productCode: product.productCode,
        productName: variantLabel.isNotEmpty
            ? '${product.productName ?? ''} ($variantLabel)'
            : product.productName,
        unitPrice: sentProductPrice,
        productPurchasePrice: variant.purchasePrice ??
            stockModel?.productPurchasePrice ??
            product.productPurchasePrice,
        stock: currentStock,
        quantity: quantity,
        stockId: stockModel?.id ?? product.getFirstStockId(),
        gstRateSelect: product.gstRateSelect,
        gstType: product.gstType,
        vatType: product.vatType,
        unitName: product.unit?.unitName,
        productDetails: _collectAttributes(product, variant, stock: stockModel),
        variantKey: _buildVariantKey(product, variant),
        variantLabel: variantLabel,
      );

      providerData.addToCartWithBulkQuantity(
          cartItem: cartItem, quantity: quantity, fromEditSales: false);
      if (showSuccess) {
        EasyLoading.showSuccess('Variant added to cart!');
      }
    }

    if (_restrictZeroStockTransactions &&
        (currentStock <= alertQty) &&
        alertQty > 0) {
      final shouldProceed = await showDialog<bool>(
            context: sheetContext,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Low Stock Warning'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product: ${product.productName ?? ''}'),
                  const SizedBox(height: 8),
                  if (variantLabel.isNotEmpty)
                    Text(
                      variantLabel,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 8),
                  Text('Current Stock: $currentStock'),
                  Text('Alert Quantity: $alertQty'),
                  Text('Quantity to Add: $quantity'),
                  const SizedBox(height: 12),
                  const Text('Do you want to proceed?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Add'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldProceed) {
        return false;
      }
    }

    await proceed();
    return true;
  }

  void _showVariantSelectionSheet(
      ProductModel product, CartNotifier providerData) {
    final variantResolution = _resolveProductVariants(product);
    final variants = variantResolution.variants;
    if (variants.isEmpty) {
      EasyLoading.showInfo('No variants available for this product.');
      return;
    }

    final rootContext = context;
    final Map<ProductVariant, int> selectedVariants = {};

    ProductVariant? defaultVariant;
    for (final variant in variants) {
      final stock = variantResolution.stockMap[variant];
      final availableStock =
          (stock?.productStock ?? variant.stock ?? product.productStock ?? 0)
              .toInt();
      if (!_restrictZeroStockTransactions || availableStock > 0) {
        defaultVariant = variant;
        break;
      }
    }
    final ProductVariant initialVariant = defaultVariant ?? variants.first;
    selectedVariants[initialVariant] = 1;
    ProductVariant? focusedVariant = initialVariant;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          ProductVariant? displayVariant = focusedVariant;
          if (displayVariant == null && selectedVariants.isNotEmpty) {
            displayVariant = selectedVariants.keys.first;
          }
          final displayStock = displayVariant != null
              ? variantResolution.stockMap[displayVariant]
              : null;
          final attributeEntries =
              _collectAttributes(product, displayVariant, stock: displayStock)
                  .entries
                  .toList();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product.productName ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (product.brand?.brandName != null)
                        Text(product.brand!.brandName!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      if (attributeEntries.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product Details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            ...attributeEntries.map(
                              (entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    Text(entry.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      Text(
                        'Select Variant(s)',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...variants.map((variant) {
                        final stock = variantResolution.stockMap[variant];
                        final variantAttributes =
                            _collectAttributes(product, variant, stock: stock);
                        final availableStock = (stock?.productStock ??
                                variant.stock ??
                                product.productStock ??
                                0)
                            .toInt();
                        final mrp = stock?.productSalePrice ??
                            variant.mrp ??
                            product.productSalePrice ??
                            0;
                        final isSelected =
                            selectedVariants.containsKey(variant);
                        final quantity = selectedVariants[variant] ?? 1;
                        final isFocused = identical(focusedVariant, variant);

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              focusedVariant = variant;
                              if (!isSelected) {
                                if (_restrictZeroStockTransactions &&
                                    availableStock <= 0) {
                                  EasyLoading.showError(
                                    '${product.productName ?? 'This variant'} is out of stock and cannot be selected.',
                                    duration: const Duration(seconds: 2),
                                  );
                                  return;
                                }
                                selectedVariants[variant] =
                                    availableStock > 0 &&
                                            quantity > availableStock
                                        ? availableStock
                                        : (quantity <= 0 ? 1 : quantity);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isFocused || isSelected
                                      ? kMainColor
                                      : Colors.grey.shade300,
                                  width: (isFocused || isSelected) ? 1.5 : 1),
                              color: isSelected
                                  ? kMainColor.withOpacity(0.08)
                                  : Colors.white,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (checked) {
                                    if (checked == true) {
                                      if (_restrictZeroStockTransactions &&
                                          availableStock <= 0) {
                                        EasyLoading.showError(
                                          '${product.productName ?? 'This variant'} is out of stock and cannot be selected.',
                                          duration: const Duration(seconds: 2),
                                        );
                                        return;
                                      }
                                      setModalState(() {
                                        focusedVariant = variant;
                                        final desiredQuantity =
                                            quantity <= 0 ? 1 : quantity;
                                        final clampedQuantity =
                                            (availableStock > 0 &&
                                                    desiredQuantity >
                                                        availableStock)
                                                ? availableStock
                                                : desiredQuantity;
                                        selectedVariants[variant] =
                                            clampedQuantity > 0
                                                ? clampedQuantity
                                                : 1;
                                      });
                                    } else {
                                      setModalState(() {
                                        selectedVariants.remove(variant);
                                        if (identical(
                                            focusedVariant, variant)) {
                                          focusedVariant =
                                              selectedVariants.keys.isNotEmpty
                                                  ? selectedVariants.keys.first
                                                  : null;
                                        }
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (variantAttributes.isNotEmpty)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: variantAttributes.entries
                                              .map(
                                                (entry) => Chip(
                                                  label: Text(
                                                    '${entry.key}: ${entry.value}',
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      if (availableStock > 0)
                                        if (availableStock > 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              'Stock: $availableStock',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'MRP: $currency$mrp',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (isSelected)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: quantity > 1
                                                    ? () => setModalState(() {
                                                          selectedVariants[
                                                                  variant] =
                                                              quantity - 1;
                                                          focusedVariant =
                                                              variant;
                                                        })
                                                    : null,
                                                icon: const Icon(Icons
                                                    .remove_circle_outline),
                                              ),
                                              Text(
                                                quantity.toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  if (_restrictZeroStockTransactions &&
                                                      availableStock <= 0) {
                                                    EasyLoading.showError(
                                                      'Out of stock – cannot add more.',
                                                      duration: const Duration(
                                                          seconds: 2),
                                                    );
                                                    return;
                                                  }
                                                  if (availableStock == 0 ||
                                                      quantity <
                                                          availableStock) {
                                                    setModalState(() {
                                                      selectedVariants[
                                                              variant] =
                                                          quantity + 1;
                                                      focusedVariant = variant;
                                                    });
                                                  }
                                                },
                                                icon: const Icon(
                                                    Icons.add_circle_outline),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: selectedVariants.isEmpty
                              ? null
                              : () async {
                                  bool addedAny = false;
                                  for (final entry
                                      in selectedVariants.entries) {
                                    final variant = entry.key;
                                    final qty = entry.value;
                                    if (qty <= 0) continue;
                                    final stock =
                                        variantResolution.stockMap[variant];
                                    final success = await _addVariantToCart(
                                      sheetContext: sheetContext,
                                      product: product,
                                      variant: variant,
                                      stockModel: stock,
                                      quantity: qty,
                                      providerData: providerData,
                                      showSuccess: false,
                                    );
                                    addedAny = addedAny || success;
                                  }

                                  if (addedAny) {
                                    EasyLoading.showSuccess(
                                        'Selected variants added to cart!');
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                    if (Navigator.canPop(rootContext)) {
                                      Navigator.pop(rootContext);
                                    }
                                  } else {
                                    EasyLoading.showError(
                                      'Unable to add selected variants. Please check stock and try again.',
                                    );
                                  }
                                },
                          child: const Text('Add Selected Variants'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Consumer(builder: (context, ref, __) {
        final providerData = ref.watch(cartNotifier);
        final productList = ref.watch(productProvider);

        return Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(
              lang.S.of(context).addItems,
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: AppTextField(
                            controller: codeController,
                            textFieldType: TextFieldType.NAME,
                            onChanged: (value) {
                              setState(() {
                                productCode = value;
                              });
                            },
                            decoration: InputDecoration(
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              labelText: lang.S.of(context).productCode,
                              hintText:
                                  productCode == '0000' || productCode == '-1'
                                      ? 'Scan product QR code'
                                      : productCode,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (context) => BarcodeScannerWidget(
                                onBarcodeFound: (String code) {
                                  setState(() {
                                    productCode = code;
                                    codeController.text = productCode;
                                  });
                                },
                              ),
                            );
                          },
                          child: const BarCodeButton(),
                        ),
                      ),
                    ],
                  ),
                  productList.when(data: (products) {
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          if (widget.customerModel != null &&
                              widget.customerModel!.type != null) {
                            if (widget.customerModel!.type!
                                .contains('Retailer')) {
                              productPrice = products[i].productSalePrice ?? 0;
                            } else if (widget.customerModel!.type!
                                .contains('Dealer')) {
                              productPrice =
                                  products[i].productDealerPrice ?? 0;
                            } else if (widget.customerModel!.type!
                                .contains('Wholesaler')) {
                              productPrice =
                                  products[i].productWholeSalePrice ?? 0;
                            } else if (widget.customerModel!.type!
                                .contains('Supplier')) {
                              productPrice =
                                  products[i].productPurchasePrice ?? 0;
                            } else if (widget.customerModel!.type!
                                .contains('Guest')) {
                              productPrice = products[i].productSalePrice ?? 0;
                            }
                          } else {
                            productPrice = products[i].productSalePrice ?? 0;
                          }

                          return ProductCard(
                            productTitle: products[i].productName.toString(),
                            productDescription:
                                products[i].brand?.brandName ?? '',
                            productPrice: productPrice,
                            productImage: products[i].productPicture,
                            stock: products[i].productStock ?? 0,
                            isSelected:
                                selectedProducts.containsKey(products[i].id),
                            selectedQuantity:
                                selectedProducts[products[i].id] ?? 1,
                            onSelectionChanged: (selected) async {
                              if (_hasVariants(products[i])) {
                                _showVariantSelectionSheet(
                                    products[i], providerData);
                                return;
                              }
                              if (_restrictZeroStockTransactions &&
                                  (products[i].productStock ?? 0) <= 0) {
                                EasyLoading.showError('Out of stock');
                                return;
                              }
                              await _toggleProductSelection(
                                  (products[i].id ?? 0).toInt(),
                                  (products[i].productStock ?? 0).toInt(),
                                  products[i],
                                  providerData);
                            },
                            onQuantityChanged: (quantity) async {
                              await _updateProductQuantity(
                                  (products[i].id ?? 0).toInt(),
                                  quantity,
                                  (products[i].productStock ?? 0).toInt(),
                                  products[i],
                                  providerData);
                            },
                            product: products[i],
                            providerData: providerData,
                            onShowUpdateDialog: _showUpdateProductDialog,
                          ).visible((products[i].productCode == productCode ||
                                      productCode == '0000' ||
                                      productCode == '-1') &&
                                  productPrice != '0' ||
                              products[i]
                                  .productName!
                                  .toLowerCase()
                                  .contains(productCode.toLowerCase()));
                        });
                  }, error: (e, stack) {
                    return Text(e.toString());
                  }, loading: () {
                    return const Center(child: CircularProgressIndicator());
                  }),
                ],
              ),
            ),
          ),
          floatingActionButton: selectedProducts.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pop(context);
                    EasyLoading.showSuccess(
                        '${selectedProducts.length} items added to cart!');
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('Add ${selectedProducts.length} Items'),
                  backgroundColor: kMainColor,
                )
              : null,
        );
      }),
    );
  }
}

// ignore: must_be_immutable
class ProductCard extends StatefulWidget {
  ProductCard(
      {Key? key,
      required this.productTitle,
      required this.productDescription,
      required this.productPrice,
      required this.productImage,
      required this.stock,
      this.isSelected = false,
      this.selectedQuantity = 1,
      this.onSelectionChanged,
      this.onQuantityChanged,
      this.product,
      this.providerData,
      this.onShowUpdateDialog})
      : super(key: key);

  // final Product product;
  String productTitle, productDescription;
  num productPrice, stock;
  String? productImage;
  bool isSelected;
  int selectedQuantity;
  Function(bool)? onSelectionChanged;
  Function(int)? onQuantityChanged;
  ProductModel? product;
  CartNotifier? providerData;
  Function(BuildContext, ProductModel, CartNotifier, int)? onShowUpdateDialog;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  num quantity = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(cartNotifier);
      for (var element in providerData.cartItemList) {
        if (element.productName == widget.productTitle) {
          quantity = element.quantity;
        }
      }

      bool isZeroPrice = widget.productPrice <= 0;
      bool isLowStock = false;
      num alertQty = 0;
      final hasVariants = widget.product != null &&
          (widget.product!.productType?.toLowerCase() == 'variant') &&
          (widget.product!.variants?.isNotEmpty ?? false);

      // Check if product has low stock
      if (widget.product != null) {
        alertQty = widget.product!.alertQty ?? 0;
        isLowStock = (widget.stock <= alertQty) && alertQty > 0;
      }

      return Opacity(
        opacity: isZeroPrice ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: () {
            if (!isZeroPrice) {
              widget.onSelectionChanged?.call(!widget.isSelected);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              border: widget.isSelected
                  ? Border.all(color: kMainColor, width: 2)
                  : isZeroPrice
                      ? Border.all(color: Colors.red.shade300, width: 1)
                      : isLowStock
                          ? Border.all(color: Colors.orange.shade300, width: 1)
                          : Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: isZeroPrice
                  ? Colors.grey.shade100
                  : widget.isSelected
                      ? kMainColor.withOpacity(0.1)
                      : isLowStock
                          ? Colors.orange.withOpacity(0.05)
                          : Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        // Product image
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: widget.productImage == null
                                ? BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(noProductImageUrl),
                                        fit: BoxFit.cover),
                                    borderRadius: BorderRadius.circular(90.0),
                                  )
                                : BoxDecoration(
                                    image: DecorationImage(
                                        image: NetworkImage(
                                            "${APIConfig.domain}${widget.productImage}"),
                                        fit: BoxFit.cover),
                                    borderRadius: BorderRadius.circular(90.0),
                                  ),
                          ),
                        ),

                        // Product details
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.productTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  '${lang.S.of(context).stocks}${widget.stock}${widget.product?.unit?.unitName != null && widget.product!.unit!.unitName!.isNotEmpty ? ' (${widget.product!.unit!.unitName})' : ''}',
                                  style: TextStyle(
                                    color:
                                        isLowStock ? Colors.orange[800] : null,
                                    fontWeight:
                                        isLowStock ? FontWeight.bold : null,
                                  ),
                                ),
                                if (isLowStock)
                                  Container(
                                    margin: EdgeInsets.only(top: 4),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color:
                                              Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          size: 12,
                                          color: Colors.orange[800],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Low Stock (Alert: ${alertQty.toInt()})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange[800],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  widget.productDescription,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                if (hasVariants)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kMainColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.style,
                                            size: 14, color: kMainColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Variants available',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: kMainColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Quantity controls
                                if (widget.isSelected)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon:
                                            const Icon(Icons.remove, size: 16),
                                        onPressed: widget.selectedQuantity > 1
                                            ? () => widget.onQuantityChanged
                                                ?.call(
                                                    widget.selectedQuantity - 1)
                                            : null,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (widget.product != null &&
                                              widget.providerData != null &&
                                              widget.onShowUpdateDialog !=
                                                  null) {
                                            widget.onShowUpdateDialog!(
                                                context,
                                                widget.product!,
                                                widget.providerData!,
                                                widget.selectedQuantity);
                                          }
                                        },
                                        child: Text(
                                            'Qty: ${widget.selectedQuantity}'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: widget.selectedQuantity <
                                                widget.stock
                                            ? () => widget.onQuantityChanged
                                                ?.call(
                                                    widget.selectedQuantity + 1)
                                            : null,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$currency${widget.productPrice}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isZeroPrice ? Colors.red : null,
                        ),
                      ),
                      if (isZeroPrice)
                        Text(
                          'Price not set',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
