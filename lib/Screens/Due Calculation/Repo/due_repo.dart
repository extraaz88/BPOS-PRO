// ignore_for_file: unused_local_variable
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../Const/api_config.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Provider/transactions_provider.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../../Customers/Provider/customer_provider.dart';
import '../Model/due_collection_invoice_model.dart';
import '../Model/due_collection_model.dart';
import '../Providers/due_provider.dart';

class DueRepo {
  Future<List<DueCollection>> fetchDueCollectionList() async {
    final uri = Uri.parse('${APIConfig.url}/parties');
//dues
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    print('===============================================');
    print('Due Report API Response:');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('===============================================');

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
      
      print('Parsed Data: $parsedData');
      print('Due List Length: ${(parsedData['data'] as List<dynamic>).length}');

      final partiesList = parsedData['data'] as List<dynamic>;
      
      // Print each party item
      for (int i = 0; i < partiesList.length; i++) {
        print('Party Item $i: ${partiesList[i]}');
      }
      
      // Convert parties data to DueCollection format
      List<DueCollection> dueCollections = [];
      for (var party in partiesList) {
        // Skip walk-in customers (id == -1 or name == 'Walk-in Customer')
        final partyId = party['id'];
        final partyName = party['name']?.toString() ?? '';
        if (partyId == -1 || partyName == 'Walk-in Customer') {
          continue; // Skip walk-in customers
        }
        
        // Only add if party has due amount
        if (party['due'] != null && party['due'] > 0) {
          // Create a DueCollection object from party data
          final dueData = {
            'id': party['id'],
            'party_id': party['id'],
            'totalDue': party['due'],
            'dueAmountAfterPay': party['due'],
            'payDueAmount': 0,
            'paymentDate': DateTime.now().toIso8601String().split('T')[0], // Current date
            'invoiceNumber': 'N/A',
            'party': party,
          };
          print('Converted Due Data: $dueData');
          print('Party Type in Due Data: ${party['type']}');
          dueCollections.add(DueCollection.fromJson(dueData));
        }
      }
      
      print('Total Due Collections: ${dueCollections.length}');
      return dueCollections;
    } else {
      print('Error Response: ${response.body}');
      throw Exception('Failed to fetch Due List');
    }
  }

  Future<DueCollectionInvoice> fetchDueInvoiceList({required int id}) async {
    final uri = Uri.parse('${APIConfig.url}/invoices?party_id=$id');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body);
      return DueCollectionInvoice.fromJson(parsedData['data']);
    } else {
      throw Exception('Failed to fetch Sales List');
    }
  }

  Future<DueCollection?> dueCollect({
    required WidgetRef ref,
    required BuildContext context,
    required num partyId,
    required String? invoiceNumber,
    required String paymentDate,
    required String paymentType,
    required num payDueAmount,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/dues');
    final requestBody = jsonEncode({
      'party_id': partyId,
      'invoiceNumber': invoiceNumber,
      'paymentDate': paymentDate,
      'payment_type_id': paymentType,
      'payDueAmount': payDueAmount,
    });

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);
      var responseData = await customHttpClient.post(url: uri, headers: {"Accept": 'application/json', 'Authorization': await getAuthToken(), 'Content-Type': 'application/json'}, body: requestBody);
      final parsedData = jsonDecode(responseData.body);
      print("Print Due data: ${parsedData['data']}");

      if (responseData.statusCode == 200) {
        EasyLoading.showSuccess('Collected successful!');

        ref.refresh(partiesProvider);

        ref.refresh(purchaseTransactionProvider);
        ref.refresh(salesTransactionProvider);
        ref.refresh(businessInfoProvider);
        ref.refresh(getExpireDateProvider(ref));

        // ref.refresh(dueInvoiceListProvider(partyId.round()));
        ref.refresh(dueCollectionListProvider);
        ref.refresh(summaryInfoProvider);

        return DueCollection.fromJson(parsedData['data']);
        // Navigator.pop(context);
        // return PurchaseTransaction.fromJson(parsedData);
      } else {
        EasyLoading.dismiss().then(
          (value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase creation failed: ${parsedData['message']}'))),
        );
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss().then(
        (value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error'))),
      );
      return null;
    }
  }
}
