import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/combo_model.dart';
import '../Repo/combo_repo.dart';

ComboRepo comboRepo = ComboRepo();
final comboProvider =
    FutureProvider<List<ComboModel>>((ref) => comboRepo.fetchAllCombos());
