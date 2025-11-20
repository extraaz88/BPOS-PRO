import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/model/hold_order_model.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:mobile_pos/services/hold_order_service.dart';
import '../Sales/Repo/sales_repo.dart';

// Provider for fetching all hold orders (local storage - deprecated)
final holdOrdersProvider = FutureProvider<List<HoldOrderModel>>((ref) async {
  return await HoldOrderService.getAllHoldOrders();
});

// NEW: Provider for fetching held sales from API
final heldSalesProvider =
    FutureProvider<List<SalesTransactionModel>>((ref) async {
  print('\n🔄 Fetching held sales from API...');
  final saleRepo = SaleRepo();
  return await saleRepo.fetchHeldSales();
});

// Provider for hold order restoration state
final holdOrderRestoreProvider =
    StateNotifierProvider<HoldOrderRestoreNotifier, HoldOrderModel?>((ref) {
  return HoldOrderRestoreNotifier();
});

class HoldOrderRestoreNotifier extends StateNotifier<HoldOrderModel?> {
  HoldOrderRestoreNotifier() : super(null);

  void setHoldOrder(HoldOrderModel order) {
    state = order;
  }

  void clearHoldOrder() {
    state = null;
  }
}
