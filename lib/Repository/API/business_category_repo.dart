import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../Const/api_config.dart';
import '../../model/business_category_model.dart';
import '../constant_functions.dart';

class BusinessCategoryRepository {
  Future<List<BusinessCategory>> getBusinessCategories() async {
    try {
      final url = '${APIConfig.url}${APIConfig.businessCategoriesUrl}';
      final token = await getAuthToken();

      print('Business categories API → GET $url');
      final headers = {
        'Accept': 'application/json',
      };

      if (token.isNotEmpty) {
        headers['Authorization'] = token;
      } else {
        print('Business categories API warning: token missing, calling without Authorization header');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print(
        'Business categories API ← ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        return data.map((category) => BusinessCategory.fromJson(category)).toList();
      } else {
        throw Exception(
          'Failed to fetch business categories (status ${response.statusCode})',
        );
      }
    } catch (error) {
      throw Exception('Error fetching business categories: $error');
    }
  }
}
