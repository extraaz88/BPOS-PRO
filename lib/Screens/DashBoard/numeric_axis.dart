import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Repository/constant_functions.dart';
import 'package:mobile_pos/model/dashboard_overview_model.dart';

import 'chart_data.dart';

class DashboardChart extends StatefulWidget {
  const DashboardChart({Key? key, required this.model}) : super(key: key);

  final DashboardOverviewModel model;

  @override
  State<DashboardChart> createState() => _DashboardChartState();
}
//
// class _DashboardChartState extends State<DashboardChart> {
//   List<ChartData> chartData = [];
//
//   @override
//   void initState() {
//     super.initState();
//     getData(widget.model);
//   }
//
//   void getData(DashboardOverviewModel model) {
//     chartData = [];
//     for (int i = 0; i < model.data!.sales!.length; i++) {
//       chartData.add(ChartData(
//         model.data!.sales![i].date!,
//         model.data!.sales![i].amount!.toDouble(),
//         model.data!.purchases![i].amount!.toDouble(),
//       ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Container(
//           color: Colors.white,
//           // padding: const EdgeInsets.all(16.0),
//           child: Stack(
//             alignment: Alignment.topRight,
//             children: [
//               BarChart(
//                 BarChartData(
//                   alignment: BarChartAlignment.spaceAround,
//                   maxY: _getMaxY(),
//                   barTouchData: BarTouchData(enabled: false),
//                   titlesData: FlTitlesData(
//                     show: true,
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: _getBottomTitles,
//                         reservedSize: 42,
//                       ),
//                     ),
//                     rightTitles: const AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: false,
//                       ),
//                     ),
//                     topTitles: const AxisTitles(
//                       sideTitles: SideTitles(showTitles: false,reservedSize: 20)
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: _getLeftTitles,
//                         reservedSize: 50,
//                       ),
//                     ),
//                   ),
//                   borderData: FlBorderData(
//                     show: false,  // Ensure borders are shown
//                   ),
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: false,
//                     drawHorizontalLine: true,
//                     getDrawingHorizontalLine: (value) {
//                       return const FlLine(
//                         color: Color(0xffD1D5DB),
//                         dashArray: [4, 4],
//                         strokeWidth: 1,
//                       );
//                     },
//                   ),
//                   barGroups: _buildBarGroups(),
//                 ),
//
//               ),
//         Column(
//           children: [
//             CustomPaint(
//               size:  Size(
//                   MediaQuery.of(context).size.width-100, 0.1), // Adjust size as needed
//               painter: DashedBarPainter(
//                 barHeight: 1,
//                 barColor: const Color(0xffD1D5DB),
//                 dashWidth: 4,
//                 dashSpace: 4,
//               )),
//             // const SizedBox(),
//             const Spacer(),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 42),
//               child: CustomPaint(
//                   size:  Size(
//                       MediaQuery.of(context).size.width-100, 0.1), // Adjust size as needed
//                   painter: DashedBarPainter(
//                     barHeight: 1,
//                     barColor: const Color(0xffD1D5DB),
//                     dashWidth: 4,
//                     dashSpace: 4,
//                   )),
//             ),
//           ],
//         ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   double _getMaxY() {
//     double maxY = 0;
//     for (var data in chartData) {
//       maxY = maxY > data.y ? maxY : data.y;
//       maxY = maxY > data.y1 ? maxY : data.y1;
//     }
//     return maxY + 10;
//   }
//
//   List<BarChartGroupData> _buildBarGroups() {
//     return chartData.asMap().entries.map((entry) {
//       int index = entry.key;
//       ChartData data = entry.value;
//
//       return BarChartGroupData(
//         x: index,
//         barRods: [
//           BarChartRodData(
//             toY: data.y,
//             color: Colors.green,
//             width: 6,
//             borderRadius: const BorderRadius.all(Radius.circular(10)),
//           ),
//           BarChartRodData(
//             toY: data.y1,
//             color: kMainColor,
//             width: 6,
//             borderRadius: const BorderRadius.all(Radius.circular(10)),
//           ),
//         ],
//         barsSpace: 8,
//       );
//     }).toList();
//   }
//
//   Widget _getBottomTitles(double value, TitleMeta meta) {
//     const style = TextStyle(
//       color: Color(0xff4D4D4D),
//       fontSize: 12,
//     );
//
//     String text = chartData[value.toInt()].x;
//
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 8,
//       child: Text(text, style: style),
//     );
//   }
//
//   Widget _getLeftTitles(double value, TitleMeta meta) {
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       child: Text(
//         value.toInt().toString(),
//         style: const TextStyle(
//           color: Colors.black,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }

class _DashboardChartState extends State<DashboardChart> {
  List<ChartData> chartData = [];

  @override
  void initState() {
    super.initState();
    getData(widget.model);
  }

  @override
  void didUpdateWidget(DashboardChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      getData(widget.model);
    }
  }

  Future<void> getData(DashboardOverviewModel model) async {
    setState(() {
      chartData = [];

      print('=== DASHBOARD CHART DEBUG ===');
      print('Model data: ${model.data}');
      print('Sales data: ${model.data?.sales}');
      print('Purchases data: ${model.data?.purchases}');
      print('Sales count: ${model.data?.sales?.length ?? 0}');
      print('Purchases count: ${model.data?.purchases?.length ?? 0}');

      // Process actual sales and purchase data
      if (model.data?.sales != null || model.data?.purchases != null) {
      // Create a map to combine sales and purchases by date
      Map<String, Map<String, double>> combinedData = {};
      
      // Process sales data - only include days with actual amounts
      if (model.data?.sales != null && model.data!.sales!.isNotEmpty) {
        print('Processing ${model.data!.sales!.length} sales records...');
        for (var sale in model.data!.sales!) {
          print('Sale record: date=${sale.date}, amount=${sale.amount}');
          if (sale.date != null && sale.amount != null) {
            String dateStr = sale.date!.toString().trim();
            double amount = sale.amount!.toDouble();
            
            print('Processing sale: date=$dateStr, amount=$amount');
            
            // Only include days with actual sales amount > 0
            if (amount > 0 && amount.isFinite) {
              combinedData[dateStr] = {
                'sales': amount,
                'purchase': 0.0,
              };
              print('Added sale to chart: $dateStr = ₹$amount');
            } else {
              print('Skipped sale (amount <= 0 or invalid): $dateStr = ₹$amount');
            }
          } else {
            print('Skipped sale (null date or amount): date=${sale.date}, amount=${sale.amount}');
          }
        }
      } else {
        print('No sales data available or empty');
      }
      
      // Process purchase data - only include days with actual amounts
      if (model.data?.purchases != null && model.data!.purchases!.isNotEmpty) {
        for (var purchase in model.data!.purchases!) {
          if (purchase.date != null && purchase.amount != null) {
            String dateStr = purchase.date!.toString().trim();
            double amount = purchase.amount!.toDouble();
            
            // Only include days with actual purchase amount > 0
            if (amount > 0 && amount.isFinite) {
              if (combinedData.containsKey(dateStr)) {
                combinedData[dateStr]!['purchase'] = amount;
              } else {
                combinedData[dateStr] = {
                  'sales': 0.0,
                  'purchase': amount,
                };
              }
            }
          }
        }
      }
      
      // Convert combined data to chart data
      List<String> sortedDates = combinedData.keys.toList()..sort();
      
      print('=== CHART DATA SUMMARY ===');
      print('Total combined data entries: ${combinedData.length}');
      print('Sorted dates: $sortedDates');
      print('Dashboard Chart: Processing ${sortedDates.length} dates with actual data');
      
      for (String date in sortedDates) {
        var data = combinedData[date]!;
        chartData.add(ChartData(
          date,
          data['sales']!,
          data['purchase']!,
        ));
        print('Dashboard Chart: Date: $date, Sales: ₹${data['sales']}, Purchase: ₹${data['purchase']}');
      }
      
      print('Final chart data count: ${chartData.length}');
      print('=== END CHART DEBUG ===');
      
      // If no actual data, mark for API fetch
      if (chartData.isEmpty) {
        print('No chart data found, will fetch from sales API...');
        chartData = [
          ChartData('Loading...', 0, 0),
        ];
      }
      }
    });
    
    // Always fetch from sales API as fallback to get real data
    print('Fetching real sales data as fallback...');
    await fetchRealSalesData();
  }

  // Fallback method to fetch sales data directly
  Future<void> fetchSalesDataDirectly() async {
    try {
      // This would be implemented to fetch sales data directly
      // from the sales API as a fallback
      print('Fallback: Fetching sales data directly...');
    } catch (e) {
      print('Fallback failed: $e');
    }
  }

  // Method to fetch real sales and purchase data from APIs
  Future<void> fetchRealSalesData() async {
    try {
      print('Fetching real sales and purchase data from APIs...');
      
      // Fetch both sales and purchase data
      final salesUri = Uri.parse('${APIConfig.url}/sales');
      final purchaseUri = Uri.parse('${APIConfig.url}/purchase');
      
      final salesResponse = await http.get(salesUri, headers: {
        'Accept': 'application/json',
        'Authorization': await getAuthToken(),
      });
      
      final purchaseResponse = await http.get(purchaseUri, headers: {
        'Accept': 'application/json',
        'Authorization': await getAuthToken(),
      });

      Map<String, double> dailySales = {};
      Map<String, double> dailyPurchases = {};

      // Process sales data
      if (salesResponse.statusCode == 200) {
        final salesData = jsonDecode(salesResponse.body) as Map<String, dynamic>;
        final salesList = salesData['data'] as List<dynamic>;
        
        print('=== DASHBOARD CHART - SALES API DATA ===');
        print('Fetched ${salesList.length} sales records from API');
        
        for (var sale in salesList) {
          try {
            String saleDate = sale['saleDate'] ?? sale['sale_date'] ?? sale['created_at'];
            double amount = double.tryParse(sale['totalAmount']?.toString() ?? sale['total_amount']?.toString() ?? '0') ?? 0.0;
            
            if (amount > 0) {
              String dateKey = saleDate.split(' ')[0];
              dailySales[dateKey] = (dailySales[dateKey] ?? 0) + amount;
            }
          } catch (e) {
            print('Error processing sale: $e');
          }
        }
      }

      // Process purchase data
      if (purchaseResponse.statusCode == 200) {
        final purchaseData = jsonDecode(purchaseResponse.body) as Map<String, dynamic>;
        final purchaseList = purchaseData['data'] as List<dynamic>;
        
        print('=== DASHBOARD CHART - PURCHASE API DATA ===');
        print('Fetched ${purchaseList.length} purchase records from API');
        
        for (var purchase in purchaseList) {
          try {
            String purchaseDate = purchase['purchaseDate'] ?? purchase['purchase_date'] ?? purchase['created_at'];
            double amount = double.tryParse(purchase['totalAmount']?.toString() ?? purchase['total_amount']?.toString() ?? '0') ?? 0.0;
            
            if (amount > 0) {
              String dateKey = purchaseDate.split(' ')[0];
              dailyPurchases[dateKey] = (dailyPurchases[dateKey] ?? 0) + amount;
            }
          } catch (e) {
            print('Error processing purchase: $e');
          }
        }
      }
      
      print('=== DAILY SALES SUMMARY ===');
      dailySales.forEach((date, amount) {
        print('Sales $date: ₹$amount');
      });
      
      print('=== DAILY PURCHASE SUMMARY ===');
      dailyPurchases.forEach((date, amount) {
        print('Purchase $date: ₹$amount');
      });
      
      // Combine sales and purchase data
      Set<String> allDates = {...dailySales.keys, ...dailyPurchases.keys};
      List<String> sortedDates = allDates.toList()..sort();
      
      print('=== CHART DATA CREATION ===');
      print('All dates: $sortedDates');
      
      // Convert to chart data
      setState(() {
        chartData = [];
        
        for (String date in sortedDates) {
          chartData.add(ChartData(
            date,
            dailySales[date] ?? 0.0,
            dailyPurchases[date] ?? 0.0,
          ));
          print('Added to chart: $date - Sales: ₹${dailySales[date] ?? 0}, Purchase: ₹${dailyPurchases[date] ?? 0}');
        }
        
        print('Final chart data count: ${chartData.length}');
      });
      
    } catch (e) {
      print('Error fetching real sales and purchase data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label = '';
                double value = 0;

                if (rodIndex == 0) {
                  label = 'Sales';
                  value = rod.toY;
                } else {
                  label = 'Purchase';
                  value = rod.toY;
                }

                return BarTooltipItem(
                  '$label\n₹${value.toStringAsFixed(2)}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _getBottomTitles,
                reservedSize: 30,
                interval: 1,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _getLeftTitles,
                reservedSize: 50,
                interval: _getMaxY() / 4, // Show 4 horizontal lines for better readability
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: _getMaxY() / 4, // Match with left titles interval
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFFE5E7EB),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  double _getMaxY() {
    double maxY = 0;
    for (var data in chartData) {
      maxY = maxY > data.y ? maxY : data.y;
      maxY = maxY > data.y1 ? maxY : data.y1;
    }
    
    // If no data, return a small value
    if (maxY == 0) {
      return 100;
    }
    
    // Add 20% padding to the maximum value for better visualization
    return maxY * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return chartData.asMap().entries.map((entry) {
      int index = entry.key;
      ChartData data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.y,
            color: const Color(0xFF10B981), // Green color for sales
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: data.y1,
            color: const Color(0xFFEF4444), // Red color for purchases
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xFF6B7280),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    // Add null safety check
    if (chartData.isEmpty || value.toInt() >= chartData.length) {
      return const SizedBox.shrink();
    }

    String text = chartData[value.toInt()].x;
    
    // Format date for better display
    String formattedText = text;
    if (text != 'No Data' && text.length > 10) {
      // If it's a long date string, show only the day part
      try {
        DateTime date = DateTime.parse(text);
        formattedText = '${date.day}/${date.month}';
      } catch (e) {
        // If parsing fails, use original text
        formattedText = text;
      }
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(formattedText, style: style),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xFF6B7280),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    // Format the value with currency symbol
    String formattedValue;
    if (value >= 100000) {
      formattedValue = '₹${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      formattedValue = '₹${(value / 1000).toStringAsFixed(1)}K';
    } else {
      formattedValue = '₹${value.toInt()}';
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        formattedValue,
        style: style,
      ),
    );
  }

// Widget _getLeftTitles(double value, TitleMeta meta) {
//   return SideTitleWidget(
//     axisSide: meta.axisSide,
//     child: Text(
//       value.toInt().toString(),
//       style: const TextStyle(
//         color: Colors.black,
//         fontSize: 12,
//       ),
//     ),
//   );
// }
}

///-----------------------------synfusion data chart--------------------------------

// class NumericAxisChart extends StatefulWidget {
//   const NumericAxisChart({Key? key, required this.model}) : super(key: key);
//
//   final DashboardOverviewModel model;
//
//   @override
//   State<NumericAxisChart> createState() => _NumericAxisChartState();
// }
//
// class _NumericAxisChartState extends State<NumericAxisChart> {
//   final List<ChartData> chartData = [];
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     getData(widget.model);
//     super.initState();
//   }
//
//   getData(DashboardOverviewModel model) {
//     for (int i = 0; i < model.data!.sales!.length; i++) {
//       chartData.add(ChartData(
//           model.data!.sales![i].date!,
//           model.data!.sales![i].amount!.toDouble(),
//           model.data!.purchases![i].amount!.toDouble()));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Container(
//           color: kWhite,
//           child: SfCartesianChart(
//             primaryXAxis: const CategoryAxis(
//               axisLine: AxisLine(width: 0), // Remove bottom axis line
//               majorGridLines: MajorGridLines(width: 0), //// Remove vertical grid lines// Make labels transparent
//               majorTickLines: MajorTickLines(size: 0),
//             ),
//             primaryYAxis: const NumericAxis(
//               axisLine: AxisLine(width: 0), // Remove left axis line
//               majorGridLines: MajorGridLines(
//                 color: Color(0xffD1D5DB),
//                 dashArray: [5, 5], // Creates a dotted line pattern for horizontal grid lines
//               ),
//             ),
//             plotAreaBorderWidth: 0,
//             series: <CartesianSeries<ChartData, String>>[
//               ColumnSeries<ChartData, String>(
//                 dataSource: chartData,
//                 spacing: 0.3,
//                 width: 0.5,
//                 xValueMapper: (ChartData data, _) => data.x,
//                 yValueMapper: (ChartData data, _) => data.y,
//                 name: 'Sales',
//                 dataLabelSettings: const DataLabelSettings(isVisible: false),
//                 color: Colors.green,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(10),
//                   topRight: Radius.circular(10),
//                   bottomRight: Radius.circular(10),
//                   bottomLeft: Radius.circular(10)
//                 ),
//               ),
//               ColumnSeries<ChartData, String>(
//                 dataSource: chartData,
//                 width: 0.5,
//                 spacing: 0.3,
//                 xValueMapper: (ChartData data, _) => data.x,
//                 yValueMapper: (ChartData data, _) => data.y1,
//                 name: 'Purchase',
//                 color: kMainColor,
//                 dataLabelSettings: const DataLabelSettings(isVisible: false),
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(10),
//                   topRight: Radius.circular(10),
//                   bottomLeft: Radius.circular(10),
//                   bottomRight: Radius.circular(10)
//                 ),
//               ),
//             ],
//           )
//           ,
//         ),
//       ),
//     );
//   }
// }
//
// class ChartData {
//   ChartData(this.x, this.y, this.y1);
//
//   final String x;
//   final double y;
//   final double y1;
// }