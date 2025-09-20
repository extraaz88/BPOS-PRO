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

  Future<DashboardOverviewModel> dashboardData(String type) async {
    final token = await getAuthToken();
    
    // Try different duration formats in order of likelihood
    List<String> durationFormats = [];
    switch (type.toLowerCase()) {
      case 'weekly':
        durationFormats = ['7', 'week', 'weekly', '1w', '1week'];
        break;
      case 'monthly':
        durationFormats = ['30', 'month', 'monthly', '1m', '1month'];
        break;
      case 'yearly':
        durationFormats = ['365', 'year', 'yearly', '1y', '1year'];
        break;
      default:
        durationFormats = [type];
    }
    
    for (String durationParam in durationFormats) {
      final uri = Uri.parse('${APIConfig.url}/dashboard?duration=$durationParam');
      
      print('Trying Dashboard API URL: $uri');
      print('Dashboard API Token: Bearer $token');
      print('Original type: $type, Trying duration: $durationParam');

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
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
      } else if (response.statusCode == 400) {
        // If it's a 400 error with "Invalid duration", try the next format
        print('Duration "$durationParam" invalid, trying next format...');
        continue;
      } else {
        // For other errors, throw immediately
        throw Exception('Failed to fetch business data ${response.statusCode}');
      }
    }
    
    // If all formats failed
    throw Exception('All duration formats failed for type: $type');
  }
}
