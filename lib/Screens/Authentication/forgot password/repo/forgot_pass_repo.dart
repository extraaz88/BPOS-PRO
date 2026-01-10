import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;

import '../../../../Const/api_config.dart';

class ForgotPassRepo {
  Future<bool> forgotPass({required String email, required BuildContext context}) async {
    final url = Uri.parse('${APIConfig.url}/send-reset-code');

    final body = {
      'email': email,
    };
    final headers = {
      'Accept': 'application/json',
    };

    print('====== FORGOT PASSWORD API ======');
    print('Request URL: $url');
    print('Request Body: $body');
    print('Request Headers: $headers');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================');

      final responseData = jsonDecode(response.body);
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Please try again')));
    } finally {}

    return false;
  }

  Future<bool> verifyOTPForgotPass({required String email, required String otp, required BuildContext context}) async {
    final url = Uri.parse('${APIConfig.url}/verify-reset-code');

    final body = {
      'email': email,
      'code': otp,
    };
    final headers = {
      'Accept': 'application/json',
    };

    print('====== VERIFY OTP API ======');
    print('Request URL: $url');
    print('Request Body: $body');
    print('Request Headers: $headers');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================');

      final responseData = jsonDecode(response.body);
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['error'])));
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Please try again')));
    } finally {}

    return false;
  }

  Future<bool> resetPass({required String email, required String password, required BuildContext context}) async {
    final url = Uri.parse('${APIConfig.url}/password-reset');

    final body = {
      'email': email,
      "password": password,
    };
    final headers = {
      'Accept': 'application/json',
    };

    print('====== RESET PASSWORD API ======');
    print('Request URL: $url');
    print('Request Body: $body');
    print('Request Headers: $headers');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================');

      final responseData = jsonDecode(response.body);
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Please try again')));
    } finally {}

    return false;
  }
}
