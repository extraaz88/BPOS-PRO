import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';

import '../Repo/parties_repo.dart';

PartyRepository partiesRepo = PartyRepository();

// Default Walk-in Customer
final Party walkInCustomer = Party(
  id: -1,
  name: 'Walk-in Customer',
  phone: '0000000000',
  type: 'Customer',
  email: '',
  address: '',
  due: 0,
  status: 1,
);

// Provider for all parties (Customers + Suppliers)
final partiesProvider = FutureProvider<List<Party>>((ref) async {
  final parties = await partiesRepo.fetchAllParties();
  return [walkInCustomer, ...parties];
});

// Provider for Customers only
final customersProvider = FutureProvider<List<Party>>((ref) async {
  final customers = await partiesRepo.fetchCustomers();
  return [walkInCustomer, ...customers];
});

// Provider for Suppliers only
final suppliersProvider =
    FutureProvider<List<Party>>((ref) => partiesRepo.fetchSuppliers());
