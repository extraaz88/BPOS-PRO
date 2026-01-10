import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/widgets/empty_widget/_empty_widget.dart';

import '../../Provider/product_provider.dart';
import '../../currency.dart';

class StockList extends StatefulWidget {
  const StockList({super.key, required this.isFromReport});

  final bool isFromReport;

  @override
  StockListState createState() => StockListState();
}

class StockListState extends State<StockList> {
  String productSearch = '';
  bool _isRefreshing = false;
  String selectedFilter = 'All';
  String selectedExpireFilter = '7 Days';

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    ref.refresh(productProvider);
    await Future.delayed(const Duration(seconds: 1));
    _isRefreshing = false;
  }

  final _horizontalScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(productProvider);
      return providerData.when(
        data: (product) {
          double totalStockValue = 0;
          List<ProductModel> showableProducts = [];
          DateTime now = DateTime.now();

          for (var element in product) {
            bool matchesSearch = element.productName!
                .toLowerCase()
                .contains(productSearch.toLowerCase().trim());
            bool matchesFilter = selectedFilter == 'All' ||
                (selectedFilter == 'Low Stock' &&
                    (element.productStock ?? 0) <= (element.alertQty ?? 0));

            // Expire ফিল্টারিং
            bool matchesExpireFilter = true;
            if (selectedFilter == 'Expire') {
              DateTime? expiryDate =
                  DateTime.tryParse(element.expireDate ?? '');
              if (expiryDate != null) {
                int daysLeft = expiryDate.difference(now).inDays;
                switch (selectedExpireFilter) {
                  case '7 Days':
                    matchesExpireFilter = daysLeft <= 7 && daysLeft > 0;
                    break;
                  case '10 Days':
                    matchesExpireFilter = daysLeft <= 10 && daysLeft > 0;
                    break;
                  case '15 Days':
                    matchesExpireFilter = daysLeft <= 15 && daysLeft > 0;
                    break;
                  case '30 Days':
                    matchesExpireFilter = daysLeft <= 30 && daysLeft > 0;
                    break;
                  case '50 Days':
                    matchesExpireFilter = daysLeft <= 50 && daysLeft > 0;
                    break;
                  case 'Expired':
                    matchesExpireFilter = daysLeft <= 0;
                    break;
                }
              } else {
                matchesExpireFilter = false;
              }
            }

            if (selectedFilter == 'Expire') {
              if (matchesSearch && matchesExpireFilter) {
                showableProducts.add(element);
                totalStockValue += (element.productPurchasePrice ?? 0) *
                    (element.productStock ?? 0);
              }
            } else if (selectedFilter == 'Low Stock') {
              if (matchesSearch && matchesFilter) {
                showableProducts.add(element);
                totalStockValue += (element.productPurchasePrice ?? 0) *
                    (element.productStock ?? 0);
              }
            } else {
              if (matchesSearch) {
                showableProducts.add(element);
                totalStockValue += (element.productPurchasePrice ?? 0) *
                    (element.productStock ?? 0);
              }
            }
          }

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                lang.S.of(context).stockList,
              ),
              // centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0.0,
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: updateBorderColor),
                  ),
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    isDense: true,
                    value: selectedFilter,
                    icon: const Icon(IconlyLight.arrow_down_2,
                        color: Colors.black, size: 14),
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                        // selectedExpireFilter = null; // Expire ফিল্টার রিসেট
                      });
                    },
                    items: <String>['All', 'Low Stock', 'Expire']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                  ),
                ),
              ],
              toolbarHeight: 100,
              bottom: PreferredSize(
                preferredSize: const Size(double.infinity, 40),
                child: Column(
                  children: [
                    Container(
                      color: updateBorderColor.withValues(alpha: 0.5),
                      width: double.infinity,
                      height: 1,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Flexible(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextFormField(
                              // controller: searchController,
                              onChanged: (value) {
                                setState(() {
                                  productSearch = value;
                                });
                              },
                              decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: updateBorderColor, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.red, width: 1),
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Icon(
                                      FeatherIcons.search,
                                      color: kNeutralColor,
                                    ),
                                  ),
                                  hintText: lang.S.of(context).searchH,
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: kNeutralColor,
                                      )),
                            ),
                          ),
                        ),
                        if (selectedFilter == 'Expire')
                          Flexible(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Container(
                                alignment: Alignment.center,
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: updateBorderColor),
                                ),
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  isDense: true,
                                  value: selectedExpireFilter,
                                  hint: Text("Select Days",
                                      style: theme.textTheme.bodyMedium),
                                  icon: const Icon(IconlyLight.arrow_down_2,
                                      color: Colors.black, size: 14),
                                  underline: Container(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedExpireFilter = newValue!;
                                    });
                                  },
                                  items: <String>[
                                    '7 Days',
                                    '15 Days',
                                    '30 Days',
                                    '60 Days',
                                    'Expired'
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value,
                                          style: theme.textTheme.bodyMedium),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: RefreshIndicator(
                onRefresh: () => refreshData(ref),
                child: Column(
                  children: [
                    showableProducts.isNotEmpty
                        ? LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              final kWidth = constraints.maxWidth;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScroll,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: kWidth),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerTheme: const DividerThemeData(
                                            color: Colors.transparent)),
                                    child: DataTable(
                                      border: const TableBorder(
                                        horizontalInside: BorderSide(
                                          width: 1,
                                          color: updateBorderColor,
                                        ),
                                      ),
                                      dataRowColor:
                                          const WidgetStatePropertyAll(
                                              Colors.white),
                                      headingRowColor: WidgetStateProperty.all(
                                          const Color(0xffFEF0F1)),
                                      showBottomBorder: false,
                                      dividerThickness: 0.0,
                                      headingTextStyle:
                                          theme.textTheme.titleSmall,
                                      dataTextStyle: theme.textTheme.bodyMedium,
                                      columnSpacing: 20.0,
                                      headingRowHeight: 40,
                                      dataRowMinHeight: 40,
                                      // headingRowColor: MaterialStateColor.resolveWith((states) => const Color(0xffFEF0F1)),
                                      columns: [
                                        DataColumn(
                                            label: Text(
                                                lang.S.of(context).product)),
                                        DataColumn(label: Text('Unit')),
                                        DataColumn(
                                            label:
                                                Text(lang.S.of(context).cost)),
                                        DataColumn(
                                            label:
                                                Text(lang.S.of(context).qty)),
                                        DataColumn(
                                            label:
                                                Text(lang.S.of(context).sale)),
                                        DataColumn(label: Text('Action')),
                                      ],
                                      rows: showableProducts.map((product) {
                                        bool isLowStock =
                                            (product.productStock ?? 0) <=
                                                (product.alertQty ?? 0);
                                        bool hasVariants =
                                            _hasVariants(product);
                                        return DataRow(cells: [
                                          DataCell(
                                            (product.brand?.brandName != null)
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                                minWidth: 30,
                                                                maxWidth: 250),
                                                        child: Text(
                                                          product.productName ??
                                                              'N/A',
                                                          style: theme.textTheme
                                                              .bodyMedium
                                                              ?.copyWith(),
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${product.brand?.brandName}',
                                                        style: theme.textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                color: const Color(
                                                                    0xff999999),
                                                                fontSize: 13),
                                                        textAlign:
                                                            TextAlign.start,
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    product.productName ??
                                                        'N?A',
                                                    style: theme
                                                        .textTheme.bodyMedium,
                                                    textAlign: TextAlign.start,
                                                  ),
                                          ),
                                          DataCell(
                                            Text(
                                              product.unit?.unitName ?? '',
                                              style: theme.textTheme.bodyMedium,
                                              textAlign: TextAlign.start,
                                            ),
                                          ),
                                          DataCell(Text(
                                              '$currency${product.productPurchasePrice?.toStringAsFixed(2)}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: isLowStock
                                                          ? Colors.red
                                                          : Colors.black))),
                                          DataCell(
                                            Text(
                                              product.productStock.toString(),
                                              style: TextStyle(
                                                  color: isLowStock
                                                      ? Colors.red
                                                      : Colors.black),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '$currency${product.productSalePrice?.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                  color: isLowStock
                                                      ? Colors.red
                                                      : Colors.black),
                                            ),
                                          ),
                                          DataCell(
                                            hasVariants
                                                ? TextButton(
                                                    onPressed: () =>
                                                        _showVariantDetails(
                                                            context, product),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      minimumSize:
                                                          const Size(60, 32),
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      'View',
                                                      style: TextStyle(
                                                        color: kMainColor,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : EmptyWidget(
                            message: TextSpan(
                                text: lang.S.of(context).noProductFound),
                          ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                color: const Color(0xffFEF0F1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.S.of(context).stockValue,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$currency${totalStockValue.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        error: (e, stack) => Center(child: Text("Error: $e")),
        loading: () => const Center(child: CircularProgressIndicator()),
      );
    });
  }

  // Check if product has variants or stocks
  bool _hasVariants(ProductModel product) {
    // Check if product has direct variants
    if (product.variants != null && product.variants!.isNotEmpty) {
      return true;
    }
    // Check if product has stocks (which can represent variants)
    if (product.stocks != null && product.stocks!.isNotEmpty) {
      return true;
    }
    return false;
  }

  // Show variant details in bottom sheet
  void _showVariantDetails(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        // Build list of variants/stocks to display
        List<Map<String, dynamic>> variantList = [];

        // First, try to use direct variants
        if (product.variants != null && product.variants!.isNotEmpty) {
          for (var variant in product.variants!) {
            variantList.add({
              'type': 'variant',
              'variant': variant,
              'stock': null,
            });
          }
        }
        // If no variants, use stocks
        else if (product.stocks != null && product.stocks!.isNotEmpty) {
          for (var stock in product.stocks!) {
            variantList.add({
              'type': 'stock',
              'variant': null,
              'stock': stock,
            });
          }
        }

        if (variantList.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.productName ?? 'Product',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No variant details available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName ?? 'Product',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${variantList.length} ${variantList.length == 1 ? 'Variant' : 'Variants'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Variant List
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: variantList.length,
                      itemBuilder: (context, index) {
                        final item = variantList[index];
                        final variant = item['variant'] as ProductVariant?;
                        final stock = item['stock'] as StockModel?;

                        // Get variant details
                        String variantLabel =
                            _buildVariantLabel(variant, stock);
                        num? stockQty = variant?.stock ?? stock?.productStock;
                        num? purchasePrice = variant?.purchasePrice ??
                            stock?.productPurchasePrice ??
                            product.productPurchasePrice;
                        num? salePrice = variant?.mrp ??
                            stock?.productSalePrice ??
                            product.productSalePrice;
                        String? batchNo = stock?.batchNo;
                        String? expireDate =
                            stock?.expireDate ?? product.expireDate;
                        bool isLowStock = (stockQty ?? 0) <=
                            (variant?.lowStock ??
                                stock?.lowStock ??
                                product.alertQty ??
                                0);

                        return Card(
                          margin: EdgeInsets.only(
                            bottom: index == variantList.length - 1 ? 0 : 12,
                          ),
                          elevation: 0,
                          color: isLowStock
                              ? const Color(0xFFFFF0F0)
                              : const Color(0xFFF8F9FB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isLowStock
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.2),
                              width: isLowStock ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Variant Label
                                if (variantLabel.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Variant ${index + 1}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isLowStock
                                                ? Colors.red
                                                : kMainColor,
                                          ),
                                        ),
                                        if (isLowStock) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Low Stock',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                // Variant Attributes
                                if (variant != null) ...[
                                  if (variant.size != null &&
                                      variant.size!.isNotEmpty)
                                    _buildDetailRow(
                                        theme, 'Size', variant.size!),
                                  if (variant.color != null &&
                                      variant.color!.isNotEmpty)
                                    _buildDetailRow(
                                        theme, 'Color', variant.color!),
                                  if (variant.weight != null &&
                                      variant.weight!.isNotEmpty)
                                    _buildDetailRow(
                                        theme, 'Weight', variant.weight!),
                                  if (variant.capacity != null &&
                                      variant.capacity!.isNotEmpty)
                                    _buildDetailRow(
                                        theme, 'Capacity', variant.capacity!),
                                  if (variant.type != null &&
                                      variant.type!.isNotEmpty)
                                    _buildDetailRow(
                                        theme, 'Type', variant.type!),
                                ],

                                const Divider(height: 20),

                                // Stock Quantity
                                _buildDetailRow(
                                  theme,
                                  'Stock Quantity',
                                  stockQty?.toString() ?? '0',
                                  valueColor: isLowStock ? Colors.red : null,
                                  valueStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isLowStock ? Colors.red : Colors.black,
                                  ),
                                ),

                                // Purchase Price
                                if (purchasePrice != null)
                                  _buildDetailRow(
                                    theme,
                                    'Purchase Price',
                                    '$currency${purchasePrice.toStringAsFixed(2)}',
                                  ),

                                // Sale Price
                                if (salePrice != null)
                                  _buildDetailRow(
                                    theme,
                                    'Sale Price',
                                    '$currency${salePrice.toStringAsFixed(2)}',
                                  ),

                                // Batch Number
                                if (batchNo != null && batchNo.isNotEmpty)
                                  _buildDetailRow(theme, 'Batch No', batchNo),

                                // Expiry Date
                                if (expireDate != null && expireDate.isNotEmpty)
                                  _buildDetailRow(
                                      theme, 'Expiry Date', expireDate),

                                // Stock Value
                                if (stockQty != null && purchasePrice != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: kMainColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Stock Value',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '$currency${(stockQty * purchasePrice).toStringAsFixed(2)}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: kMainColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Build variant label from variant or stock
  String _buildVariantLabel(ProductVariant? variant, StockModel? stock) {
    if (variant != null) {
      List<String> parts = [];
      if (variant.size != null && variant.size!.isNotEmpty)
        parts.add('Size: ${variant.size}');
      if (variant.color != null && variant.color!.isNotEmpty)
        parts.add('Color: ${variant.color}');
      if (variant.weight != null && variant.weight!.isNotEmpty)
        parts.add('Weight: ${variant.weight}');
      if (variant.capacity != null && variant.capacity!.isNotEmpty)
        parts.add('Capacity: ${variant.capacity}');
      if (variant.type != null && variant.type!.isNotEmpty)
        parts.add('Type: ${variant.type}');
      return parts.join(', ');
    } else if (stock != null &&
        stock.batchNo != null &&
        stock.batchNo!.isNotEmpty) {
      return 'Batch: ${stock.batchNo}';
    }
    return '';
  }

  // Build detail row widget
  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
