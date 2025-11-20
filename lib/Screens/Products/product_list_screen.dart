import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Combo/Model/combo_model.dart';
import 'package:mobile_pos/Combo/Provider/combo_provider.dart';
import 'package:mobile_pos/Combo/create_combo_screen.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/Screens/product_category/category_list_screen.dart';
import 'package:mobile_pos/Screens/product_unit/unit_list.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../barcode/gererate_barcode.dart';
import '../product_brand/brands_list.dart';
import '../product_category/provider/product_category_provider/product_unit_provider.dart';
import '../Waste_management/disposal_form.dart';
import 'Repo/product_repo.dart';
import 'Widgets/widgets.dart';
import 'add_product.dart';
import 'bulk product upload/bulk_product_upload_screen.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.invalidate(productProvider);
    ref.invalidate(comboProvider);
    ref.invalidate(categoryProvider);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, __) {
        final businessInfo = ref.watch(businessInfoProvider);
        final providerData = ref.watch(productProvider);
        final comboData = ref.watch(comboProvider);
        final _theme = Theme.of(context);
        return businessInfo.when(data: (details) {
          return GlobalPopup(
            child: DefaultTabController(
              length: 2,
              child: Builder(
                builder: (context) {
                  final TabController tabController =
                      DefaultTabController.of(context);

                  return Scaffold(
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      backgroundColor: Colors.white,
                      surfaceTintColor: kWhite,
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.black),
                      title: Text(
                        lang.S.of(context).productList,
                      ),
                      bottom: TabBar(
                        labelColor: kMainColor,
                        indicatorColor: kMainColor,
                        unselectedLabelColor: kGreyTextColor,
                        tabs: const [
                          Tab(text: 'Products'),
                          Tab(text: 'Combos'),
                        ],
                      ),
                      actions: [
                        PopupMenuButton<int>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const CategoryList(
                                              isFromProductList: true,
                                            )));
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    IconlyBold.category,
                                    color: kGreyTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.S.of(context).productCategory,
                                    //"Product Category",
                                    style: _theme.textTheme.bodyMedium
                                        ?.copyWith(color: kGreyTextColor),
                                  )
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const BrandsList(
                                              isFromProductList: true,
                                            )));
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    IconlyBold.bookmark,
                                    color: kGreyTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.S.of(context).brand,
                                    //"Brand",
                                    style: _theme.textTheme.bodyMedium
                                        ?.copyWith(color: kGreyTextColor),
                                  )
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const UnitList(
                                              isFromProductList: true,
                                            )));
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.scale,
                                    color: kGreyTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.S.of(context).productUnit,
                                    // "Product Unit",
                                    style: _theme.textTheme.bodyMedium
                                        ?.copyWith(color: kGreyTextColor),
                                  )
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const BulkUploader(
                                              previousProductCode: [],
                                              previousProductName: [],
                                            )));
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.list_alt,
                                    color: kGreyTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Bulk Upload',
                                    // "Product Unit",
                                    style: _theme.textTheme.bodyMedium
                                        ?.copyWith(color: kGreyTextColor),
                                  )
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const BarcodeGeneratorScreen()));
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.barcode_reader,
                                    color: kGreyTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Barcode Generator',
                                    style: _theme.textTheme.bodyMedium
                                        ?.copyWith(color: kGreyTextColor),
                                  )
                                ],
                              ),
                            ),
                          ],
                          offset: const Offset(0, 40),
                          color: kWhite,
                          padding: EdgeInsets.zero,
                          elevation: 2,
                        ),
                      ],
                      centerTitle: true,
                    ),
                    floatingActionButton: FloatingActionButton(
                        backgroundColor: kMainColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                        onPressed: () async {
                          if (tabController.index == 0) {
                            Navigator.pushNamed(context, '/AddProducts');
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateComboScreen(),
                              ),
                            );
                          }
                        },
                        child: const Icon(
                          Icons.add,
                          color: kWhite,
                        )),
                    body: TabBarView(
                      children: [
                        _buildProductsTab(
                          context: context,
                          ref: ref,
                          theme: _theme,
                          productAsync: providerData,
                        ),
                        _buildCombosTab(
                          context: context,
                          ref: ref,
                          comboAsync: comboData,
                          theme: _theme,
                        ),
                      ],
                    ),
                    // bottomNavigationBar: ButtonGlobal(
                    //   iconWidget: Icons.add,
                    //   buttontext: lang.S.of(context).addNewProduct,
                    //   iconColor: Colors.white,
                    //   buttonDecoration: kButtonDecoration.copyWith(color: kMainColor),
                    //   onPressed: () {
                    //     Navigator.pushNamed(context, '/AddProducts');
                    //   },
                    // ),
                  );
                },
              ),
            ),
          );
        }, error: (e, stack) {
          return Text(e.toString());
        }, loading: () {
          return const Center(child: CircularProgressIndicator());
        });
      },
    );
  }

  Widget _buildProductsTab({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required AsyncValue<List<ProductModel>> productAsync,
  }) {
    return RefreshIndicator(
      onRefresh: () => refreshData(ref),
      child: productAsync.when(
        data: (products) {
          final regularProducts = products
              .where((product) =>
                  ((product.productType?.toLowerCase() ?? '').trim()) !=
                  'combo')
              .toList();

          if (regularProducts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Text(
                      lang.S.of(context).addProduct,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: regularProducts.length,
            itemBuilder: (_, i) {
              final product = regularProducts[i];
              return ListTile(
                onTap: () => _handleProductTap(context, product),
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                contentPadding: const EdgeInsets.only(left: 16),
                leading: product.productPicture == null
                    ? CircleAvatarWidget(
                        name: product.productName,
                        size: const Size(50, 50),
                      )
                    : Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(90)),
                          image: DecorationImage(
                            image: NetworkImage(
                              '${APIConfig.domain}${product.productPicture!}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                title: Text(
                  product.productName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  "${lang.S.of(context).stock} : ${product.productStock}${product.unit?.unitName != null && product.unit!.unitName!.isNotEmpty ? ' (${product.unit!.unitName})' : ''}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DAppColors.kSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$currency${product.productSalePrice}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18),
                    ),
                    PopupMenuButton<int>(
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProduct(
                                  productModel: product,
                                ),
                              ),
                            );
                          },
                          value: 1,
                          child: Row(
                            children: [
                              const Icon(
                                IconlyBold.edit,
                                color: kGreyTextColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                lang.S.of(context).edit,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: kGreyTextColor),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            bool confirmDelete = await showDeleteAlert(
                                context: context, itemsName: 'product');
                            if (confirmDelete) {
                              EasyLoading.show(
                                status: lang.S.of(context).deleting,
                              );
                              ProductRepo productRepo = ProductRepo();
                              await productRepo.deleteProduct(
                                  id: product.id.toString(),
                                  context: context,
                                  ref: ref);
                            }
                          },
                          value: 2,
                          child: Row(
                            children: [
                              const Icon(
                                IconlyBold.delete,
                                color: kGreyTextColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                lang.S.of(context).delete,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: kGreyTextColor),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DisposalForm(
                                  productName: product.productName,
                                  productSku: product.productCode,
                                  productId: product.id?.toInt(),
                                  currentStock: product.productStock?.toInt(),
                                ),
                              ),
                            ).then((disposed) {
                              if (disposed == true) {
                                ref.invalidate(productProvider);
                              }
                            });
                          },
                          value: 3,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                color: kGreyTextColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Dispose',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: kGreyTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                      offset: const Offset(0, 40),
                      color: kWhite,
                      padding: EdgeInsets.zero,
                      elevation: 2,
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) {
              return Divider(
                color: const Color(0xff808191).withValues(alpha: 0.2),
              );
            },
          );
        },
        error: (e, stack) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(child: Text(e.toString())),
              ),
            ],
          );
        },
        loading: () {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleProductTap(BuildContext context, ProductModel product) {
    final apiVariants = (product.variants ?? [])
        .where((variant) => _hasVariantData(variant))
        .toList();

    if (apiVariants.isNotEmpty) {
      _logVariants(product, apiVariants, source: 'api');
      _showVariantBottomSheet(
        context: context,
        product: product,
        variants: apiVariants,
      );
      return;
    }

    final stockVariants = _buildVariantsFromStocks(product);

    if (stockVariants.isNotEmpty) {
      _logVariants(product, stockVariants, source: 'stocks');
      _showVariantBottomSheet(
        context: context,
        product: product,
        variants: stockVariants,
      );
      return;
    }

    final fallbackVariant = ProductVariant(
      size: product.size,
      color: product.color,
      weight: product.weight,
      capacity: product.capacity,
      type: product.type,
    );

    if (_hasAnyAttribute(fallbackVariant)) {
      _logVariants(product, [fallbackVariant], source: 'fallback');
      _showVariantBottomSheet(
        context: context,
        product: product,
        variants: [fallbackVariant],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.S.of(context).noDataFound,
          ),
        ),
      );
    }
  }

  bool _hasAnyAttribute(ProductVariant variant) {
    return (variant.size?.trim().isNotEmpty ?? false) ||
        (variant.color?.trim().isNotEmpty ?? false) ||
        (variant.weight?.trim().isNotEmpty ?? false) ||
        (variant.capacity?.trim().isNotEmpty ?? false) ||
        (variant.type?.trim().isNotEmpty ?? false);
  }

  bool _hasVariantData(ProductVariant variant) {
    return _hasAnyAttribute(variant) ||
        variant.purchasePrice != null ||
        variant.mrp != null ||
        variant.stock != null ||
        variant.lowStock != null;
  }

  List<ProductVariant> _buildVariantsFromStocks(ProductModel product) {
    final stocks = product.stocks ?? [];
    final List<ProductVariant> variants = [];

    for (final stock in stocks) {
      final attributes = _parseBatchAttributes(stock.batchNo);
      final variant = ProductVariant(
        id: stock.id,
        size: attributes['size'] ?? product.size,
        color: attributes['color'] ?? product.color,
        weight: attributes['weight'] ?? product.weight,
        capacity: attributes['capacity'] ?? product.capacity,
        type: attributes['type'] ?? product.type,
        purchasePrice: stock.productPurchasePrice,
        mrp: stock.productSalePrice ?? product.productSalePrice,
        stock: stock.productStock,
        lowStock: stock.lowStock ?? product.alertQty,
      );

      if (_hasVariantData(variant)) {
        variants.add(variant);
      }
    }

    return variants;
  }

  Map<String, String> _parseBatchAttributes(String? batchNo) {
    if (batchNo == null || batchNo.trim().isEmpty) {
      return {};
    }

    final Map<String, String> attributes = {};
    final parts = batchNo.split('|');

    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;

      final separatorIndex = part.indexOf(':');
      if (separatorIndex == -1) continue;

      final key = part.substring(0, separatorIndex).trim().toLowerCase();
      final value = part.substring(separatorIndex + 1).trim();
      if (value.isEmpty) continue;

      attributes[key] = value;
    }

    return attributes;
  }

  void _logVariants(
    ProductModel product,
    List<ProductVariant> variants, {
    required String source,
  }) {
    final productLabel = product.productName ?? 'ID:${product.id ?? '-'}';
    print('=== VARIANTS ($source) FOR $productLabel ===');
    for (final variant in variants) {
      print(variant.toJson());
    }
  }

  void _showVariantBottomSheet({
    required BuildContext context,
    required ProductModel product,
    required List<ProductVariant> variants,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.productName ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Variant Details',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kMainColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(variants.length, (index) {
                  final variant = variants[index];
                  return Card(
                    margin: EdgeInsets.only(
                      bottom: index == variants.length - 1 ? 0 : 12,
                    ),
                    elevation: 0,
                    color: const Color(0xFFF8F9FB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (variants.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Variant ${index + 1}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          _buildAttributeRow(
                            label: 'Size',
                            value: _formatValue(variant.size),
                            theme: theme,
                          ),
                          _buildAttributeRow(
                            label: 'Color',
                            value: _formatValue(variant.color),
                            theme: theme,
                          ),
                          _buildAttributeRow(
                            label: 'Weight',
                            value: _formatValue(variant.weight),
                            theme: theme,
                          ),
                          _buildAttributeRow(
                            label: 'Capacity',
                            value: _formatValue(variant.capacity),
                            theme: theme,
                          ),
                          _buildAttributeRow(
                            label: 'Type',
                            value: _formatValue(variant.type),
                            theme: theme,
                          ),
                          if (variant.purchasePrice != null)
                            _buildAttributeRow(
                              label: 'Purchase Price',
                              value: _formatNumber(variant.purchasePrice),
                              theme: theme,
                            ),
                          if (variant.mrp != null)
                            _buildAttributeRow(
                              label: 'MRP',
                              value: _formatNumber(variant.mrp),
                              theme: theme,
                            ),
                          if (variant.stock != null)
                            _buildAttributeRow(
                              label: 'Stock',
                              value: _formatNumber(variant.stock),
                              theme: theme,
                            ),
                          if (variant.lowStock != null)
                            _buildAttributeRow(
                              label: 'Low Stock Alert',
                              value: _formatNumber(variant.lowStock),
                              theme: theme,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttributeRow({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }

  String _formatNumber(num? value) {
    if (value == null) return '-';
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Widget _buildCombosTab({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<List<ComboModel>> comboAsync,
    required ThemeData theme,
  }) {
    return RefreshIndicator(
      onRefresh: () => refreshData(ref),
      child: comboAsync.when(
        data: (combos) {
          final activeCombos = combos
              .where((combo) =>
                  ((combo.productStatus?.toLowerCase() ?? '').trim()) ==
                  'active')
              .toList();

          if (activeCombos.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No combos found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: activeCombos.length,
            itemBuilder: (_, i) {
              final combo = activeCombos[i];
              return ListTile(
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                contentPadding: const EdgeInsets.only(left: 16),
                leading: combo.comboImage == null
                    ? CircleAvatarWidget(
                        name: combo.comboName,
                        size: const Size(50, 50),
                      )
                    : Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(90)),
                          image: DecorationImage(
                            image: NetworkImage(
                              '${APIConfig.domain}${combo.comboImage!}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                title: Text(
                  combo.comboName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
                subtitle: Text(
                  '${combo.products?.length ?? 0} items',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DAppColors.kSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$currency${combo.finalPrice?.toStringAsFixed(2) ?? '0.00'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18),
                    ),

                    //______________Combo Menu Button __________________________________>

                    // PopupMenuButton<int>(
                    //   style: const ButtonStyle(
                    //     padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    //   ),
                    //   itemBuilder: (context) => [
                    //     PopupMenuItem(
                    //       onTap: () async {
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //             builder: (context) =>
                    //                 CreateComboScreen(comboModel: combo),
                    //           ),
                    //         );
                    //       },
                    //       value: 1,
                    //       child: Row(
                    //         children: [
                    //           const Icon(
                    //             IconlyBold.edit,
                    //             color: kGreyTextColor,
                    //           ),
                    //           const SizedBox(width: 10),
                    //           const Text('Edit Combo'),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    //   offset: const Offset(0, 40),
                    //   color: kWhite,
                    //   padding: EdgeInsets.zero,
                    //   elevation: 2,
                    // ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) {
              return Divider(
                color: const Color(0xff808191).withValues(alpha: 0.2),
              );
            },
          );
        },
        error: (e, stack) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(child: Text(e.toString())),
              ),
            ],
          );
        },
        loading: () {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        },
      ),
    );
  }
}