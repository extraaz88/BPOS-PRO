import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/dashboard_overview_model.dart';

import 'chart_data.dart';

class DashboardChart extends StatefulWidget {
  const DashboardChart({Key? key, required this.model}) : super(key: key);

  final DashboardOverviewModel model;

  @override
  State<DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<DashboardChart> {
  List<ChartData> chartData = [];

  @override
  void initState() {
    super.initState();
    getData(widget.model);
  }

  void getData(DashboardOverviewModel model) {
    chartData = [];
    
    print('=== CHART DEBUG START ===');
    print('Model: $model');
    print('Model data: ${model.data}');
    print('Sales data: ${model.data?.sales}');
    print('Purchases data: ${model.data?.purchases}');
    
    // Add null safety checks
    if (model.data?.sales != null && model.data?.purchases != null) {
      int salesLength = model.data!.sales!.length;
      int purchasesLength = model.data!.purchases!.length;
      int maxLength = salesLength < purchasesLength ? salesLength : purchasesLength;
      
      print('Sales length: $salesLength, Purchases length: $purchasesLength');
      
      double totalSales = 0;
      double totalPurchases = 0;
      int daysWithSales = 0;
      int daysWithPurchases = 0;
      
      for (int i = 0; i < maxLength; i++) {
        double salesAmount = (model.data!.sales![i].amount ?? 0).toDouble();
        double purchaseAmount = (model.data!.purchases![i].amount ?? 0).toDouble();
        
        totalSales += salesAmount;
        totalPurchases += purchaseAmount;
        
        if (salesAmount > 0) daysWithSales++;
        if (purchaseAmount > 0) daysWithPurchases++;
        
        chartData.add(ChartData(
          model.data!.sales![i].date ?? '',
          salesAmount,
          purchaseAmount,
        ));
        
        // Print first few data points
        if (i < 5) {
          print('Data[$i]: Date=${model.data!.sales![i].date}, Sales=$salesAmount, Purchase=$purchaseAmount');
        }
      }
      
      print('Total chart data points: ${chartData.length}');
      print('Total Sales: \$${totalSales.toStringAsFixed(2)}');
      print('Total Purchases: \$${totalPurchases.toStringAsFixed(2)}');
      print('Days with Sales: $daysWithSales');
      print('Days with Purchases: $daysWithPurchases');
      print('Max Y value: ${_getMaxY()}');
    } else {
      print('ERROR: Sales or purchases data is null!');
    }
    print('=== CHART DEBUG END ===');
  }

  @override
  Widget build(BuildContext context) {
    print('=== CHART BUILD DEBUG ===');
    print('Chart data length: ${chartData.length}');
    print('Chart data empty: ${chartData.isEmpty}');
    
    // Show message if no chart data
    if (chartData.isEmpty) {
      print('Showing no chart data message');
      return const Center(
        child: Text(
          'No chart data available',
          style: TextStyle(color: kGreyTextColor),
        ),
      );
    }
    
    // Check if all data is zero
    bool allDataZero = chartData.every((data) => data.y == 0 && data.y1 == 0);
    
    print('Building chart with ${chartData.length} data points');
    print('Max Y value: ${_getMaxY()}');
    
    // Try to build the chart, if it fails, show a simple fallback
    try {
      return Container(
        height: 250,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: allDataZero 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sales/purchase data for selected period',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try selecting a different time period',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartData.length * 50.0, // Adjust width based on data points
                child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String weekDay = chartData[group.x].x;
                      double actualValue = rod.toY > 0.1 ? rod.toY : 0; // Handle the minimum height for zero values
                      
                      if (rodIndex == 0) {
                        return BarTooltipItem(
                          'Sales\nDay $weekDay\n\$${actualValue.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      } else {
                        return BarTooltipItem(
                          'Purchase\nDay $weekDay\n\$${actualValue.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }
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
                      reservedSize: 40,
                      interval: _getMaxY() / 5, // Show 5 intervals
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xffD1D5DB), width: 1),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: _getMaxY() / 5,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xffD1D5DB),
                      dashArray: [4, 4],
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Chart build error: $e');
      return Container(
        height: 250,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Chart Error: $e',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Data points: ${chartData.length}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  double _getMaxY() {
    if (chartData.isEmpty) return 100;
    
    double maxY = 0;
    bool hasNonZeroData = false;
    
    for (var data in chartData) {
      if (data.y > 0 || data.y1 > 0) hasNonZeroData = true;
      maxY = maxY > data.y ? maxY : data.y;
      maxY = maxY > data.y1 ? maxY : data.y1;
    }
    
    // If maxY is 0 and no non-zero data, set a minimum scale for visualization
    if (maxY == 0) {
      return hasNonZeroData ? 100 : 50; // Lower scale when all data is zero
    }
    
    // For small amounts (less than 1000), use smaller intervals
    if (maxY < 1000) {
      // Add 30% padding for small amounts
      double paddedMax = maxY * 1.3;
      // Round up to the nearest 25 for better granularity
      return ((paddedMax / 25).ceil() * 25).toDouble();
    } else {
      // Add 20% padding to the max value for better visibility
      double paddedMax = maxY * 1.2;
      // Round up to the nearest 50 for cleaner scale
      return ((paddedMax / 50).ceil() * 50).toDouble();
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    return chartData.asMap().entries.map((entry) {
      int index = entry.key;
      ChartData data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.y > 0 ? data.y : 0.1,
            color: data.y > 0 ? Colors.green : Colors.grey.withOpacity(0.5),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: data.y1 > 0 ? data.y1 : 0.1,
            color: data.y1 > 0 ? kMainColor : Colors.grey.withOpacity(0.5),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 6,
        groupVertically: true,
      );
    }).toList();
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff4D4D4D),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Add null safety check
    if (chartData.isEmpty || value.toInt() >= chartData.length) {
      return const SizedBox.shrink();
    }
    
    String text = chartData[value.toInt()].x;
    
    // Show only every 3rd label to avoid overcrowding
    if (value.toInt() % 3 != 0 && chartData.length > 10) {
      return const SizedBox.shrink();
    }

    // Format the date better - handle hour format (00-23) and day format
    String formattedText;
    if (text.length == 2 && int.tryParse(text) != null) {
      int hour = int.parse(text);
      if (hour >= 0 && hour <= 23) {
        // This is hour format, show as time
        formattedText = '${hour.toString().padLeft(2, '0')}:00';
      } else {
        // This might be day format
        formattedText = 'Day $text';
      }
    } else {
      formattedText = text;
    }

    return SideTitleWidget(
      space: 8,
      meta: meta,
      child: Text(formattedText, style: style),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff4D4D4D),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Only show integer values
    if (value % 1 != 0) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        '\$${value.toInt()}',
        style: style,
      ),
    );
  }
}

///---------------------------------dash line-------------------------------

class DashedBarPainter extends CustomPainter {
  final double barHeight;
  final Color barColor;
  final double dashWidth;
  final double dashSpace;

  DashedBarPainter({
    required this.barHeight,
    required this.barColor,
    this.dashWidth = 4.0,
    this.dashSpace = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = barHeight;

    final dashPath = Path();
    for (double i = 0; i < size.width; i += dashWidth + dashSpace) {
      dashPath.addRect(Rect.fromLTWH(i, 0, dashWidth, size.height));
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}