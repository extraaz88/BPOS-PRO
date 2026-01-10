import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../../../currency.dart';

class RegisterRepo {
  Map<String, String> get _jsonHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// Send OTP to WhatsApp for the provided phone + email
  Future<bool> sendOtp({
    required String phone,
    required String email,
    required BuildContext context,
  }) async {
    EasyLoading.show(status: 'Sending OTP...');
    final uri = Uri.parse('${APIConfig.url}/whatsapp/send-otp');

    try {
      print('📡 [Send OTP] url: $uri');
      print('📦 [Send OTP] body: {phone: $phone, email: $email}');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode({'phone': phone, 'email': email}),
      );

      EasyLoading.dismiss();
      print('📩 [Send OTP] status: ${response.statusCode}');
      print('📩 [Send OTP] raw: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'OTP sent successfully')),
        );
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
      );
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
      return false;
    }
  }

  /// Resend OTP to WhatsApp
  Future<bool> resendOtp({
    required String phone,
    required String email,
    required BuildContext context,
  }) async {
    EasyLoading.show(status: 'Resending OTP...');
    final uri = Uri.parse('${APIConfig.url}/whatsapp/resend-otp');

    try {
      print('📡 [Resend OTP] url: $uri');
      print('📦 [Resend OTP] body: {phone: $phone, email: $email}');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode({'phone': phone, 'email': email}),
      );

      EasyLoading.dismiss();
      print('📩 [Resend OTP] status: ${response.statusCode}');
      print('📩 [Resend OTP] raw: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'OTP resent')),
        );
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to resend OTP')),
      );
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resending OTP: $e')),
      );
      return false;
    }
  }

  /// Verify OTP and persist token/role/currency if returned
  Future<bool> verifyOtp({
    required String phone,
    required String email,
    required String otp,
    required BuildContext context,
  }) async {
    EasyLoading.show(status: 'Verifying OTP...');
    final uri = Uri.parse('${APIConfig.url}/whatsapp/verify-otp');

    try {
      print('📡 [Verify OTP] url: $uri');
      print('📦 [Verify OTP] body: {phone: $phone, email: $email, otp: $otp}');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode({'phone': phone, 'email': email, 'otp': otp}),
      );

      EasyLoading.dismiss();
      print('📩 [Verify OTP] status: ${response.statusCode}');
      print('📩 [Verify OTP] raw: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'OTP verified')),
        );

        if (data['currency'] != null) {
          await CurrencyMethods().saveCurrencyDataInLocalDatabase(
            selectedCurrencySymbol: data['currency']['symbol'],
            selectedCurrencyName: data['currency']['name'],
          );
        }

        final token = data['token'];
        if (token != null) {
          var cleanToken = token.toString();
          if (cleanToken.toLowerCase().startsWith('bearer ')) {
            cleanToken = cleanToken.substring(7);
          }

          Map<String, dynamic>? visibilityMap;
          if (data['visibility'] != null) {
            if (data['visibility'] is Map) {
              visibilityMap = Map<String, dynamic>.from(data['visibility']);
            }
          }

          await saveUserData(
            token: cleanToken,
            role: data['role'],
            visibility: visibilityMap,
          );
        }

        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? data['error'] ?? 'OTP verification failed'),
        ),
      );
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying OTP: $e')),
      );
      return false;
    }
  }

  /// Complete business registration after OTP verification
  Future<bool> registerBusiness({
    required String businessCategory,
    required String name,
    required String businessName,
    required String businessAddress,
    required String phone,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    EasyLoading.show(status: 'Creating account...');
    final uri = Uri.parse('${APIConfig.url}/sign-up');

    try {
      final payload = {
        'business_category': businessCategory,
        'name': name,
        'business_name': businessName,
        'business_address': businessAddress,
        'phone': phone,
        'email': email,
        'password': password,
      };
      print('📡 [Register] url: $uri');
      print('📦 [Register] body: $payload');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode(payload),
      );

      EasyLoading.dismiss();
      print('📩 [Register] status: ${response.statusCode}');
      print('📩 [Register] raw: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Registered successfully')),
        );
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Registration failed')),
      );
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering: $e')),
      );
      return false;
    }
  }
}

