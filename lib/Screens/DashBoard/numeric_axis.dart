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

class _DashboardChartState extends State<DashboardChart> with TickerProviderStateMixin {
  List<ChartData> chartData = [];
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    getData(widget.model);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      
      // Get only the latest 4 days
      List<String> latest4Days = sortedDates.length > 4 
          ? sortedDates.sublist(sortedDates.length - 4) 
          : sortedDates;
      
      print('=== LATEST 4 DAYS FILTER ===');
      print('Original dates count: ${sortedDates.length}');
      print('Latest 4 days: $latest4Days');
      
      for (String date in latest4Days) {
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
      
      // Get only the latest 4 days from API data
      List<String> latest4Days = sortedDates.length > 4 
          ? sortedDates.sublist(sortedDates.length - 4) 
          : sortedDates;
      
      print('=== API DATA - LATEST 4 DAYS FILTER ===');
      print('Original API dates count: ${sortedDates.length}');
      print('Latest 4 days from API: $latest4Days');
      
      // Convert to chart data
      setState(() {
        chartData = [];
        
        for (String date in latest4Days) {
          chartData.add(ChartData(
            date,
            dailySales[date] ?? 0.0,
            dailyPurchases[date] ?? 0.0,
          ));
          print('Added to chart: $date - Sales: ₹${dailySales[date] ?? 0}, Purchase: ₹${dailyPurchases[date] ?? 0}');
        }
        
        print('Final chart data count: ${chartData.length}');
      });
      
      // Start animation after data is loaded
      _animationController.forward();
      
    } catch (e) {
      print('Error fetching real sales and purchase data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing
    final isTablet = screenWidth > 800;
    final chartHeight = isTablet ? 320.0 : screenHeight * 0.35; // Increased height
    final headerPadding = isTablet ? 0.0 : 16.0;
    final chartPadding = isTablet ? 10.0 : 8.0;
    
    return Container(
      height: chartHeight,
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 5 : 4,
        vertical: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: EdgeInsets.fromLTRB(headerPadding, headerPadding, headerPadding, 8),
            child: Text(
              'Sales & Purchase Analytics (Last 4 Days)',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Legend
          Container(
            padding: EdgeInsets.fromLTRB(headerPadding, 0, headerPadding, headerPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Sales', const Color(0xFF10B981), isTablet),
                SizedBox(width: isTablet ? 20 : 16),
                _buildLegendItem('Purchase', const Color(0xFF3B82F6), isTablet),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: chartPadding, vertical: 4),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(12),
                      tooltipMargin: 8,
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
                          '$label\n₹${value.toStringAsFixed(0)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                        getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, isTablet),
                        reservedSize: isTablet ? 50 : 40,
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
                        getTitlesWidget: (value, meta) => _getLeftTitles(value, meta, isTablet),
                        reservedSize: isTablet ? 80 : 60,
                        interval: _getMaxY() / 5,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      left: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    horizontalInterval: _getMaxY() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      );
                    },
                  ),
                      barGroups: _buildBarGroups(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isTablet ? 14 : 12,
          height: isTablet ? 14 : 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isTablet ? 3 : 2),
          ),
        ),
        SizedBox(width: isTablet ? 8 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return chartData.asMap().entries.map((entry) {
      int index = entry.key;
      ChartData data = entry.value;

      // Apply animation to bar heights
      double animatedSales = data.y * _animation.value;
      double animatedPurchase = data.y1 * _animation.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: animatedSales,
            color: data.y > 0 ? const Color(0xFF10B981) : Colors.grey[300]!,
            width: isTablet ? 24 : 20,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isTablet ? 8 : 6),
              topRight: Radius.circular(isTablet ? 8 : 6),
            ),
            gradient: data.y > 0 ? LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF10B981).withOpacity(0.8),
                const Color(0xFF10B981),
              ],
            ) : null,
          ),
          BarChartRodData(
            toY: animatedPurchase,
            color: data.y1 > 0 ? const Color(0xFF3B82F6) : Colors.grey[300]!,
            width: isTablet ? 24 : 20,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isTablet ? 8 : 6),
              topRight: Radius.circular(isTablet ? 8 : 6),
            ),
            gradient: data.y1 > 0 ? LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.8),
                const Color(0xFF3B82F6),
              ],
            ) : null,
          ),
        ],
        barsSpace: isTablet ? 8 : 6,
      );
    }).toList();
  }

  Widget _getBottomTitles(double value, TitleMeta meta, bool isTablet) {
    final style = TextStyle(
      color: const Color(0xFF374151),
      fontSize: isTablet ? 13 : 11,
      fontWeight: FontWeight.w600,
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
      space: isTablet ? 12 : 8,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 8, 
          vertical: isTablet ? 6 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
        ),
        child: Text(
          formattedText, 
          style: style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta, bool isTablet) {
    final style = TextStyle(
      color: const Color(0xFF374151),
      fontSize: isTablet ? 13 : 11,
      fontWeight: FontWeight.w600,
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
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 8 : 6, 
          vertical: isTablet ? 4 : 2,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
        ),
        child: Text(
          formattedValue,
          style: style,
        ),
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