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
final dashboardInfoProvider = FutureProvider.family
    .autoDispose<DashboardOverviewModel, String>(
        (ref, type) => businessRepository.dashboardData(type));

// Custom date provider
final customDateProvider = StateProvider<Map<String, DateTime?>>((ref) => {
  'fromDate': null,
  'toDate': null,
});

final dashboardCustomDateProvider = FutureProvider.family
    .autoDispose<DashboardOverviewModel, Map<String, dynamic>>(
        (ref, params) => businessRepository.dashboardData(
          params['type'] as String,
          fromDate: params['fromDate'] as DateTime?,
          toDate: params['toDate'] as DateTime?,
        ));
