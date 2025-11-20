import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';

import '../Screens/Products/Repo/product_repo.dart';

ProductRepo productRepo = ProductRepo();
final productProvider =
    FutureProvider<List<ProductModel>>((ref) => productRepo.fetchAllProducts());

// Provider for low stock products only
final lowStockProvider = FutureProvider<List<ProductModel>>((ref) async {
  final products = await productRepo.fetchAllProducts();
  return products
      .where(
          (product) => (product.productStock ?? 0) <= (product.alertQty ?? 0))
      .toList();
});

// Provider for low stock count
final lowStockCountProvider = FutureProvider<int>((ref) async {
  final products = await productRepo.fetchAllProducts();
  return products
      .where(
          (product) => (product.productStock ?? 0) <= (product.alertQty ?? 0))
      .length;
});
