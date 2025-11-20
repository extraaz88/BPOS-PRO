import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/add_to_cart.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as l;
import 'package:mobile_pos/model/add_to_cart_model.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';

import '../../constant.dart';

class SalesAddToCartForm extends StatefulWidget {
  const SalesAddToCartForm(
      {super.key,
      required this.batchWiseStockModel,
      required this.previousContext});

  final AddToCartModel batchWiseStockModel;
  final BuildContext previousContext;

  @override
  ProductAddToCartFormState createState() => ProductAddToCartFormState();
}

class ProductAddToCartFormState extends State<SalesAddToCartForm> {
  GlobalKey<FormState> key = GlobalKey();

  bool isUpdating = false;
  String? selectedDate;
  TextEditingController productQuantityController = TextEditingController();
  TextEditingController salePriceController = TextEditingController();
  ProductModel? _product;
  List<ProductVariant> _variants = [];
  ProductVariant? _selectedVariant;
  bool _variantInitialized = false;
  String? _variantLabelDisplay;
  Map<ProductVariant, StockModel> _variantStockMap = {};

  @override
  void initState() {
    salePriceController.text = widget.batchWiseStockModel.unitPrice;
    productQuantityController.text =
        formatPointNumber(widget.batchWiseStockModel.quantity);
    _variantLabelDisplay = widget.batchWiseStockModel.variantLabel;

    super.initState();
  }

  bool isClicked = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, __) {
      final lang = l.S.of(context);
      final productsAsync = ref.watch(productProvider);

      productsAsync.whenData((products) {
        final matchedProduct = products.firstWhere(
          (element) =>
              element.id?.toString() ==
              widget.batchWiseStockModel.productId.toString(),
          orElse: () => ProductModel(),
        );

        if (matchedProduct.id != null) {
          final shouldRefresh =
              _shouldRefreshVariants(_product, matchedProduct);
          if (shouldRefresh) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _product = matchedProduct;
                _variants = _resolveVariants(matchedProduct);
                _variantInitialized = false;
              });
            });
          } else if (!_variantInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _initializeSelectedVariant();
            });
          } else {
            _product ??= matchedProduct;
          }
        }
      });

      final selectedVariant = _selectedVariant;
      final selectedProduct = _product;
      final variantStock = selectedVariant != null
          ? selectedVariant.stock ??
              _variantStockMap[selectedVariant]?.productStock
          : selectedProduct?.productStock;
      final variantMrp = selectedVariant != null
          ? selectedVariant.mrp ??
              _variantStockMap[selectedVariant]?.productSalePrice
          : selectedProduct?.productSalePrice;

      return Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((_variantLabelDisplay ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _variantLabelDisplay!,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            if (_variants.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Variant (${_variants.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(color: const Color(0xffEAEFFA)),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _variants.length; i++) ...[
                          _VariantCheckboxTile(
                            isSelected:
                                identical(_variants[i], selectedVariant),
                            onSelected: () => _onVariantSelected(_variants[i]),
                            label: _getVariantDisplayLabel(_variants[i]),
                            stockText: _getVariantStockText(_variants[i]),
                            priceText: _getVariantPriceText(_variants[i]),
                          ),
                          if (i != _variants.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 0.6,
                              color: Color(0xffEAEFFA),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (selectedVariant != null && selectedProduct != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variant Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          _collectAttributes(selectedProduct, selectedVariant)
                              .entries
                              .map(
                                (entry) => Chip(
                                  label: Text('${entry.key}: ${entry.value}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 8),
                    if (variantStock != null)
                      Text(
                        'Stock: ${formatPointNumber(variantStock)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (variantMrp != null)
                      Text(
                        'MRP: ${formatPointNumber(variantMrp)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            // Stock quantity
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: productQuantityController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      label: Text(l.S.of(context).quantity),
                      hintText: l.S.of(context).enterQuantity,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: salePriceController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.pleaseEnterAValidSalePrice;
                      }
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      label: Text(lang.salePrice),
                      hintText: lang.enterAmount,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 29),
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: GestureDetector(
                onTap: () async {
                  if (isClicked) {
                    return;
                  }
                  if (!(key.currentState?.validate() ?? false)) {
                    return;
                  }

                  isClicked = true;

                  if (_product != null && _selectedVariant != null) {
                    _applyVariantChanges();
                  }

                  ref.watch(cartNotifier).updateProduct(
                        productId: widget.batchWiseStockModel.productId,
                        price: salePriceController.text,
                        qty: productQuantityController.text,
                        variantKey: widget.batchWiseStockModel.variantKey,
                      );

                  Navigator.pop(context);
                },
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: kMainColor,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Center(
                    child: Text(
                      l.S.of(context).save,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  void _initializeSelectedVariant() {
    if (!mounted || _variantInitialized) return;
    if (_product == null) {
      setState(() {
        _selectedVariant = null;
        _variantInitialized = true;
      });
      return;
    }

    final variants = _variants;
    if (variants.isEmpty) {
      setState(() {
        _selectedVariant = null;
        _variantInitialized = true;
      });
      return;
    }

    final currentKey = widget.batchWiseStockModel.variantKey?.trim();
    ProductVariant? initial;

    if (currentKey != null && currentKey.isNotEmpty) {
      for (final variant in variants) {
        if (_buildVariantKey(_product!, variant) == currentKey) {
          initial = variant;
          break;
        }
      }
    }

    initial ??= variants.first;
    final label = _getVariantDisplayLabel(initial);

    setState(() {
      _selectedVariant = initial;
      _variantInitialized = true;
      if (label.isNotEmpty) {
        _variantLabelDisplay = label;
      }
    });

    _syncControllersWithVariant(initial, clampQuantity: true);
  }

  void _onVariantSelected(ProductVariant variant) {
    if (!mounted || _product == null) return;
    setState(() {
      _selectedVariant = variant;
      _variantLabelDisplay = _getVariantDisplayLabel(variant);
    });
    _syncControllersWithVariant(variant);
  }

  void _syncControllersWithVariant(ProductVariant variant,
      {bool clampQuantity = true}) {
    if (_product == null) return;
    final product = _product!;

    final stockModel = _variantStockMap[variant];
    final num salePrice = (variant.mrp ??
            stockModel?.productSalePrice ??
            product.productSalePrice ??
            num.tryParse(widget.batchWiseStockModel.unitPrice) ??
            0)
        .toDouble();
    salePriceController.text = formatPointNumber(salePrice);

    if (clampQuantity) {
      final num? availableStockSource =
          variant.stock ?? stockModel?.productStock ?? product.productStock;
      if (availableStockSource != null && availableStockSource > 0) {
        final availableStock = availableStockSource.toInt();
        final currentQty = num.tryParse(productQuantityController.text) ??
            widget.batchWiseStockModel.quantity;
        if (currentQty > availableStock) {
          productQuantityController.text = formatPointNumber(availableStock);
        }
      }
    }
  }

  void _applyVariantChanges() {
    if (_product == null || _selectedVariant == null) return;

    final product = _product!;
    final variant = _selectedVariant!;
    final stockModel = _variantStockMap[variant];
    final variantLabel =
        (stockModel?.batchNo ?? _buildVariantLabel(product, variant)).trim();
    final displayLabel = _getVariantDisplayLabel(variant).trim();
    final variantKey = _buildVariantKey(product, variant);

    widget.batchWiseStockModel.variantLabel =
        variantLabel.isNotEmpty ? variantLabel : displayLabel;
    widget.batchWiseStockModel.variantKey = variantKey;

    widget.batchWiseStockModel.productDetails =
        _collectAttributes(product, variant);

    widget.batchWiseStockModel.productName = displayLabel.isNotEmpty
        ? '${product.productName ?? ''} ($displayLabel)'
        : product.productName ?? widget.batchWiseStockModel.productName;

    widget.batchWiseStockModel.productPurchasePrice =
        stockModel?.productPurchasePrice ??
            variant.purchasePrice ??
            product.productPurchasePrice;

    widget.batchWiseStockModel.stock = stockModel?.productStock ??
        variant.stock ??
        product.productStock ??
        widget.batchWiseStockModel.stock;

    widget.batchWiseStockModel.stockId = stockModel?.id ?? variant.id;

    widget.batchWiseStockModel.unitPrice = salePriceController.text;
  }

  String _buildVariantKey(ProductModel product, ProductVariant variant) {
    final parts = <String>[
      (variant.id ?? '').toString(),
      variant.size ?? product.size ?? '',
      variant.weight ?? product.weight ?? '',
      variant.color ?? product.color ?? '',
      variant.capacity ?? product.capacity ?? '',
      variant.type ?? product.type ?? '',
    ];

    return parts.where((part) => part.trim().isNotEmpty).join('|');
  }

  String _buildVariantLabel(ProductModel? product, ProductVariant variant) {
    final parts = <String>[];
    final sourceProduct = product;

    final size = variant.size ?? sourceProduct?.size;
    final color = variant.color ?? sourceProduct?.color;
    final weight = variant.weight ?? sourceProduct?.weight;
    final capacity = variant.capacity ?? sourceProduct?.capacity;
    final type = variant.type ?? sourceProduct?.type;

    if (size != null && size.trim().isNotEmpty) {
      parts.add('Size: $size');
    }
    if (color != null && color.trim().isNotEmpty) {
      parts.add('Color: $color');
    }
    if (weight != null && weight.trim().isNotEmpty) {
      parts.add('Weight: $weight');
    }
    if (capacity != null && capacity.trim().isNotEmpty) {
      parts.add('Capacity: $capacity');
    }
    if (type != null && type.trim().isNotEmpty) {
      parts.add('Type: $type');
    }

    return parts.join(' | ');
  }

  String _getVariantDisplayLabel(ProductVariant variant) {
    final stockModel = _variantStockMap[variant];
    final batchLabel = stockModel?.batchNo;
    if (batchLabel != null && batchLabel.trim().isNotEmpty) {
      return batchLabel.trim();
    }
    final label = _buildVariantLabel(_product, variant);
    if (label.isNotEmpty) {
      return label;
    }
    final index = _variants.indexOf(variant);
    if (index >= 0) {
      return 'Variant ${index + 1}';
    }
    return 'Variant';
  }

  Map<String, String> _collectAttributes(
      ProductModel product, ProductVariant variant) {
    final attributes = <String, String>{};
    final stockModel = _variantStockMap[variant];

    if (stockModel?.batchNo != null && stockModel!.batchNo!.trim().isNotEmpty) {
      attributes['Batch'] = stockModel.batchNo!.trim();
    }

    void addAttribute(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        attributes[key] = value.trim();
      }
    }

    addAttribute('Size', variant.size ?? product.size);
    addAttribute('Color', variant.color ?? product.color);
    addAttribute('Weight', variant.weight ?? product.weight);
    addAttribute('Capacity', variant.capacity ?? product.capacity);
    addAttribute('Type', variant.type ?? product.type);

    final purchasePrice =
        stockModel?.productPurchasePrice ?? variant.purchasePrice;
    if (purchasePrice != null) {
      attributes['Purchase Price'] = formatPointNumber(purchasePrice);
    }

    final salePrice = stockModel?.productSalePrice ?? variant.mrp;
    if (salePrice != null) {
      attributes['Sale Price'] = formatPointNumber(salePrice);
    }

    final stockValue = stockModel?.productStock ?? variant.stock;
    if (stockValue != null) {
      attributes['Stock'] = formatPointNumber(stockValue);
    }

    return attributes;
  }

  List<ProductVariant> _resolveVariants(ProductModel product) {
    final directVariants = product.variants;
    if (directVariants != null && directVariants.isNotEmpty) {
      _variantStockMap = {};
      return List<ProductVariant>.from(directVariants);
    }

    final stocks = product.stocks;
    if (stocks == null || stocks.isEmpty) {
      _variantStockMap = {};
      return [];
    }

    final generatedVariants = <ProductVariant>[];
    final generatedMap = <ProductVariant, StockModel>{};

    for (final stock in stocks) {
      final variant = _variantFromStock(product, stock);
      generatedVariants.add(variant);
      generatedMap[variant] = stock;
    }

    _variantStockMap = generatedMap;
    return generatedVariants;
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

  String? _getVariantStockText(ProductVariant variant) {
    final stockModel = _variantStockMap[variant];
    final stockValue = variant.stock ?? stockModel?.productStock;

    if (stockValue == null) return null;
    return 'Stock: ${formatPointNumber(stockValue)}';
  }

  String? _getVariantPriceText(ProductVariant variant) {
    final stockModel = _variantStockMap[variant];
    final salePrice = variant.mrp ?? stockModel?.productSalePrice;

    if (salePrice == null) return null;
    return 'Sale Price: ${formatPointNumber(salePrice)}';
  }

  bool _shouldRefreshVariants(ProductModel? current, ProductModel next) {
    if (current == null) return true;
    if (current.id != next.id) return true;
    if ((current.updatedAt ?? '') != (next.updatedAt ?? '')) return true;
    if ((current.productStock ?? 0) != (next.productStock ?? 0)) return true;

    final currentVariantCount = current.variants?.length ?? 0;
    final nextVariantCount = next.variants?.length ?? 0;
    if (currentVariantCount != nextVariantCount) return true;

    final currentStockCount = current.stocks?.length ?? 0;
    final nextStockCount = next.stocks?.length ?? 0;
    if (currentStockCount != nextStockCount) return true;

    return false;
  }
}

class _VariantCheckboxTile extends StatelessWidget {
  const _VariantCheckboxTile({
    required this.isSelected,
    required this.onSelected,
    required this.label,
    this.stockText,
    this.priceText,
  });

  final bool isSelected;
  final VoidCallback onSelected;
  final String label;
  final String? stockText;
  final String? priceText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onSelected,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? kMainColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) {
                if (!isSelected) {
                  onSelected();
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (stockText != null)
                        Text(
                          stockText!,
                          style: theme.textTheme.bodySmall,
                        ),
                      if (priceText != null)
                        Text(
                          priceText!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
