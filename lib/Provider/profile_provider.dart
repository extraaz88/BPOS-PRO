import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/model/business_info_model.dart';
import 'package:mobile_pos/model/business_setting_model.dart';
import 'package:mobile_pos/model/dashboard_overview_model.dart';

import '../Repository/API/business_info_repo.dart';
import '../model/todays_summary_model.dart';

BusinessRepository businessRepository = BusinessRepository();
final businessInfoProvider = FutureProvider<BusinessInformation>(
    (ref) => businessRepository.fetchBusinessData());
final getExpireDateProvider = FutureProvider.family<void, WidgetRef>(
    (ref, widgetRef) =>
        businessRepository.fetchSubscriptionExpireDate(ref: widgetRef));
final businessSettingProvider = FutureProvider<BusinessSettingModel>(
    (ref) => businessRepository.businessSettingData());
final summaryInfoProvider = FutureProvider<TodaysSummaryModel>(
    (ref) => businessRepository.fetchTodaySummaryData());

// Parameter class for dashboard requests
class DashboardParams {
  final String type;
  final DateTime? fromDate;
  final DateTime? toDate;

  DashboardParams({
    required this.type,
    this.fromDate,
    this.toDate,
  });

  // Override equality for Riverpod to properly cache
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => type.hashCode ^ fromDate.hashCode ^ toDate.hashCode;
}

final dashboardInfoProvider = FutureProvider.family
    .autoDispose<DashboardOverviewModel, DashboardParams>(
        (ref, params) => businessRepository.dashboardData(
              params.type,
              fromDate: params.fromDate,
              toDate: params.toDate,
            ));
