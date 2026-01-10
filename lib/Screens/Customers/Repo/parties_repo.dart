//ignore_for_file: avoid_print,unused_local_variable
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Const/api_config.dart';

import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../Model/parties_model.dart';
import '../Provider/customer_provider.dart';

class PartyRepository {
  // Fetch all parties (Customers + Suppliers)
  Future<List<Party>> fetchAllParties() async {
    final uri = Uri.parse('${APIConfig.url}/parties');

    print('\n👥 ===== FETCH ALL PARTIES API =====');
    print('📤 Request URL: $uri');
    print('📤 Request Method: GET');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      final partyList = parsedData['data'] as List<dynamic>;

      print('✅ Success: Found ${partyList.length} parties');
      print('👥 Parties List:');
      for (int i = 0; i < partyList.length && i < 5; i++) {
        print(
            '   [${i + 1}] ID: ${partyList[i]['id']}, Name: ${partyList[i]['name']}, Type: ${partyList[i]['type']}');
      }
      if (partyList.length > 5) {
        print('   ... and ${partyList.length - 5} more');
      }
      print('👥 ====================================\n');

      return partyList.map((category) => Party.fromJson(category)).toList();
    } else {
      print('❌ Error: Failed to fetch parties');
      print('👥 ====================================\n');
      throw Exception('Failed to fetch parties');
    }
  }

  // Fetch only Customers
  Future<List<Party>> fetchCustomers() async {
    final uri = Uri.parse('${APIConfig.url}/parties?type=Customer');

    print('\n👤 ===== FETCH CUSTOMERS API =====');
    print('📤 Request URL: $uri');
    print('📤 Request Method: GET');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      final partyList = parsedData['data'] as List<dynamic>;

      print('✅ Success: Found ${partyList.length} customers');
      print('👤 Customers List:');
      for (int i = 0; i < partyList.length && i < 5; i++) {
        print(
            '   [${i + 1}] ID: ${partyList[i]['id']}, Name: ${partyList[i]['name']}, Phone: ${partyList[i]['phone']}');
      }
      if (partyList.length > 5) {
        print('   ... and ${partyList.length - 5} more');
      }
      print('👤 ====================================\n');

      return partyList.map((category) => Party.fromJson(category)).toList();
    } else {
      print('❌ Error: Failed to fetch customers');
      print('👤 ====================================\n');
      throw Exception('Failed to fetch customers');
    }
  }

  // Fetch only Suppliers
  Future<List<Party>> fetchSuppliers() async {
    final uri = Uri.parse('${APIConfig.url}/parties?type=Supplier');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => Party.fromJson(category)).toList();
    } else {
      throw Exception('Failed to fetch suppliers');
    }
  }

  Future<void> addParty({
    required WidgetRef ref,
    required BuildContext context,
    required String name,
    required String phone,
    required String type,
    File? image,
    String? email,
    String? address,
    String? due,
  }) async {
    CustomHttpClient customHttpClient =
        CustomHttpClient(client: http.Client(), context: context, ref: ref);
    final uri = Uri.parse('${APIConfig.url}/parties');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();

    request.fields['name'] = name;
    request.fields['phone'] = phone;
    request.fields['type'] = type;
    if (email != null) request.fields['email'] = email;
    if (address != null) request.fields['address'] = address;
    if (due != null) request.fields['due'] = due; // Convert due to string
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
          'image', image.readAsBytesSync(),
          filename: image.path));
    }

    print('\n➕ ===== ADD CUSTOMER API =====');
    print('📤 Request URL: $uri');
    print('📤 Request Method: POST');
    print('📤 Request Fields:');
    request.fields.forEach((key, value) {
      print('   $key: $value');
    });
    if (image != null) {
      print('📎 Image: ${image.path}');
    }

    // final response = await request.send();
    final response = await customHttpClient.uploadFile(
        url: uri, fileFieldName: 'image', file: image, fields: request.fields);
    final responseData = await response.stream.bytesToString();
    final parsedData = jsonDecode(responseData);

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: $responseData');

    if (response.statusCode == 200) {
      print('✅ Success: Customer added');
      print('➕ Customer Details:');
      if (parsedData['data'] != null) {
        final customerData = parsedData['data'];
        print('   ID: ${customerData['id']}');
        print('   Name: ${customerData['name']}');
        print('   Phone: ${customerData['phone']}');
        print('   Type: ${customerData['type']}');
      }
      print('➕ ====================================\n');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added successful!')));

      // Refresh all providers
      // ignore: unused_result
      ref.refresh(partiesProvider);
      // ignore: unused_result
      ref.refresh(customersProvider);
      // ignore: unused_result
      ref.refresh(suppliersProvider);

      Navigator.pop(context);
    } else {
      // Handle specific error cases
      String errorMessage = 'Party creation failed';
      if (parsedData['message'] != null) {
        errorMessage = parsedData['message'];
        // Make the error message more user-friendly
        if (errorMessage.toLowerCase().contains('phone') &&
            errorMessage.toLowerCase().contains('taken')) {
          errorMessage =
              'This phone number is already registered. Please use a different phone number.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  Future<void> updateParty({
    required String id,
    required WidgetRef ref,
    required BuildContext context,
    required String name,
    required String phone,
    required String type,
    File? image,
    String? email,
    String? address,
    String? due,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/parties/$id');
    CustomHttpClient customHttpClient =
        CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();

    request.fields['_method'] = 'put';
    request.fields['name'] = name;
    request.fields['phone'] = phone;
    request.fields['type'] = type;
    if (email != null) request.fields['email'] = email;
    if (address != null) request.fields['address'] = address;
    if (due != null) request.fields['due'] = due; // Convert due to string
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
          'image', image.readAsBytesSync(),
          filename: image.path));
    }

    print('\n✏️ ===== UPDATE CUSTOMER API =====');
    print('📤 Request URL: $uri');
    print('📤 Request Method: PUT');
    print('📤 Customer ID: $id');
    print('📤 Request Fields:');
    request.fields.forEach((key, value) {
      if (key != '_method') {
        print('   $key: $value');
      }
    });
    if (image != null) {
      print('📎 Image: ${image.path}');
    }

    // final response = await request.send();
    final response = await customHttpClient.uploadFile(
        url: uri, fields: request.fields, file: image, fileFieldName: 'image');
    final responseData = await response.stream.bytesToString();

    final parsedData = jsonDecode(responseData);

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: $responseData');

    if (response.statusCode == 200) {
      print('✅ Success: Customer updated');
      print('✏️ Updated Customer Details:');
      if (parsedData['data'] != null) {
        final customerData = parsedData['data'];
        print('   ID: ${customerData['id']}');
        print('   Name: ${customerData['name']}');
        print('   Phone: ${customerData['phone']}');
      }
      print('✏️ ====================================\n');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Updated Successfully!')));

      // Refresh all providers
      // ignore: unused_result
      ref.refresh(partiesProvider);
      // ignore: unused_result
      ref.refresh(customersProvider);
      // ignore: unused_result
      ref.refresh(suppliersProvider);

      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Party Update failed: ${parsedData['message']}')));
    }
  }

  Future<void> deleteParty({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/parties/$id';

    print('\n🗑️ ===== DELETE CUSTOMER API =====');
    print('📤 Request URL: $apiUrl');
    print('📤 Request Method: DELETE');
    print('📤 Customer ID: $id');

    try {
      CustomHttpClient customHttpClient =
          CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Success: Customer deleted');
        print('🗑️ ====================================\n');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party deleted successfully')));

        // Refresh all providers
        // ignore: unused_result
        ref.refresh(partiesProvider);
        // ignore: unused_result
        ref.refresh(customersProvider);
        // ignore: unused_result
        ref.refresh(suppliersProvider);

        Navigator.pop(
            context); // Assuming you want to close the screen after deletion
        // Navigator.pop(context); // Assuming you want to close the screen after deletion
      } else {
        final parsedData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete party: ${parsedData['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> sendCustomerUdeSms(
      {required num id, required BuildContext context}) async {
    final uri = Uri.parse('${APIConfig.url}/parties/$id');

    print('\n📱 ===== SEND CUSTOMER SMS API =====');
    print('📤 Request URL: $uri');
    print('📤 Request Method: GET');
    print('📤 Customer ID: $id');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    EasyLoading.dismiss();
    if (response.statusCode == 200) {
      print('✅ Success: SMS sent to customer');
      print('📱 ====================================\n');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonDecode(response.body)['message'])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${jsonDecode((response.body))['message']}')));
    }
  }
}
