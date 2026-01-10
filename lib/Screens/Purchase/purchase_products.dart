import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/Screens/Purchase/Repo/purchase_repo.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../GlobalComponents/bar_code_scaner_widget.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/add_to_cart_purchase.dart';
import '../../core/theme/_app_colors.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../Products/Model/product_model.dart';
import '../../currency.dart';

class _VariantResolutionResult {
  const _VariantResolutionResult({
    required this.variants,
    required this.stockMap,
  });

  final List<ProductVariant> variants;
  final Map<ProductVariant, StockModel> stockMap;
}

class PurchaseProducts extends StatefulWidget {
  PurchaseProducts({super.key, this.supplierModel, this.selectedTaxType});

  final Party? supplierModel;
  final String? selectedTaxType;

  @override
  State<PurchaseProducts> createState() => _PurchaseProductsState();
}

class _PurchaseProductsState extends State<PurchaseProducts> {
  String productCode = '0000';
  TextEditingController codeController = TextEditingController();
  bool _restrictZeroStockTransactions = false;

  @override
  void initState() {
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
    required WidgetRef ref,
    bool showSuccess = true,
  }) async {
    final basePurchasePrice = (stockModel?.productPurchasePrice ??
            variant.purchasePrice ??
            product.productPurchasePrice ??
            0)
        .toDouble();
    final variantLabel =
        _buildVariantLabel(product, variant, stock: stockModel);

    num priceValue = basePurchasePrice;
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

    if (_restrictZeroStockTransactions && currentStock <= 0) {
      EasyLoading.showError(
        '${product.productName ?? 'This variant'} is out of stock and cannot be added to the purchase.',
        duration: const Duration(seconds: 2),
      );
      return false;
    }

    Future<void> proceed() async {
      final cartItem = CartProductModelPurchase(
        productId: product.id ?? 0,
        productName: variantLabel.isNotEmpty
            ? '${product.productName ?? ''} ($variantLabel)'
            : product.productName ?? '',
        brandName: product.brand?.brandName,
        productPurchasePrice: basePurchasePrice,
        productSalePrice: stockModel?.productSalePrice ??
            variant.mrp ??
            product.productSalePrice,
        productWholeSalePrice: product.productWholeSalePrice,
        productDealerPrice: product.productDealerPrice,
        quantities: quantity,
        stock: currentStock,
        stockId: stockModel?.id,
        gstRateSelect: product.gstRateSelect,
        vatType: product.vatType,
        vatAmount: product.vatAmount,
        productDetails: _collectAttributes(product, variant, stock: stockModel),
        variantKey: _buildVariantKey(product, variant),
        variantLabel: variantLabel,
      );

      // Set tax type in cart provider before adding product
      if (widget.selectedTaxType != null) {
        ref.watch(cartNotifierPurchaseNew).setTaxType(widget.selectedTaxType!);
      }

      ref
          .watch(cartNotifierPurchaseNew)
          .addToCartRiverPod(cartItem: cartItem, fromEditSales: false);
      if (showSuccess) {
        EasyLoading.showSuccess('Variant added to cart!');
      }
    }

    await proceed();
    return true;
  }

  void _showVariantSelectionSheet(ProductModel product, WidgetRef ref) {
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
                        final purchasePrice = stock?.productPurchasePrice ??
                            variant.purchasePrice ??
                            product.productPurchasePrice ??
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
                                          'Purchase Price: $currency$purchasePrice',
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
                                      ref: ref,
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
    return Consumer(builder: (context, ref, __) {
      final _theme = Theme.of(context);
      final productList = ref.watch(productProvider);
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(
              lang.S.of(context).productList,
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: codeController,
                          keyboardType: TextInputType.name,
                          onChanged: (value) {
                            setState(() {
                              productCode = value;
                            });
                          },
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: lang.S.of(context).productCode,
                            hintText:
                                productCode == '0000' || productCode == '-1'
                                    ? 'Scan product QR code'
                                    : productCode,
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
                                  setState(() {
                                    // Remove barcode scanner prefix (e.g., ]C1001989 -> 001989)
                                    // Barcode scanners often add a 3-character prefix like ]C1
                                    if (code.length > 3 && code.startsWith(']')) {
                                      productCode = code.substring(3);
                                    } else {
                                      productCode = code;
                                    }
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
                ),
                productList.when(data: (products) {
                  return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        return Visibility(
                          visible: ((products[i].productCode == productCode ||
                                  productCode == '0000' ||
                                  productCode == '-1')) ||
                              products[i]
                                  .productName!
                                  .toLowerCase()
                                  .contains(productCode.toLowerCase()),
                          child: ListTile(
                            visualDensity: const VisualDensity(
                                horizontal: -4, vertical: -4),
                            contentPadding: EdgeInsets.zero,
                            leading: products[i].productPicture == null
                                ? CircleAvatarWidget(
                                    name: products[i].productName,
                                    size: const Size(50, 50),
                                  )
                                : Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(90)),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          '${APIConfig.domain}${products[i].productPicture!}',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    products[i].productName.toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        _theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lang.S.of(context).stock,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    products[i].brand?.brandName ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        _theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: DAppColors.kSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  products[i].productStock.toString(),
                                  style: _theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: DAppColors.kSecondary,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (_hasVariants(products[i])) {
                                _showVariantSelectionSheet(products[i], ref);
                                return;
                              }
                              if (_restrictZeroStockTransactions &&
                                  (products[i].productStock ?? 0) <= 0) {
                                EasyLoading.showError(
                                  '${products[i].productName ?? 'This product'} is out of stock and cannot be added to the purchase.',
                                  duration: const Duration(seconds: 2),
                                );
                                return;
                              }
                              showDialog(
                                  context: context,
                                  builder: (_) {
                                    final cartProduct =
                                        CartProductModelPurchase(
                                      productId: products[i].id ?? 0,
                                      brandName:
                                          products[i].brand?.brandName ?? '',
                                      productName:
                                          products[i].productName ?? '',
                                      productDealerPrice:
                                          products[i].productDealerPrice,
                                      productPurchasePrice:
                                          products[i].productPurchasePrice,
                                      productSalePrice:
                                          products[i].productSalePrice,
                                      productWholeSalePrice:
                                          products[i].productWholeSalePrice,
                                      quantities: 1,
                                      stock: products[i].productStock,
                                      vatType: products[i].vatType,
                                      vatAmount: products[i].vatAmount,
                                      gstRateSelect: products[i].gstRateSelect,
                                    );

                                    return purchaseProductAddBottomSheet(
                                        context: context,
                                        product: cartProduct,
                                        ref: ref,
                                        fromUpdate: false,
                                        selectedTaxType: widget.selectedTaxType,
                                        restrictZeroStockTransactions:
                                            _restrictZeroStockTransactions);
                                  });
                            },
                          ),
                        );
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
      );
    });
  }
}

// ignore: must_be_immutable
class ProductCard extends StatefulWidget {
  ProductCard(
      {super.key,
      required this.productTitle,
      required this.productDescription,
      required this.stock,
      required this.productImage});

  // final Product product;
  String productTitle, productDescription, stock;
  String? productImage;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          children: [
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
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.productTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Text(
                    widget.productDescription,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lang.S.of(context).stock,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.stock,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: kGreyTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

purchaseProductAddBottomSheet(
    {required BuildContext context,
    required CartProductModelPurchase product,
    required WidgetRef ref,
    required bool fromUpdate,
    String? selectedTaxType,
    bool restrictZeroStockTransactions = false}) {
  CartProductModelPurchase tempProduct = CartProductModelPurchase(
    productDealerPrice: product.productDealerPrice,
    productId: product.productId,
    quantities: product.quantities,
    brandName: product.brandName,
    stock: product.stock,
    productName: product.productName,
    productPurchasePrice: product.productPurchasePrice,
    productSalePrice: product.productSalePrice,
    productWholeSalePrice: product.productWholeSalePrice,
    vatType: product.vatType,
    vatAmount: product.vatAmount,
    gstRateSelect: product.gstRateSelect,
    variantKey: product.variantKey,
    variantLabel: product.variantLabel,
    productDetails: product.productDetails,
    stockId: product.stockId,
  );
  return AlertDialog(
      content: SizedBox(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.S.of(context).addItems,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.cancel,
                      color: kMainColor,
                    )),
              ],
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    product.productName.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  lang.S.of(context).stock,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        product.brandName ?? '',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.stock.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (product.variantLabel != null &&
                    product.variantLabel!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kMainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.style, size: 16, color: kMainColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.variantLabel!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: kMainColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: AppTextField(
                  initialValue: product.quantities.toString(),
                  textFieldType: TextFieldType.NUMBER,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  onChanged: (value) {
                    tempProduct.quantities = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).quantity,
                    // hintText: 'Enter quantity',
                    hintText: lang.S.of(context).enterQuantity,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: product.productPurchasePrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  onChanged: (value) {
                    tempProduct.productPurchasePrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).purchasePrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: product.productSalePrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  onChanged: (value) {
                    tempProduct.productSalePrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).salePrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: product.productWholeSalePrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  onChanged: (value) {
                    tempProduct.productWholeSalePrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).wholeSalePrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: product.productDealerPrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  onChanged: (value) {
                    tempProduct.productDealerPrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).dealerPrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if ((tempProduct.quantities ?? 0) > 0) {
                final effectiveStock = tempProduct.stock ?? product.stock;
                if (restrictZeroStockTransactions &&
                    (effectiveStock != null && effectiveStock <= 0)) {
                  EasyLoading.showError(
                    '${product.productName} is out of stock and cannot be added to the purchase.',
                    duration: const Duration(seconds: 2),
                  );
                  return;
                }

                // Set tax type in cart provider before adding product
                if (selectedTaxType != null) {
                  ref
                      .watch(cartNotifierPurchaseNew)
                      .setTaxType(selectedTaxType);
                }

                if (fromUpdate) {
                  // Update existing product - use updateProduct method to preserve variant matching
                  ref.watch(cartNotifierPurchaseNew).updateProduct(
                        productId: tempProduct.productId,
                        price: tempProduct.productPurchasePrice ?? 0,
                        qty: tempProduct.quantities.toString(),
                        variantKey: tempProduct.variantKey,
                      );
                } else {
                  // Add new product
                  ref.watch(cartNotifierPurchaseNew).addToCartRiverPod(
                          cartItem: CartProductModelPurchase(
                        brandName: tempProduct.brandName,
                        stock: tempProduct.stock,
                        productId: tempProduct.productId,
                        productName: tempProduct.productName,
                        productDealerPrice: tempProduct.productDealerPrice,
                        productPurchasePrice: tempProduct.productPurchasePrice,
                        productSalePrice: tempProduct.productSalePrice,
                        productWholeSalePrice:
                            tempProduct.productWholeSalePrice,
                        quantities: tempProduct.quantities,
                        vatType: tempProduct.vatType,
                        vatAmount: tempProduct.vatAmount,
                        gstRateSelect: tempProduct.gstRateSelect,
                        variantKey: tempProduct.variantKey,
                        variantLabel: tempProduct.variantLabel,
                        productDetails: tempProduct.productDetails,
                        stockId: tempProduct.stockId,
                      ));
                }

                if (fromUpdate) {
                  Navigator.pop(context);
                } else {
                  int count = 0;
                  Navigator.popUntil(context, (route) {
                    return count++ == 2;
                  });
                }
              } else {
                EasyLoading.showError(
                  lang.S.of(context).pleaseAddQuantity,
                  // 'Please add quantity'
                );
              }
            },
            child: Container(
              height: 60,
              width: context.width(),
              decoration: const BoxDecoration(
                  color: kMainColor,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Center(
                child: Text(
                  lang.S.of(context).save,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    ),
  ));
}
