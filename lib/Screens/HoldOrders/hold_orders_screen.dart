import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/HoldOrders/hold_orders_provider.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/model/hold_order_model.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:mobile_pos/services/hold_order_service.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../Customers/Model/parties_model.dart' as parties;
import '../Customers/Provider/customer_provider.dart';
import '../Purchase/add_and_edit_purchase.dart';
import '../Sales/add_sales.dart';
import '../Sales/Repo/sales_repo.dart';
import '../Purchase/Model/purchase_transaction_model.dart';
import '../Purchase/Repo/purchase_repo.dart';

class HoldOrdersScreen extends ConsumerStatefulWidget {
  const HoldOrdersScreen({super.key});

  @override
  ConsumerState<HoldOrdersScreen> createState() => _HoldOrdersScreenState();
}

class _HoldOrdersScreenState extends ConsumerState<HoldOrdersScreen>
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

  // Method to restore hold order
  Future<void> _restoreHoldOrder(HoldOrderModel order) async {
    final partiesData = ref.read(partiesProvider);

    await partiesData.when(
      data: (partiesList) async {
        parties.Party? customer;

        // Find customer if customerId is set
        if (order.customerId != null && order.customerId! > 0) {
          try {
            customer = partiesList.firstWhere(
              (party) => party.id == order.customerId,
            );
          } catch (e) {
            // Customer not found, will use walk-in
            customer = null;
          }
        }

        // Navigate to appropriate screen based on order type
        if (order.orderType == 'sale') {
          // Store the hold order data in provider
          ref.read(holdOrderRestoreProvider.notifier).setHoldOrder(order);

          // Navigate to Add Sales screen
          Navigator.pop(context); // Close hold orders screen
          await AddSalesScreen(
            customerModel: customer,
            transitionModel: null,
          ).launch(context);
        } else if (order.orderType == 'purchase') {
          // Store the hold order data in provider
          ref.read(holdOrderRestoreProvider.notifier).setHoldOrder(order);

          // Navigate to Add Purchase screen
          Navigator.pop(context); // Close hold orders screen
          await AddAndUpdatePurchaseScreen(
            supplierModel: customer,
            transitionModel: null,
          ).launch(context);
        }
      },
      loading: () {
        EasyLoading.showError('Loading customer data...');
      },
      error: (error, stack) {
        EasyLoading.showError('Error loading customer data: $error');
      },
    );
  }

  // Method to delete hold order
  Future<void> _deleteHoldOrder(String id) async {
    await HoldOrderService.deleteHoldOrder(id);
    ref.invalidate(holdOrdersProvider);
    EasyLoading.showSuccess('Hold order deleted');
  }

  // Show confirmation dialog before deleting
  Future<void> _showDeleteConfirmation(HoldOrderModel order) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hold Order'),
        content: Text(
            'Are you sure you want to delete this hold order for ${order.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHoldOrder(order.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch held sales from API
    final heldSalesData = ref.watch(heldSalesProvider);
    // Fetch held purchases from API
    final heldPurchasesData = ref.watch(heldPurchasesProvider);

    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2.0,
          surfaceTintColor: kWhite,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Hold Orders',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: kMainColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kMainColor,
            tabs: const [
              Tab(text: 'Sales (API)'), // Indicate API source
              Tab(text: 'Purchase (API)'), // Updated to show API source
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Sales Tab - From API
            _buildHeldSalesTab(heldSalesData),
            // Purchase Tab - From API
            _buildHeldPurchasesTab(heldPurchasesData),
          ],
        ),
      ),
    );
  }

  // Widget for Sales tab using API data
  Widget _buildHeldSalesTab(
      AsyncValue<List<SalesTransactionModel>> heldSalesData) {
    return heldSalesData.when(
      data: (sales) {
        print('📊 Displaying ${sales.length} held sales from API');

        if (sales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Held Sales',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Held sales from API will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(heldSalesProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(heldSalesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildHeldSaleCard(sale);
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading held sales from API...'),
          ],
        ),
      ),
      error: (error, stack) {
        print('❌ Error loading held sales: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading held sales',
                style: TextStyle(fontSize: 18, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(heldSalesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for Purchase tab using API data
  Widget _buildHeldPurchasesTab(
      AsyncValue<List<PurchaseTransaction>> heldPurchasesData) {
    return heldPurchasesData.when(
      data: (purchases) {
        print('📊 Displaying ${purchases.length} held purchases from API');

        if (purchases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No held purchases found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hold purchases will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final purchase = purchases[index];
            return _buildHeldPurchaseCard(purchase);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading held purchases',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(heldPurchasesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Build card for held sale from API
  Widget _buildHeldSaleCard(SalesTransactionModel sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implement restore functionality
          toast('Restore functionality coming soon');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.party?.name ?? 'Walk-in Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sale.party?.phone ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'HELD',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${sale.invoiceNumber ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sale.saleDate ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sale.salesDetails?.length ?? 0} Items',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '$currency${sale.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kMainColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Held Sale'),
                            content: const Text(
                                'Are you sure you want to delete this held sale?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && sale.id != null) {
                          EasyLoading.show(status: 'Deleting...');
                          final saleRepo = SaleRepo();
                          final success = await saleRepo.deleteHeldSale(
                              saleId: sale.id!.toInt());
                          EasyLoading.dismiss();

                          if (success) {
                            ref.invalidate(heldSalesProvider);
                            EasyLoading.showSuccess('Held sale deleted');
                          } else {
                            EasyLoading.showError('Failed to delete');
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        toast('Restore functionality coming soon');
                      },
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Restore'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build card for held purchase from API
  Widget _buildHeldPurchaseCard(PurchaseTransaction purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implement restore functionality
          toast('Restore functionality coming soon');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.party?.name ?? 'Walk-in Supplier',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purchase.party?.phone ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'HOLD',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${purchase.id ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        purchase.purchaseDate ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${purchase.details?.length ?? 0} Items',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '$currency${purchase.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kMainColor,
                    ),
                  ),
                ],
              ),
              if (purchase.dueAmount != null && purchase.dueAmount! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Due Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$currency${purchase.dueAmount!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Hold Purchase'),
                            content: const Text(
                                'Are you sure you want to delete this hold purchase?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && purchase.id != null) {
                          EasyLoading.show(status: 'Deleting...');

                          // Call the actual delete API
                          final purchaseRepo = PurchaseRepo();
                          final success = await purchaseRepo.deleteHeldPurchase(
                            id: purchase.id.toString(),
                            context: context,
                            ref: ref,
                          );

                          if (success) {
                            // Refresh the held purchases list
                            ref.invalidate(heldPurchasesProvider);
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        toast('Restore functionality coming soon');
                      },
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Restore'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<HoldOrderModel> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type == 'sale' ? 'Sales' : 'Purchase'} Hold Orders',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hold orders will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(HoldOrderModel order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: kMainColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _restoreHoldOrder(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName ?? 'Walk-in Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.customerPhone != null &&
                            order.customerPhone!.isNotEmpty)
                          Text(
                            order.customerPhone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: order.orderType == 'sale'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: order.orderType == 'sale'
                            ? Colors.green
                            : Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      order.orderType == 'sale' ? 'SALE' : 'PURCHASE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: order.orderType == 'sale'
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items: ${order.items?.length ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.date ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '$currency${order.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kMainColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (order.items != null && order.items!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  'Products:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ...order.items!.take(3).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${item.productName} (${item.quantity?.toInt() ?? 0})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                if (order.items!.length > 3)
                  Text(
                    '  +${order.items!.length - 3} more...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreHoldOrder(order),
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMainColor,
                        side: const BorderSide(color: kMainColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showDeleteConfirmation(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Icon(Icons.delete, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
