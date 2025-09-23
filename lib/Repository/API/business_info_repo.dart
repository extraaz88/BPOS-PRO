import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/model/business_setting_model.dart';
import 'package:mobile_pos/model/dashboard_overview_model.dart';
import 'package:mobile_pos/model/todays_summary_model.dart';

import '../../http_client/subscription_expire_provider.dart';
import '../../model/business_info_model.dart';
import '../constant_functions.dart';

class BusinessRepository {
  Future<BusinessInformation> fetchBusinessData() async {
    final uri = Uri.parse('${APIConfig.url}/business');
    final token = await getAuthToken();

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      final BusinessInformation businessInformation = BusinessInformation.fromJson(parsedData['data']);

      return businessInformation;
    } else {
      throw Exception('Failed to fetch business data');
    }
  }

  Future<void> fetchSubscriptionExpireDate({required WidgetRef ref}) async {
    final uri = Uri.parse('${APIConfig.url}/business');
    final token = await getAuthToken();

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      final BusinessInformation businessInformation = BusinessInformation.fromJson(parsedData['data']);
      ref.read(subscriptionProvider.notifier).updateSubscription(businessInformation.willExpire);
      // ref.read(subscriptionProvider.notifier).updateSubscription("2025-01-05");
    } else {
      throw Exception('Failed to fetch business data');
    }
  }

  Future<BusinessSettingModel> businessSettingData() async {
    final uri = Uri.parse('${APIConfig.url}/business-settings');
    final token = await getAuthToken();
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    BusinessSettingModel businessSettingModel = BusinessSettingModel(message: null, pictureUrl: null);
    if (response.statusCode == 200) {
      final parseData = jsonDecode(response.body);
      businessSettingModel = BusinessSettingModel.fromJson(parseData);
    }
    return businessSettingModel;
  }

  Future<BusinessInformation?> checkBusinessData() async {
    final uri = Uri.parse('${APIConfig.url}/business');
    final token = await getAuthToken();

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      return BusinessInformation.fromJson(parsedData['data']); // Extract the "data" object from the response
    } else {
      return null;
    }
  }

  Future<TodaysSummaryModel> fetchTodaySummaryData() async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final uri = Uri.parse('${APIConfig.url}/summary?date=$date');
    final token = await getAuthToken();

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      print(response.body);
      return TodaysSummaryModel.fromJson(jsonDecode(response.body)); // Extract the "data" object from the response
    } else {
      // await LogOutRepo().signOut();

      throw Exception('Failed to fetch business data');
    }
  }

  Future<DashboardOverviewModel> dashboardData(String type, {DateTime? fromDate, DateTime? toDate}) async {
    // Map the duration type to the correct API format
    String durationParam;
    switch (type.toLowerCase()) {
      case 'today':
        durationParam = 'today';
        break;
      case 'yesterday':
        durationParam = 'yesterday';
        break;
      case 'last 7 days':
        durationParam = 'last_seven_days';
        break;
      case 'last 30 days':
        durationParam = 'last_thirty_days';
        break;
      case 'current month':
        durationParam = 'current_month';
        break;
      case 'last month':
        durationParam = 'last_month';
        break;
      case 'current year':
        durationParam = 'current_year';
        break;
      case 'custom date':
        durationParam = 'custom_date';
        break;
      case 'weekly':
        durationParam = 'week';
        break;
      case 'monthly':
        durationParam = 'month';
        break;
      case 'yearly':
        durationParam = 'year';
        break;
      default:
        durationParam = type;
    }
    
    // Build URI with custom date parameters if needed
    String url = '${APIConfig.url}/dashboard?duration=$durationParam';
    if (type.toLowerCase() == 'custom date' && fromDate != null && toDate != null) {
      String fromDateStr = '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';
      String toDateStr = '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}';
      url += '&from_date=$fromDateStr&to_date=$toDateStr';
    }
    
    final uri = Uri.parse(url);
    final token = await getAuthToken();
    
    print('Dashboard API URL: $uri');
    print('Dashboard API Token: $token');
    print('Original type: $type, Mapped duration: $durationParam');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
    });
    print('Dashboard API Response Status: ${response.statusCode}');
    print('Dashboard API Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        print('Dashboard API Response Data: $responseData');
        
        // Check if the response has a 'data' wrapper like other endpoints
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          return DashboardOverviewModel.fromJson(responseData['data']);
        } else {
          return DashboardOverviewModel.fromJson(responseData);
        }
      } catch (e) {
        print('JSON Parsing Error: $e');
        throw Exception('Failed to parse dashboard data: $e');
      }
    } else {
      // await LogOutRepo().signOut();

      throw Exception('Failed to fetch business data ${response.statusCode}');
    }
  }
}
