import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Combo/Provider/combo_provider.dart';
import 'package:mobile_pos/Combo/Repo/combo_repo.dart';
import 'package:mobile_pos/Combo/create_combo_screen.dart';
import 'package:mobile_pos/Combo/Model/combo_model.dart';
import 'package:mobile_pos/Const/api_config.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart';
import '../../currency.dart';

class ComboListScreen extends StatefulWidget {
  const ComboListScreen({super.key});

  @override
  State<ComboListScreen> createState() => _ComboListScreenState();
}

class _ComboListScreenState extends State<ComboListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          title: const Text(
            'Combo List',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: kMainColor,
            labelColor: kMainColor,
            unselectedLabelColor: kGreyTextColor,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Inactive'),
            ],
          ),
        ),
        body: Consumer(
          builder: (context, ref, __) {
            final combos = ref.watch(comboProvider);

            return combos.when(
              // Replace variable name comboList -> comboData and normalize it
              data: (comboData) {
                final comboList = _normalizeComboList(comboData);

                // Debug: Print all combo statuses
                print('=== COMBO FILTERING DEBUG ===');
                for (var combo in comboList) {
                  print(
                      'Combo: ${combo.comboName}, Status: "${combo.productStatus}"');
                }
                print('Total combos: ${comboList.length}');

                // Filter combos based on product_status
                final activeCombos = comboList.where((combo) {
                  if (combo.productStatus == null) return false;
                  final status = combo.productStatus!.toLowerCase().trim();
                  final isActive = status == 'active';
                  print(
                      'Combo "${combo.comboName}": status="$status", isActive=$isActive');
                  return isActive;
                }).toList();

                final inactiveCombos = comboList.where((combo) {
                  if (combo.productStatus == null) return false;
                  final status = combo.productStatus!.toLowerCase().trim();
                  final isInactive = status == 'inactive';
                  return isInactive;
                }).toList();

                print('Active combos: ${activeCombos.length}');
                print('Inactive combos: ${inactiveCombos.length}');
                print('=== END FILTERING DEBUG ===');

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Tab
                    _buildComboList(context, ref, activeCombos, 'Active'),
                    // Inactive Tab
                    _buildComboList(context, ref, inactiveCombos, 'Inactive'),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading combos',
                      style: TextStyle(
                        fontSize: 18,
                        color: kGreyTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await ref.refresh(comboProvider.future);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, __) {
            return FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateComboScreen(),
                  ),
                );
                // Refresh combo list after creating new combo
                ref.invalidate(comboProvider);
                // Switch to Active tab
                _tabController.animateTo(0);
              },
              backgroundColor: kMainColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Combo Kit',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }

  // New helper: normalize provider response into a List<ComboModel>
  List<ComboModel> _normalizeComboList(dynamic comboData) {
    try {
      if (comboData == null) return <ComboModel>[];

      // Already a List (could be List<ComboModel> or List<Map>)
      if (comboData is List) {
        return comboData
            .map<ComboModel>((e) =>
                e is ComboModel ? e : ComboModel.fromJson(e ?? <String, dynamic>{}))
            .toList();
      }

      // If it's a Map, try common keys like 'data' or find the first List value
      if (comboData is Map) {
        dynamic listCandidate =
            comboData['data'] ?? comboData['combos'] ?? comboData['records'];

        if (listCandidate == null) {
          for (var v in comboData.values) {
            if (v is List) {
              listCandidate = v;
              break;
            }
          }
        }

        if (listCandidate is List) {
          return listCandidate
              .map<ComboModel>((e) => e is ComboModel ? e : ComboModel.fromJson(e ?? <String, dynamic>{}))
              .toList();
        }

        // As a last resort, convert map values if they look like combo entries
        return comboData.values
            .where((v) => v != null)
            .map<ComboModel>((e) => e is ComboModel ? e : ComboModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error normalizing combo data: $e');
    }
    return <ComboModel>[];
  }

  Widget _buildComboList(
      BuildContext context, WidgetRef ref, List comboList, String tabType) {
    if (comboList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: kGreyTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${tabType.toLowerCase()} combos found',
              style: TextStyle(
                fontSize: 18,
                color: kGreyTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (tabType == 'Active')
              Text(
                'Tap the + button to create your first combo',
                style: TextStyle(
                  fontSize: 14,
                  color: kGreyTextColor,
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(comboProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: comboList.length,
        itemBuilder: (context, index) {
          final combo = comboList[index];
          return _buildComboCard(context, ref, combo);
        },
      ),
    );
  }

  // New helper: return absolute image URL if already absolute, otherwise prefix domain
  String _resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return '';
    final trimmed = imagePath.trim();
    // If already absolute URL, return as-is
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // Otherwise prefix domain (APIConfig.domain is expected to include protocol and host)
    return '${APIConfig.domain}$trimmed';
  }

  Widget _buildComboCard(
    BuildContext context,
    WidgetRef ref,
    combo,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to combo details
          _showComboDetails(context, ref, combo);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Combo Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (() {
                  final imgUrl = _resolveImageUrl(combo.comboImage);
                  if (imgUrl.isNotEmpty) {
                    return Image.network(
                      imgUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: kGreyTextColor.withOpacity(0.1),
                          child: Icon(
                            Icons.image_not_supported,
                            color: kGreyTextColor,
                            size: 32,
                          ),
                        );
                      },
                    );
                  } else {
                    return Container(
                      width: 80,
                      height: 80,
                      color: kGreyTextColor.withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        color: kGreyTextColor,
                        size: 32,
                      ),
                    );
                  }
                }()),
              ),
              const SizedBox(width: 16),
              // Combo Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      combo.comboName ?? 'Unnamed Combo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${combo.products?.length ?? 0} products',
                      style: TextStyle(
                        fontSize: 14,
                        color: kGreyTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency${combo.finalPrice?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kMainColor,
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
  }

  void _showComboDetails(BuildContext context, WidgetRef ref, combo) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, refConsumer, __) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 500, maxHeight: 600),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                combo.comboName ?? 'Combo Details',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Combo Image
                          if (combo.comboImage != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (() {
                                  final imgUrl = _resolveImageUrl(combo.comboImage);
                                  if (imgUrl.isNotEmpty) {
                                    return Image.network(
                                      imgUrl,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 200,
                                          height: 200,
                                          color:
                                              kGreyTextColor.withOpacity(0.1),
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: kGreyTextColor,
                                            size: 50,
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: kGreyTextColor.withOpacity(0.1),
                                      child: Icon(
                                        Icons.image,
                                        color: kGreyTextColor,
                                        size: 50,
                                      ),
                                    );
                                  }
                                }()),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Details
                          _buildDetailRow(
                              'Combo Name', combo.comboName ?? 'N/A'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Products Count',
                              '${combo.products?.length ?? 0}'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Subtotal',
                              '$currency${combo.subtotal?.toStringAsFixed(2) ?? '0.00'}'),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                              'Discount Type', combo.discountType ?? 'N/A'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Discount Value',
                              '$currency${combo.discountValue?.toStringAsFixed(2) ?? '0.00'}'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Final Price',
                              '$currency${combo.finalPrice?.toStringAsFixed(2) ?? '0.00'}',
                              isHighlight: true),
                          const SizedBox(height: 12),
                          // Status Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kGreyTextColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    combo.productStatus?.toLowerCase() ==
                                            'active'
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          combo.productStatus?.toLowerCase() ==
                                                  'active'
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Switch(
                                    value: combo.productStatus?.toLowerCase() ==
                                        'active',
                                    onChanged: (value) async {
                                      print('=== TOGGLE STATUS DEBUG ===');
                                      print(
                                          'Combo ID (combo_kit): ${combo.id}');
                                      print(
                                          'Product ID (outer): ${combo.productId}');
                                      print('Combo Name: ${combo.comboName}');
                                      print(
                                          'Current Status: ${combo.productStatus}');

                                      if (combo.productId == null) {
                                        print('ERROR: productId is null!');
                                        print(
                                            'This might happen if the combo list needs to be refreshed.');
                                        EasyLoading.showError(
                                            'Invalid product ID. Please refresh the combo list.');
                                        // Try to refresh the combo list
                                        refConsumer.invalidate(comboProvider);
                                        return;
                                      }

                                      final newStatus =
                                          value ? 'active' : 'inactive';

                                      setState(() {
                                        // Toggle the status visually
                                        combo.productStatus = newStatus;
                                      });

                                      try {
                                        final comboRepo = ComboRepo();
                                        await comboRepo.updateComboKitStatus(
                                          productId: combo.productId!,
                                          status: newStatus,
                                          ref: refConsumer,
                                          context: context,
                                        );

                                        // Refresh combo list
                                        refConsumer.invalidate(comboProvider);
                                      } catch (e) {
                                        // Revert on error
                                        setState(() {
                                          combo.productStatus =
                                              value ? 'inactive' : 'active';
                                        });
                                        print(
                                            'Error updating combo status: $e');
                                      }
                                    },
                                    activeColor: kMainColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Products List
                          if (combo.products != null &&
                              combo.products!.isNotEmpty) ...[
                            const Text(
                              'Products:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...combo.products!.map((product) => InkWell(
                                  onTap: () {
                                    // Show popup when product is clicked
                                    _showProductStatusPopup(
                                        context, refConsumer, combo, product);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.productName ??
                                                    'Unknown Product',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ),
                                            Text(
                                              '$currency${product.productPrice?.toStringAsFixed(2) ?? '0.00'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: kMainColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Quantity: ${product.quantity ?? 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: kGreyTextColor,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: kGreyTextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? kMainColor : Colors.black,
          ),
        ),
      ],
    );
  }

  void _showProductStatusPopup(BuildContext context, WidgetRef ref,
      ComboModel combo, ComboProduct product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            product.productName ?? 'Product',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Combo: ${combo.comboName ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: kGreyTextColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Product Status:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateProductStatus(
                    context, ref, combo, product, 'active');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Active'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateProductStatus(
                    context, ref, combo, product, 'inactive');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactive'),
            ),
          ],
        );
      },
    );
  }

  // New helper: resolve product id from ComboProduct (checks productId, nested product)
  num? _resolveProductId(ComboProduct product) {
    if (product.productId != null) return product.productId;
    if (product.product != null && product.product is Map) {
      final dynamic pid = product.product['id'] ?? product.product['product_id'] ?? product.product['productId'];
      if (pid != null) {
        if (pid is num) return pid;
        final parsed = num.tryParse(pid.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<void> _updateProductStatus(BuildContext context, WidgetRef ref,
      ComboModel combo, ComboProduct product, String status) async {
    // First try to resolve canonical product id
    final resolvedProductId = _resolveProductId(product);

    // If primary resolution missing, allow one fallback attempt using the combo_product relation id
    num? fallbackProductId;
    if (resolvedProductId == null && product.id != null) {
      // Use combo_product relation id as a last-resort fallback (may or may not be accepted by server)
      fallbackProductId = product.id;
      print('Resolved product id is null — will attempt fallback using combo_product relation id: $fallbackProductId');
    }

    if (combo.id == null && resolvedProductId == null && fallbackProductId == null) {
      print('Invalid IDs while updating product status. combo.id=${combo.id}, resolvedProductId=$resolvedProductId, fallbackProductId=$fallbackProductId, original product.productId=${product.productId}, nested product=${product.product}');
      EasyLoading.showError('Invalid combo or product ID. Please refresh the combo list and try again.');
      ref.invalidate(comboProvider);
      return;
    }

    try {
      EasyLoading.show(status: 'Updating status...');

      final comboRepo = ComboRepo();

      // Try primary resolved id first
      if (resolvedProductId != null && combo.id != null) {
        print('=== PRODUCT STATUS UPDATE (primary) ===');
        print('Combo Product ID (relation id): ${product.id}');
        print('Resolved Product ID: $resolvedProductId');
        print('Combo ID: ${combo.id}');
        print('Status: $status');

        await comboRepo.updateComboStatus(
          comboId: combo.id!,
          productId: resolvedProductId,
          status: status,
          comboProductId: product.id,
        );

        EasyLoading.showSuccess('Status updated successfully!');
        ref.invalidate(comboProvider);
        return;
      }

      // If primary failed or missing, try fallback using combo_product relation id
      if (fallbackProductId != null && combo.id != null) {
        print('=== PRODUCT STATUS UPDATE (fallback) ===');
        print('Using combo_product relation id as product_id: $fallbackProductId');
        print('Combo Product ID (relation id): ${product.id}');
        print('Combo ID: ${combo.id}');
        print('Status: $status');

        await comboRepo.updateComboStatus(
          comboId: combo.id!,
          productId: fallbackProductId,
          status: status,
          comboProductId: product.id,
        );

        EasyLoading.showSuccess('Status updated (fallback) — refresh to confirm.');
        ref.invalidate(comboProvider);
        return;
      }

      // If we reach here, we don't have usable IDs
      print('Failed to update: no usable product id or combo id.');
      EasyLoading.showError('Invalid product or combo id. Please refresh and try again.');
      ref.invalidate(comboProvider);
    } catch (e) {
      print('Error updating product status: $e');
      EasyLoading.showError('Failed to update status: $e');
      // Refresh to allow client to recover / pick correct ids from server
      ref.invalidate(comboProvider);
    }
  }
}
