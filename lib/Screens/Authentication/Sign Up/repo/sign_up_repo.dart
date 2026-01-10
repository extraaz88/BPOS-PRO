import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Const/api_config.dart';
import '../../../../Repository/constant_functions.dart';
import '../../../../currency.dart';

class SignUpRepo {
  Future<bool> signUp({
    required String name, 
    required String email, 
    required String password,
    String? businessName,
    String? category,
    required BuildContext context,
  }) async {
    final url = Uri.parse('${APIConfig.url}/sign-up');

    final body = {
      'name': name,
      'email': email,
      'password': password,
    };
    
    if (businessName != null && businessName.isNotEmpty) {
      body['business_name'] = businessName;
    }
    if (category != null && category.isNotEmpty) {
      body['category'] = category;
    }
    final headers = {
      'Accept': 'application/json',
    };

    try {
      print('🔥🔥 SIGNUP FUNCTION CALLED !!!!');
      print('📡 [Sign Up API] URL: $url');
      print('📡 [Sign Up API] Headers: $headers');
      print('📡 [Sign Up API] Body: $body');
      final response = await http.post(url, headers: headers, body: body);

      final responseData = jsonDecode(response.body);
      print('Sign Up API response: $responseData');
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Please try again')));
    } finally {}

    return false;
  }

  Future<bool> verifyOTP({
    required String email, 
    required String otp, 
    required BuildContext context,
    String? name,
    String? password,
    String? businessName,
    String? category,
  }) async {
    // First verify the OTP
    final verifyUrl = Uri.parse('${APIConfig.url}/submit-otp');

    final verifyBody = {
      'email': email,
      'otp': otp,
    };
    final headers = {
      'Accept': 'application/json',
    };

    try {
      print('📡 [Verify OTP API] URL: $verifyUrl');
      print('📡 [Verify OTP API] Headers: $headers');
      print('📡 [Verify OTP API] Body: $verifyBody');
      final verifyResponse = await http.post(verifyUrl, headers: headers, body: verifyBody);
      print('📩 [Verify OTP API] status: ${verifyResponse.statusCode}');
      print('📩 [Verify OTP API] raw response: ${verifyResponse.body}');
      final verifyResponseData = jsonDecode(verifyResponse.body);
      
      if (verifyResponse.statusCode == 200) {
        // OTP verified successfully, now register the user if name and password are provided
        if (name != null && password != null) {
          final registerUrl = Uri.parse('${APIConfig.url}/sign-up');
          
          final registerBody = {
            'name': name,
            'email': email,
            'password': password,
          };
          
          // Add business_name and category if provided
          if (businessName != null && businessName.isNotEmpty) {
            registerBody['business_name'] = businessName;
          }
          if (category != null && category.isNotEmpty) {
            registerBody['category'] = category;
          }
          
          print('📡 [Register after OTP API] URL: $registerUrl');
          print('📡 [Register after OTP API] Headers: $headers');
          print('📡 [Register after OTP API] Body: $registerBody');
          final registerResponse = await http.post(registerUrl, headers: headers, body: registerBody);
          print('📩 [Register after OTP API] status: ${registerResponse.statusCode}');
          print('📩 [Register after OTP API] raw response: ${registerResponse.body}');
          final registerResponseData = jsonDecode(registerResponse.body);
          
          EasyLoading.dismiss();
          
          if (registerResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(registerResponseData['message'] ?? 'Registration successful!')),
            );

            // Save token and currency data from registration response
            String? token = registerResponseData['token'];
            if (registerResponseData['currency'] != null) {
              await CurrencyMethods().saveCurrencyDataInLocalDatabase(
                selectedCurrencySymbol: registerResponseData['currency']['symbol'], 
                selectedCurrencyName: registerResponseData['currency']['name']
              );
            }
            if (token != null) {
              // Ensure token doesn't have Bearer prefix
              String cleanToken = token;
              if (cleanToken.toLowerCase().startsWith('bearer ')) {
                cleanToken = cleanToken.substring(7);
              }
              
              // Handle visibility - it can be a List or Map
              Map<String, dynamic>? visibilityMap;
              if (registerResponseData['visibility'] != null) {
                if (registerResponseData['visibility'] is List) {
                  visibilityMap = null;
                } else if (registerResponseData['visibility'] is Map) {
                  visibilityMap = Map<String, dynamic>.from(registerResponseData['visibility']);
                }
              }
              
              await saveUserData(
                token: cleanToken,
                role: registerResponseData['role'],
                visibility: visibilityMap,
              );
              
              // Wait a bit to ensure token is fully saved
              await Future.delayed(const Duration(milliseconds: 100));
            }

            return true;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(registerResponseData['message'] ?? 'Registration failed')),
            );
            return false;
          }
        } else {
          // OTP verified but no registration needed (for forgot password flow)
          EasyLoading.dismiss();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(verifyResponseData['message'] ?? 'OTP verified successfully')),
          );
          
          String? token = verifyResponseData['token'];
          if (verifyResponseData['currency'] != null) {
            await CurrencyMethods().saveCurrencyDataInLocalDatabase(
              selectedCurrencySymbol: verifyResponseData['currency']['symbol'], 
              selectedCurrencyName: verifyResponseData['currency']['name']
            );
          }
          if (token != null) {
            await saveUserData(token: token);
          }
          
          return true;
        }
      } else {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(verifyResponseData['error'] ?? 'OTP verification failed')),
        );
        return false;
      }
    } catch (error) {
      EasyLoading.dismiss();
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      return false;
    }
  }

  Future<bool> resendOTP({required String email, required BuildContext context}) async {
    final url = Uri.parse('${APIConfig.url}/resend-otp');

    final body = {
      'email': email,
    };
    final headers = {
      'Accept': 'application/json',
    };

    try {
      final response = await http.post(url, headers: headers, body: body);

      final responseData = jsonDecode(response.body);
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['error'])));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Please try again')));
    } finally {}

    return false;
  }

  /// Send WhatsApp OTP for phone number verification
  Future<Map<String, dynamic>?> sendWhatsAppOTP({
    required String phone,
    required String email,
    required BuildContext context,
  }) async {
    final url = Uri.parse('https://bharatbill.live/api/v1/whatsapp/send-otp');

    final body = {
      'phone': phone,
      'email': email,
    };
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      print('Send WhatsApp OTP API response: $responseData');
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'OTP sent successfully')),
        );
        return responseData;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to send OTP')),
        );
        return null;
      }
    } catch (error) {
      print('Error sending WhatsApp OTP: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error: Please try again')),
      );
      return null;
    }
  }

  /// Verify WhatsApp OTP and register/login user
  Future<Map<String, dynamic>?> verifyWhatsAppOTP({
    required String phone,
    required String email,
    required String otp,
    required BuildContext context,
    bool saveUserOnSuccess = true,
    bool registerAfterVerify = false,
    String? name,
    String? password,
  }) async {
    final url = Uri.parse('https://bharatbill.live/api/v1/whatsapp/verify-otp');

    final body = {
      'phone': phone,
      'email': email,
      'otp': otp,
    };
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      print('📡 [Verify WhatsApp OTP] URL: $url');
      print('📡 [Verify WhatsApp OTP] Headers: $headers');
      print('📡 [Verify WhatsApp OTP] Body: $body');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      print('Verify WhatsApp OTP API response: $responseData');
      EasyLoading.dismiss();
      
      if (response.statusCode == 200) {
        if (!saveUserOnSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'OTP verified successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // If caller asked to register immediately after OTP verify
          if (registerAfterVerify && name != null && password != null) {
            print('Calling Sign Up API after OTP verify...');
            final signUpSuccess = await signUp(
              name: name,
              email: email,
              password: password,
              context: context,
            );
            print('Sign Up after OTP verify success: $signUpSuccess');
            responseData['signUpSuccess'] = signUpSuccess;
          }
          return responseData;
        }
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Registration successful!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Save currency data if available
        if (responseData['currency'] != null) {
          await CurrencyMethods().saveCurrencyDataInLocalDatabase(
            selectedCurrencySymbol: responseData['currency']['symbol'],
            selectedCurrencyName: responseData['currency']['name'],
          );
        }

        // Save user data (token, role, visibility)
        String? token = responseData['token'];
        if (token != null) {
          // Ensure token doesn't have Bearer prefix (it will be added by getAuthToken)
          String cleanToken = token;
          if (cleanToken.toLowerCase().startsWith('bearer ')) {
            cleanToken = cleanToken.substring(7);
          }
          
          print('Saving token: $cleanToken');
          
          // Handle visibility - it can be a List or Map, but saveUserData expects Map or null
          Map<String, dynamic>? visibilityMap;
          if (responseData['visibility'] != null) {
            if (responseData['visibility'] is List) {
              // If visibility is a List, convert to Map or set to null
              // For now, we'll set it to null since it's an empty array
              visibilityMap = null;
            } else if (responseData['visibility'] is Map) {
              visibilityMap = Map<String, dynamic>.from(responseData['visibility']);
            }
          }
          
          await saveUserData(
            token: cleanToken,
            role: responseData['role'],
            visibility: visibilityMap,
          );
          
          // Wait a bit to ensure token is fully saved to SharedPreferences
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Verify token was saved
          final prefs = await SharedPreferences.getInstance();
          final savedToken = prefs.getString('token');
          print('Token saved verification: ${savedToken != null ? "Success" : "Failed"}');
        }

        return responseData;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? responseData['error'] ?? 'OTP verification failed')),
        );
        return null;
      }
    } catch (error) {
      print('Error verifying WhatsApp OTP: $error');
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      return null;
    }
  }

  /// Complete sign-up flow: send WhatsApp OTP, verify it, then register user
  Future<bool> signUpWithWhatsAppOTPFlow({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String otp,
    String? businessName,
    String? category,
    required BuildContext context,
  }) async {
    // Step 1: send OTP
    final sendResponse = await sendWhatsAppOTP(phone: phone, email: email, context: context);
    if (sendResponse == null) return false;

    // Step 2: verify OTP (skip saving user; registration happens next)
    final verifyResponse = await verifyWhatsAppOTP(
      phone: phone,
      email: email,
      otp: otp,
      context: context,
      saveUserOnSuccess: false,
      registerAfterVerify: false, // ensure sign-up is called only once after verify
    );
    if (verifyResponse == null) return false;

    // Step 3: call sign-up API (only once)
    final isSignedUp = await signUp(
      name: name,
      email: email,
      password: password,
      businessName: businessName,
      category: category,
      context: context,
    );

    print('signUpWithWhatsAppOTPFlow -> signUp success: $isSignedUp');

    return isSignedUp;
  }
}
