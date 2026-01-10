// ignore_for_file: file_names, unused_element, unused_local_variable

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/profile_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../Model/payment_credential_model.dart';
import '../Model/subscription_plan_model.dart';

class SubscriptionPlanRepo {
  final _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<List<SubscriptionPlanModel>> fetchAllPlans() async {
    final uri = Uri.parse('${APIConfig.url}/plans');
    final token = await getAuthToken();

    print('📡 [Plans List API] Request URL: $uri');
    print('📡 [Plans List API] Token: $token');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': token,
    });

    print('📡 [Plans List API] Response Status: ${response.statusCode}');
    print('📡 [Plans List API] Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      final plans = partyList.map((category) => SubscriptionPlanModel.fromJson(category)).toList();
      
      print('✅ [Plans List API] Total Plans: ${plans.length}');
      for (var plan in plans) {
        print('✅ [Plans List API] Plan: ${plan.subscriptionName} - Duration: ${plan.duration} days - Price: ${plan.subscriptionPrice}');
      }
      
      return plans;
      // Parse into Party objects
    } else {
      print('❌ [Plans List API] Failed with status: ${response.statusCode}');
      throw Exception('Failed to fetch Products');
    }
  }

  Future<PaymentCredentialModel> getPaymentCredential() async {
    final uri = Uri.parse('${APIConfig.url}/gateways');
    final token = await getAuthToken();

    print('📡 [Payment Gateway API] Request URL: $uri');
    print('📡 [Payment Gateway API] Token: $token');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': token,
    });
    
    print('📡 [Payment Gateway API] Response Status: ${response.statusCode}');
    print('📡 [Payment Gateway API] Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final data = parsedData['data'];
      final credentials = PaymentCredentialModel.fromJson(data);
      
      print('✅ [Payment Gateway API] Gateway fetched successfully');
      
      return credentials;
    } else {
      print('❌ [Payment Gateway API] Failed with status: ${response.statusCode}');
      throw Exception('Failed to fetch credential');
    }
  }

  Future<void> subscribePlan({
    required WidgetRef ref,
    required BuildContext context,
    required int planId,
    required String paymentMethod,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/subscribes');
    final token = await getAuthToken();

    print('📡 [Subscribe Plan API] Request URL: $uri');
    print('📡 [Subscribe Plan API] Token: $token');
    print('📡 [Subscribe Plan API] Plan ID: $planId');
    print('📡 [Subscribe Plan API] Payment Method: $paymentMethod');

    var responseData = await http.post(uri, headers: {
      "Accept": 'application/json',
      'Authorization': token,
    }, body: {
      'plan_id': planId.toString(),
      'subscriptionMethod': paymentMethod,
    });

    print('📡 [Subscribe Plan API] Response Status: ${responseData.statusCode}');
    print('📡 [Subscribe Plan API] Response Body: ${responseData.body}');

    try {
      final parsedData = jsonDecode(responseData.body);

      if (responseData.statusCode == 200) {
        print('✅ [Subscribe Plan API] Subscription successful!');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscribe successful!')));
        ref.refresh(businessInfoProvider);
        ref.refresh(getExpireDateProvider(ref));

        Navigator.pop(context);
      } else {
        print('❌ [Subscribe Plan API] Failed: ${parsedData['message']}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subscribe creation failed: ${parsedData['message']}')));
      }
    } catch (error) {
      // Handle unexpected errors gracefully
      print('❌ [Subscribe Plan API] Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
    }
  }
}
