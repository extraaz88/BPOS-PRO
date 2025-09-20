import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final moduleCheckProvider = FutureProvider<bool>((ref) async {
  final url = Uri.parse('https://pospro.acnoo.com/api/v1/module-check?module_name=SocialLoginAddon');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['status'] == true;
  } else {
    return false;
  }
});
