import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;

import '../../../../Const/api_config.dart';
import '../../../../Repository/constant_functions.dart';
import '../../../../currency.dart';
import '../../../Home/home.dart';
import '../../Sign Up/verify_email.dart';
import '../../profile_setup_screen.dart';
import '../../../shop_category_selection_screen.dart';

class LogInRepo {
  Future<bool> logIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final url = Uri.parse('${APIConfig.url}/sign-in');

    final body = {
      'email': email,
      'password': password,
    };
    final headers = {
      'Accept': 'application/json',
    };

    try {
      final response = await http.post(url, headers: headers, body: body);

      final responseData = jsonDecode(response.body);
      EasyLoading.dismiss();
      print('Signin ${response.statusCode}');
      print('Signin ${response.body}');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));

        bool isSetupDone = responseData['data']['is_setup'];
        try {
          await CurrencyMethods().saveCurrencyDataInLocalDatabase(selectedCurrencySymbol: responseData['data']['currency']['symbol'], selectedCurrencyName: responseData['data']['currency']['name']);
        } catch (error) {
          print(error);
        }
        if (!isSetupDone) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileSetup()));
        } else {
          // Save token, role, and visibility permissions
          // If role is not present or not 'staff', treat as admin
          String userRole = responseData['data']['role'] ?? 'admin';
          if (userRole.isEmpty) {
            userRole = 'admin';
          }
          
          // Handle visibility - check if it's a Map or List
          Map<String, dynamic>? visibilityMap;
          final visibilityData = responseData['data']['visibility'];
          
          print('User Role: $userRole');
          print('Visibility Type: ${visibilityData.runtimeType}');
          
          if (visibilityData is Map<String, dynamic>) {
            visibilityMap = visibilityData;
            print('Visibility is Map: $visibilityMap');
          } else if (visibilityData is List) {
            // If it's an empty array, visibility is null (means full access for non-staff)
            visibilityMap = null;
            print('Visibility is List (empty array), full access granted');
          } else {
            visibilityMap = null;
            print('Visibility is null or unknown type, full access granted');
          }
          
          await saveUserData(
            token: responseData['data']['token'],
            role: userRole,
            visibility: visibilityMap,
          );
          
          // Navigate to shop category selection screen if business category exists
          if (responseData['data']['business_category_name'] != null) {
            try {
              final apiCategoryName = responseData['data']['business_category_name'] as String;
              print('API Category Name: $apiCategoryName');
              final categoryData = getCategoryByName(apiCategoryName);
              
              if (categoryData != null) {
                final categoryName = categoryData['name'] as String;
                print('Mapped Category Name: $categoryName from API category: $apiCategoryName');
                
                // Navigate to shop category selection screen with preselected category
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopCategorySelectionScreen(
                      preselectedCategoryName: categoryName,
                    ),
                  ),
                );
              } else {
                print('Warning: Category data is null for API category: $apiCategoryName');
                // Navigate to shop category selection screen without preselection
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopCategorySelectionScreen()),
                );
              }
            } catch (error) {
              print('Error processing business category: $error');
              // Navigate to shop category selection screen on error
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ShopCategorySelectionScreen()),
              );
            }
          } else {
            print('No business_category_name in login response');
            // Navigate to home if no business category
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
          }
        }

        return true;
      } else if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmail(
              email: email,
              isFormForgotPass: false,
            ),
          ),
        );

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Please try again')));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Please try again')));
    }

    return false;
  }
}
