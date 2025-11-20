import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Screens/DashBoard/global_container.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Const/api_config.dart';
import '../../Provider/profile_provider.dart';
import '../../Repository/constant_functions.dart';
import '../../Screens/payment_type/provider/payment_type_provider.dart';
import '../../Screens/payment_type/model/payment_type_model.dart';
import 'numeric_axis.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> timeList = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'Current Month',
    'Last Month',
    'Current Year',
    'Custom Date'
  ];
  String selectedTime = 'Today';
  bool _isToggleEnabled = false;
  Map<int, double> _paymentTotals = {}; // paymentTypeId -> total amount
  bool _hasCalculatedPayments = false;

  @override
  void initState() {
    super.initState();
    _loadToggleSetting();
    _loadPaymentTotalsFromStorage();
  }

  Future<void> _loadToggleSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isToggleEnabled =
          prefs.getBool('dashboard_payment_toggle_enabled') ?? false;
    });
  }

  Future<void> _loadPaymentTotalsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final totalsJson = prefs.getString('payment_totals');
    if (totalsJson != null) {
      try {
        // Parse JSON and convert string keys to int keys
        final Map<String, dynamic> parsed = jsonDecode(totalsJson);
        _paymentTotals = parsed
            .map((key, value) => MapEntry(int.parse(key), value.toDouble()));
      } catch (e) {
        print('Error loading payment totals: $e');
        _paymentTotals = {};
      }
    }
  }

  // Fetch payment method totals from API
  Future<void> calculateAndSavePaymentTotals(WidgetRef ref) async {
    try {
      // Only fetch from API if toggles are enabled
      if (!_isToggleEnabled) {
        return;
      }

      // API endpoint for payment mode totals
      final uri = Uri.parse('${APIConfig.url}/dashboard/payment-mode-totals');
      final token = await getAuthToken();

      print('\n=== PAYMENT MODE TOTALS API CALL ===');
      print('API URL: ${uri.toString()}');
      print('HTTP Method: GET');
      print('Timestamp: ${DateTime.now()}');
      print('Authorization: $token');
      print('=====================================\n');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': token,
        },
      );

      print('=== PAYMENT MODE TOTALS API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================================\n');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Print full response to console
        print('=== PAYMENT MODE TOTALS - PARSED RESPONSE ===');
        print(jsonEncode(responseData));
        print('=============================================\n');

        // Parse the response data - API structure: { "data": { "mine": { "totals_by_payment_mode": { "Cash": { "paid_amount": 0, "total_amount": 0 }, ... } } } }
        Map<int, double> totals = {};

        try {
          // Get payment types from provider to match names with IDs
          final paymentTypes = await ref.read(paymentTypeProvider.future);

          // Extract data from response structure - access data.mine.totals_by_payment_mode
          print('=== CHECKING RESPONSE STRUCTURE ===');
          print('Has data key: ${responseData.containsKey('data')}');
          if (responseData['data'] != null) {
            print(
                'Has mine key: ${(responseData['data'] as Map).containsKey('mine')}');
            if (responseData['data']['mine'] != null) {
              print(
                  'Has totals_by_payment_mode key: ${(responseData['data']['mine'] as Map).containsKey('totals_by_payment_mode')}');
            }
          }
          print('===================================\n');

          if (responseData['data'] != null &&
              responseData['data']['mine'] != null &&
              responseData['data']['mine']['totals_by_payment_mode'] != null) {
            final totalsByPaymentMode = responseData['data']['mine']
                ['totals_by_payment_mode'] as Map<String, dynamic>;

            print('=== MATCHING PAYMENT TYPES ===');
            print(
                'Found ${totalsByPaymentMode.length} payment modes in API response');
            print('Payment modes: ${totalsByPaymentMode.keys.toList()}');
            print('Total payment types available: ${paymentTypes.length}');

            // Iterate through each payment mode from API
            totalsByPaymentMode.forEach((paymentModeName, paymentData) {
              if (paymentData is Map && paymentData['paid_amount'] != null) {
                final paidAmount =
                    (paymentData['paid_amount'] as num).toDouble();

                // Find matching payment type by name (case-insensitive)
                PaymentTypeModel? matchingPaymentType;
                final paymentModeNameLower =
                    paymentModeName.toLowerCase().trim();

                // Try exact match first
                try {
                  matchingPaymentType = paymentTypes.firstWhere(
                    (type) =>
                        type.name?.toLowerCase().trim() == paymentModeNameLower,
                  );
                } catch (e) {
                  // Try partial match
                  try {
                    matchingPaymentType = paymentTypes.firstWhere(
                      (type) {
                        final typeName = type.name?.toLowerCase() ?? '';
                        return typeName.contains(paymentModeNameLower) ||
                            paymentModeNameLower.contains(typeName);
                      },
                    );
                  } catch (e2) {
                    print(
                        'Warning: Could not find matching payment type for "$paymentModeName"');
                  }
                }

                if (matchingPaymentType?.id != null) {
                  totals[matchingPaymentType!.id!] = paidAmount;
                  print(
                      'Matched: "$paymentModeName" -> ID ${matchingPaymentType.id} (${matchingPaymentType.name}) = ₹$paidAmount');
                } else {
                  print(
                      'Warning: Could not find matching payment type for "$paymentModeName"');
                }
              }
            });

            print('================================\n');
          } else {
            print(
                'Warning: Response structure not as expected. Expected: data.mine.totals_by_payment_mode');
            print('Response keys: ${responseData.keys.toList()}');
            if (responseData['data'] != null) {
              print(
                  'Data keys: ${(responseData['data'] as Map).keys.toList()}');
            }
          }
        } catch (e) {
          print('Error parsing payment mode totals: $e');
        }

        // Save to local storage as JSON
        // Convert int keys to string keys for JSON encoding
        final Map<String, dynamic> totalsForJson = {};
        totals.forEach((key, value) {
          totalsForJson[key.toString()] = value;
        });

        final prefs = await SharedPreferences.getInstance();
        final totalsJson = jsonEncode(totalsForJson);
        await prefs.setString('payment_totals', totalsJson);

        print('=== PAYMENT TOTALS PARSED ===');
        print('Total payment types matched: ${totals.length}');
        print('Payment Totals Map: $totals');
        totals.forEach((id, amount) {
          print('  - Payment Type ID $id: ₹$amount');
        });
        print('============================\n');

        // Update state with new values
        if (mounted) {
          setState(() {
            _paymentTotals = totals;
            print('=== STATE UPDATED ===');
            print('_paymentTotals state: $_paymentTotals');
            print('_isToggleEnabled: $_isToggleEnabled');
            print('====================\n');
          });
        } else {
          print('Warning: Widget not mounted, state not updated');
        }
      } else {
        print('=== PAYMENT MODE TOTALS API ERROR ===');
        print(
            'Failed to fetch payment mode totals. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        print('====================================\n');
      }
    } catch (e, stackTrace) {
      print('=== ERROR FETCHING PAYMENT MODE TOTALS ===');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      print('==========================================\n');
    }
  }

  // Format large numbers to K, Lac, Cr
  String formatCurrency(num value) {
    if (value < 0) {
      return '-${formatCurrency(value.abs())}';
    }

    if (value < 1000) {
      // Show exact value for small numbers
      return value.toStringAsFixed(2);
    } else if (value < 100000) {
      // Show in K (thousands) - 1000 = 1K, 70000 = 70K
      double thousands = value / 1000;
      if (thousands == thousands.roundToDouble()) {
        return '${thousands.toStringAsFixed(0)}K';
      }
      return '${thousands.toStringAsFixed(2)}K';
    } else if (value < 10000000) {
      // Show in Lac - 100000 = 1 Lac, 700000 = 7 Lac
      double lacs = value / 100000;
      if (lacs == lacs.roundToDouble()) {
        return '${lacs.toStringAsFixed(0)} Lac';
      }
      return '${lacs.toStringAsFixed(2)} Lac';
    } else {
      // Show in Cr (crores) - 10000000 = 1 Cr
      double crores = value / 10000000;
      if (crores == crores.roundToDouble()) {
        return '${crores.toStringAsFixed(0)} Cr';
      }
      return '${crores.toStringAsFixed(2)} Cr';
    }
  }

  // Custom date variables
  DateTime? fromDate;
  DateTime? toDate;
  bool showCustomDatePicker = false;

  Map<String, String> getTranslatedTimes(BuildContext context) {
    return {
      'Today': 'Today',
      'Yesterday': 'Yesterday',
      'Last 7 Days': 'Last 7 Days',
      'Last 30 Days': 'Last 30 Days',
      'Current Month': 'Current Month',
      'Last Month': 'Last Month',
      'Current Year': 'Current Year',
      'Custom Date': 'Custom Date',
    };
  }

  bool _isRefreshing = false; // Prevents multiple refresh calls

  // Helper method to create DashboardParams
  DashboardParams _getDashboardParams() {
    if (selectedTime.toLowerCase() == 'custom date' &&
        fromDate != null &&
        toDate != null) {
      return DashboardParams(
        type: 'custom date',
        fromDate: fromDate,
        toDate: toDate,
      );
    }
    return DashboardParams(type: selectedTime.toLowerCase());
  }

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    // Invalidate and refresh the provider
    ref.invalidate(dashboardInfoProvider(_getDashboardParams()));

    // Recalculate and save payment totals
    await calculateAndSavePaymentTotals(ref);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  // Helper method to get icon based on payment type name
  IconData _getPaymentIcon(String? paymentName) {
    if (paymentName == null) return Icons.payment;

    final name = paymentName.toLowerCase();
    if (name.contains('cash')) return Icons.money;
    if (name.contains('card') ||
        name.contains('debit') ||
        name.contains('credit')) return Icons.credit_card;
    if (name.contains('online') ||
        name.contains('upi') ||
        name.contains('paytm') ||
        name.contains('phonepe')) return Icons.payment;
    if (name.contains('bank') || name.contains('transfer'))
      return Icons.account_balance;
    if (name.contains('cheque') || name.contains('check')) return Icons.receipt;
    return Icons.payment;
  }

  // Helper method to get color based on payment type name
  Color _getPaymentColor(String? paymentName) {
    if (paymentName == null) return kMainColor;

    final name = paymentName.toLowerCase();
    if (name.contains('cash')) return Colors.green;
    if (name.contains('card')) return Colors.blue;
    if (name.contains('online') || name.contains('upi')) return Colors.purple;
    if (name.contains('bank') || name.contains('transfer'))
      return Colors.orange;
    if (name.contains('cheque') || name.contains('check')) return Colors.teal;
    // Default color for other payment types
    return kMainColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translatedTimes = getTranslatedTimes(context);
    return Consumer(builder: (_, ref, watch) {
      final dashboardInfo =
          ref.watch(dashboardInfoProvider(_getDashboardParams()));
      return dashboardInfo.when(data: (dashboard) {
        // Debug print to verify dashboard data
        print('Dashboard Data: ${dashboard.toJson()}');
        // Add print to check if dashboard.data is null
        print('Dashboard .data: ${dashboard.data}');
        // Add print for each field
        print('totalExpense: ${dashboard.data?.totalExpense}');
        print('totalIncome: ${dashboard.data?.totalIncome}');
        print('totalItems: ${dashboard.data?.totalItems}');
        print('totalCategories: ${dashboard.data?.totalCategories}');
        print('stockValue: ${dashboard.data?.stockValue}');
        print('totalDue: ${dashboard.data?.totalDue}');
        print('totalProfit: ${dashboard.data?.totalProfit}');
        print('totalLoss: ${dashboard.data?.totalLoss}');

        // Calculate payment totals once when dashboard data is loaded
        if (!_hasCalculatedPayments) {
          _hasCalculatedPayments = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            calculateAndSavePaymentTotals(ref);
          });
        }

        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: kWhite,
            surfaceTintColor: kWhite,
            title: Text(
              lang.S.of(context).dashboard,
              //'Dashboard'
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    // width: 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: kBorderColorTextField)),
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: kGreyTextColor,
                        size: 18,
                      ),
                      value: selectedTime,
                      items: timeList.map((time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(
                            translatedTimes[time] ??
                                time, // Translate item dynamically
                            style: const TextStyle(
                              color: kGreyTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTime = value!;
                          if (selectedTime == 'Custom Date') {
                            showCustomDatePicker = true;
                          } else {
                            showCustomDatePicker = false;
                          }
                        });
                        // Refresh the provider with new selected time
                        ref.invalidate(
                            dashboardInfoProvider(_getDashboardParams()));
                      },
                    ))),
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => refreshData(ref),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Low Stock Alert Widget
                    // Consumer(
                    //   builder: (context, ref, child) {
                    //     final lowStockCount = ref.watch(lowStockCountProvider);
                    //     return lowStockCount.when(
                    //       data: (count) {
                    //         if (count > 0) {
                    //           return Container(
                    //             margin: EdgeInsets.only(bottom: 16),
                    //             padding: EdgeInsets.all(16),
                    //             decoration: BoxDecoration(
                    //               gradient: LinearGradient(
                    //                 colors: [
                    //                   Colors.red[400]!,
                    //                   Colors.red[600]!
                    //                 ],
                    //                 begin: Alignment.topLeft,
                    //                 end: Alignment.bottomRight,
                    //               ),
                    //               borderRadius: BorderRadius.circular(12),
                    //               boxShadow: [
                    //                 BoxShadow(
                    //                   color: Colors.red.withOpacity(0.3),
                    //                   spreadRadius: 1,
                    //                   blurRadius: 8,
                    //                   offset: Offset(0, 4),
                    //                 ),
                    //               ],
                    //             ),
                    //             child: Row(
                    //               children: [
                    //                 Container(
                    //                   padding: EdgeInsets.all(12),
                    //                   decoration: BoxDecoration(
                    //                     color: Colors.white.withOpacity(0.2),
                    //                     borderRadius: BorderRadius.circular(10),
                    //                   ),
                    //                   child: Icon(
                    //                     Icons.inventory_2_outlined,
                    //                     color: Colors.white,
                    //                     size: 24,
                    //                   ),
                    //                 ),
                    //                 SizedBox(width: 16),
                    //                 Expanded(
                    //                   child: Column(
                    //                     crossAxisAlignment:
                    //                         CrossAxisAlignment.start,
                    //                     children: [
                    //                       Text(
                    //                         'Low Stock Alert',
                    //                         style: TextStyle(
                    //                           fontSize: 18,
                    //                           fontWeight: FontWeight.bold,
                    //                           color: Colors.white,
                    //                         ),
                    //                       ),
                    //                       SizedBox(height: 4),
                    //                       Text(
                    //                         '$count products need restocking',
                    //                         style: TextStyle(
                    //                           fontSize: 14,
                    //                           color:
                    //                               Colors.white.withOpacity(0.9),
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //                 Container(
                    //                   padding: EdgeInsets.symmetric(
                    //                       horizontal: 16, vertical: 8),
                    //                   decoration: BoxDecoration(
                    //                     color: Colors.white.withOpacity(0.2),
                    //                     borderRadius: BorderRadius.circular(8),
                    //                     border: Border.all(
                    //                         color:
                    //                             Colors.white.withOpacity(0.3)),
                    //                   ),
                    //                   child: Text(
                    //                     '$count',
                    //                     style: TextStyle(
                    //                       color: Colors.white,
                    //                       fontSize: 20,
                    //                       fontWeight: FontWeight.bold,
                    //                     ),
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //           );
                    //         }
                    //         return SizedBox.shrink();
                    //       },
                    //       loading: () => SizedBox.shrink(),
                    //       error: (error, stack) => SizedBox.shrink(),
                    //     );
                    //   },
                    // ),

                    // Custom Date Picker
                    if (showCustomDatePicker) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: kWhite,
                          border: Border.all(color: kBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Custom Date Range',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: kTitleColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From Date',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: kGreyTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              fromDate = date;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                fromDate != null
                                                    ? '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}'
                                                    : 'Select From Date',
                                                style: TextStyle(
                                                  color: fromDate != null
                                                      ? kTitleColor
                                                      : kGreyTextColor,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today,
                                                  size: 16,
                                                  color: kGreyTextColor),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'To Date',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: kGreyTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              toDate = date;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                toDate != null
                                                    ? '${toDate!.day}/${toDate!.month}/${toDate!.year}'
                                                    : 'Select To Date',
                                                style: TextStyle(
                                                  color: toDate != null
                                                      ? kTitleColor
                                                      : kGreyTextColor,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today,
                                                  size: 16,
                                                  color: kGreyTextColor),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: fromDate != null && toDate != null
                                    ? () {
                                        // Apply custom date filter
                                        ref.invalidate(dashboardInfoProvider(
                                            DashboardParams(
                                          type: 'custom date',
                                          fromDate: fromDate,
                                          toDate: toDate,
                                        )));
                                        setState(() {
                                          showCustomDatePicker = false;
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMainColor,
                                  foregroundColor: kWhite,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Apply Custom Date',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: kWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    DashboardChart(
                      model: dashboard,
                    ),

                    ///_________Items_Category________________________
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: GlobalContainer(
                                title: lang.S.of(context).totalItems,
                                image: 'assets/totalItem.svg',
                                subtitle:
                                    (dashboard.data?.totalItems?.round() ?? 0)
                                        .toString())),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                            child: GlobalContainer(
                                title: lang.S.of(context).totalCategories,
                                image: 'assets/purchaseLisst.svg',
                                subtitle:
                                    (dashboard.data?.totalCategories?.round() ??
                                            0)
                                        .toString()))
                      ],
                    ),

                    ///_________Quick Overview________________________
                    const SizedBox(height: 20),
                    Text(
                      lang.S.of(context).quickOverview,
                      //'Quick Overview',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: GlobalContainer(
                                title: lang.S.of(context).totalIncome,
                                image: 'assets/totalIncome.svg',
                                subtitle:
                                    '$currency${formatCurrency(dashboard.data?.totalIncome ?? 0)}')),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                            child: GlobalContainer(
                                title: lang.S.of(context).totalExpense,
                                image: 'assets/expense.svg',
                                subtitle:
                                    '$currency${formatCurrency(dashboard.data?.totalExpense ?? 0)}'))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: GlobalContainer(
                                title: lang.S.of(context).customerDue,
                                image: 'assets/duelist.svg',
                                subtitle:
                                    '$currency${formatCurrency(dashboard.data?.totalDue ?? 0)}')),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                            child: GlobalContainer(
                                title: lang.S.of(context).stockValue,
                                image: 'assets/stock.svg',
                                subtitle:
                                    "$currency${formatCurrency(dashboard.data?.stockValue ?? 0)}"))
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      lang.S.of(context).lossProfit,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                    ),

                    ///__________Total_Lass_and_Total_profit_____________________________________
                    const SizedBox(height: 10),
                    SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                              child: GlobalContainer(
                                  title: lang.S.of(context).totalProfit,
                                  image: 'assets/lossprofit.svg',
                                  subtitle:
                                      '$currency${formatCurrency(dashboard.data?.totalProfit ?? 0)}')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: GlobalContainer(
                                  title: lang.S.of(context).totalLoss,
                                  image: 'assets/expense.svg',
                                  subtitle:
                                      '$currency${formatCurrency((dashboard.data?.totalLoss ?? 0).abs())}'))
                        ],
                      ),
                    ),

                    ///__________Payment_Method_Toggles_____________________________________
                    if (_isToggleEnabled)
                      Consumer(
                        builder: (context, ref, child) {
                          final paymentTypes = ref.watch(paymentTypeProvider);
                          return paymentTypes.when(
                            data: (types) {
                              // Filter only active payment types
                              final activeTypes =
                                  types.where((t) => t.status == 1).toList();

                              // Group payment methods into rows of 2
                              List<List<PaymentTypeModel>> rows = [];
                              for (int i = 0; i < activeTypes.length; i += 2) {
                                rows.add(activeTypes.sublist(
                                    i,
                                    i + 2 > activeTypes.length
                                        ? activeTypes.length
                                        : i + 2));
                              }

                              if (rows.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  Text(
                                    'Payment Methods',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  const SizedBox(height: 10),
                                  ...rows
                                      .map((row) => Column(
                                            children: [
                                              Row(
                                                children: row
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  final index = entry.key;
                                                  final paymentType =
                                                      entry.value;
                                                  return Expanded(
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                        right:
                                                            index == 0 ? 12 : 0,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: _getPaymentColor(
                                                                    paymentType
                                                                        .name)
                                                                .withOpacity(
                                                                    0.1),
                                                            spreadRadius: 1,
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(8),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: _getPaymentColor(
                                                                          paymentType
                                                                              .name)
                                                                      .withOpacity(
                                                                          0.1),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Icon(
                                                                  _getPaymentIcon(
                                                                      paymentType
                                                                          .name),
                                                                  color: _getPaymentColor(
                                                                      paymentType
                                                                          .name),
                                                                  size: 20,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 12),
                                                              Expanded(
                                                                child: Text(
                                                                  paymentType
                                                                          .name ??
                                                                      'Unknown',
                                                                  style: theme
                                                                      .textTheme
                                                                      .titleMedium
                                                                      ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        kTitleColor,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 12),
                                                          Text(
                                                            '$currency${formatCurrency(_paymentTotals[paymentType.id] ?? 0)}',
                                                            style: theme
                                                                .textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  _getPaymentColor(
                                                                      paymentType
                                                                          .name),
                                                              fontSize: 20,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              if (rows.indexOf(row) <
                                                  rows.length - 1)
                                                const SizedBox(height: 10),
                                            ],
                                          ))
                                      .toList(),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (error, stack) => const SizedBox.shrink(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }, error: (e, stack) {
        print(stack);
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  //'{No data found} $e',
                  '${lang.S.of(context).noDataFound} $e',
                  style: const TextStyle(
                      color: kGreyTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }, loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      });
    });
  }
}
