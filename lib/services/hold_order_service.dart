import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos/model/hold_order_model.dart';

class HoldOrderService {
  static const String _holdOrdersKey = 'hold_orders';

  // Get all hold orders
  static Future<List<HoldOrderModel>> getAllHoldOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? holdOrdersJson = prefs.getString(_holdOrdersKey);

    if (holdOrdersJson == null) {
      return [];
    }

    final List<dynamic> holdOrdersList = json.decode(holdOrdersJson);
    return holdOrdersList
        .map((json) => HoldOrderModel.fromMap(json))
        .toList();
  }

  // Get hold orders by type (sale or purchase)
  static Future<List<HoldOrderModel>> getHoldOrdersByType(String type) async {
    final allOrders = await getAllHoldOrders();
    return allOrders.where((order) => order.orderType == type).toList();
  }

  // Add a new hold order
  static Future<String> addHoldOrder(HoldOrderModel order) async {
    final holdOrders = await getAllHoldOrders();

    // Generate a unique ID using timestamp
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    order.id = newId;
    order.createdAt = DateTime.now();
    
    holdOrders.add(order);
    await _saveHoldOrders(holdOrders);
    
    return newId;
  }

  // Update an existing hold order
  static Future<void> updateHoldOrder(HoldOrderModel order) async {
    final holdOrders = await getAllHoldOrders();
    final index = holdOrders.indexWhere((o) => o.id == order.id);

    if (index != -1) {
      holdOrders[index] = order;
      await _saveHoldOrders(holdOrders);
    }
  }

  // Delete a hold order
  static Future<void> deleteHoldOrder(String id) async {
    final holdOrders = await getAllHoldOrders();
    holdOrders.removeWhere((order) => order.id == id);
    await _saveHoldOrders(holdOrders);
  }

  // Delete all hold orders of a specific type
  static Future<void> deleteHoldOrdersByType(String type) async {
    final holdOrders = await getAllHoldOrders();
    holdOrders.removeWhere((order) => order.orderType == type);
    await _saveHoldOrders(holdOrders);
  }

  // Clear all hold orders
  static Future<void> clearAllHoldOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_holdOrdersKey);
  }

  // Private method to save hold orders
  static Future<void> _saveHoldOrders(List<HoldOrderModel> holdOrders) async {
    final prefs = await SharedPreferences.getInstance();
    final holdOrdersJson = json.encode(
      holdOrders.map((order) => order.toMap()).toList(),
    );
    await prefs.setString(_holdOrdersKey, holdOrdersJson);
  }

  // Get count of hold orders by type
  static Future<int> getHoldOrdersCount(String type) async {
    final orders = await getHoldOrdersByType(type);
    return orders.length;
  }

  // Get count of all hold orders
  static Future<int> getAllHoldOrdersCount() async {
    final orders = await getAllHoldOrders();
    return orders.length;
  }
}

