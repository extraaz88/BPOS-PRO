import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/DashBoard/global_container.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../Provider/profile_provider.dart';
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

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    // Invalidate and refresh the provider based on selected time
    if (selectedTime == 'Custom Date' && fromDate != null && toDate != null) {
      ref.invalidate(dashboardCustomDateProvider({
        'type': 'custom_date',
        'fromDate': fromDate,
        'toDate': toDate,
      }));
    } else {
      ref.invalidate(dashboardInfoProvider(selectedTime.toLowerCase()));
    }

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translatedTimes = getTranslatedTimes(context);
    return Consumer(builder: (_, ref, watch) {
      // Use custom date provider if custom date is selected
      final dashboardInfo = selectedTime == 'Custom Date' && fromDate != null && toDate != null
          ? ref.watch(dashboardCustomDateProvider({
              'type': 'custom_date',
              'fromDate': fromDate,
              'toDate': toDate,
            }))
          : ref.watch(dashboardInfoProvider(selectedTime.toLowerCase()));
      
      return dashboardInfo.when(data: (dashboard) {
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
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: kBorderColorTextField)),
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
                            translatedTimes[time] ?? time, // Translate item dynamically
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
                        if (selectedTime == 'Custom Date' && fromDate != null && toDate != null) {
                          ref.invalidate(dashboardCustomDateProvider({
                            'type': 'custom_date',
                            'fromDate': fromDate,
                            'toDate': toDate,
                          }));
                        } else {
                          ref.invalidate(dashboardInfoProvider(selectedTime.toLowerCase()));
                        }
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From Date',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: kGreyTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              fromDate = date;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: kBorderColorTextField),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                fromDate != null 
                                                    ? '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}'
                                                    : 'Select From Date',
                                                style: TextStyle(
                                                  color: fromDate != null ? kTitleColor : kGreyTextColor,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today, size: 16, color: kGreyTextColor),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'To Date',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: kGreyTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: toDate ?? DateTime.now(),
                                            firstDate: fromDate ?? DateTime(2020),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              toDate = date;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: kBorderColorTextField),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                toDate != null 
                                                    ? '${toDate!.day}/${toDate!.month}/${toDate!.year}'
                                                    : 'Select To Date',
                                                style: TextStyle(
                                                  color: toDate != null ? kTitleColor : kGreyTextColor,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today, size: 16, color: kGreyTextColor),
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
                                    ? () async {
                                        // Validate date range
                                        if (fromDate!.isAfter(toDate!)) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('From date must be before To date'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        
                                        // Apply custom date filter
                                        try {
                                          ref.invalidate(dashboardCustomDateProvider({
                                            'type': 'custom_date',
                                            'fromDate': fromDate,
                                            'toDate': toDate,
                                          }));
                                          setState(() {
                                            showCustomDatePicker = false;
                                          });
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Data loaded for ${fromDate!.day}/${fromDate!.month}/${fromDate!.year} to ${toDate!.day}/${toDate!.month}/${toDate!.year}'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error loading data: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMainColor,
                                  foregroundColor: kWhite,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: kWhite),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.S.of(context).salesPurchaseOverview,
                            //'Sales & Purchase Overview',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: kTitleColor),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              RichText(
                                  text: TextSpan(
                                      text: lang.S.of(context).sales,
                                      //'Sales',
                                      style: const TextStyle(color: kTitleColor),
                                      children: const [
                                    // TextSpan(
                                    //     text: '$currency 500',
                                    //     style: gTextStyle.copyWith(fontWeight: FontWeight.bold,color: kTitleColor)
                                    // ),
                                  ])),
                              const SizedBox(
                                width: 20,
                              ),
                              const Icon(
                                Icons.circle,
                                color: kMainColor,
                                size: 18,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              RichText(
                                  text: TextSpan(
                                      text: lang.S.of(context).purchase,

                                      //'Purchase',
                                      style: const TextStyle(color: kTitleColor),
                                      children: const [
                                    // TextSpan(
                                    //     text: '$currency 300',
                                    //     style: gTextStyle.copyWith(fontWeight: FontWeight.bold,color: kTitleColor)
                                    // ),
                                  ])),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                              height: 250,
                              width: double.infinity,
                              child: dashboard.data?.sales != null && dashboard.data?.purchases != null
                                  ? DashboardChart(
                                      model: dashboard,
                                    )
                                  : const Center(
                                      child: Text(
                                        'No chart data available',
                                        style: TextStyle(color: kGreyTextColor),
                                      ),
                                    )),
                        ],
                      ),
                    ),

                    ///_________Items_Category________________________
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: GlobalContainer(title: lang.S.of(context).totalItems, image: 'assets/totalItem.svg', subtitle: (dashboard.data?.totalItems?.round() ?? 0).toString())),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(child: GlobalContainer(title: lang.S.of(context).totalCategories, image: 'assets/purchaseLisst.svg', subtitle: (dashboard.data?.totalCategories?.round() ?? 0).toString()))
                      ],
                    ),

                    ///_________Quick Overview________________________
                    const SizedBox(height: 20),
                    Text(
                      lang.S.of(context).quickOverview,
                      //'Quick Overview',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: GlobalContainer(title: lang.S.of(context).totalIncome, image: 'assets/totalIncome.svg', subtitle: '$currency${(dashboard.data?.totalIncome ?? 0).toStringAsFixed(2)}')),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(child: GlobalContainer(title: lang.S.of(context).totalExpense, image: 'assets/expense.svg', subtitle: '$currency${(dashboard.data?.totalExpense ?? 0).toStringAsFixed(2)}'))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: GlobalContainer(title: lang.S.of(context).customerDue, image: 'assets/duelist.svg', subtitle: '$currency ${(dashboard.data?.totalDue ?? 0).toStringAsFixed(2)}')),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(child: GlobalContainer(title: lang.S.of(context).stockValue, image: 'assets/stock.svg', subtitle: "$currency${(dashboard.data?.stockValue ?? 0).toStringAsFixed(2)}"))
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      lang.S.of(context).lossProfit,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                    ),

                    ///__________Total_Lass_and_Total_profit_____________________________________
                    const SizedBox(height: 10),
                    Row(
                      children: [Expanded(child: GlobalContainer(title: lang.S.of(context).totalProfit, image: 'assets/lossprofit.svg', subtitle: '$currency${(dashboard.data?.totalProfit ?? 0).toStringAsFixed(2)}')), const SizedBox(width: 12), Expanded(child: GlobalContainer(title: lang.S.of(context).totalLoss, image: 'assets/expense.svg', subtitle: '$currency${(dashboard.data?.totalLoss ?? 0).abs().toStringAsFixed(2)}'))],
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
                  style: const TextStyle(color: kGreyTextColor, fontSize: 16, fontWeight: FontWeight.w500),
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
