import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/model/dashboard_overview_model.dart';
import 'dart:math' as math;

class AnimatedSalesPurchaseGraph extends StatefulWidget {
  const AnimatedSalesPurchaseGraph({Key? key}) : super(key: key);

  @override
  State<AnimatedSalesPurchaseGraph> createState() => _AnimatedSalesPurchaseGraphState();
}

class _AnimatedSalesPurchaseGraphState extends State<AnimatedSalesPurchaseGraph>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Tooltip state
  bool _showTooltip = false;
  Offset? _tooltipPosition;
  Map<String, dynamic>? _selectedData;

  // Time period selection
  String selectedTime = 'Current Month';

  @override
  void initState() {
    super.initState();
    
    // Main animation controller for graph drawing
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    


    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));


    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getProcessedData(List<Sales>? sales, List<Purchases>? purchases) {
    // Validation: Check if data is null or empty
    if (sales == null && purchases == null) {
      print('Graph Validation: Both sales and purchases data are null');
      return [];
    }
    
    if ((sales == null || sales.isEmpty) && (purchases == null || purchases.isEmpty)) {
      print('Graph Validation: Both sales and purchases data are empty');
      return [];
    }
    
    // Create a map to combine sales and purchases by date
    Map<String, Map<String, dynamic>> combinedData = {};
    
    // Process sales data with validation - ONLY include days with actual amounts
    if (sales != null && sales.isNotEmpty) {
      for (var sale in sales) {
        try {
          // Validate sale data
          if (sale.date != null && sale.amount != null) {
            String dateStr = sale.date!.toString().trim();
            if (dateStr.isNotEmpty) {
              double amount = sale.amount!.toDouble();
              
              // CRITICAL FILTER: Only include days with actual amounts > 0
              if (amount.isFinite && amount > 0) {
                combinedData[dateStr] = {
                  'date': dateStr,
                  'sales': amount,
                  'purchase': 0.0,
                };
                print('Graph Filter: Added sale with amount - Date: $dateStr, Amount: $amount');
              } else {
                print('Graph Filter: Skipped sale with zero/negative amount - Date: $dateStr, Amount: $amount');
              }
            }
          }
        } catch (e) {
          print('Graph Validation: Error processing sale data - $e');
        }
      }
    } else {
      print('Graph Validation: Sales data is null or empty');
    }
    
    // Process purchases data with validation - ONLY include days with actual amounts
    if (purchases != null && purchases.isNotEmpty) {
      for (var purchase in purchases) {
        try {
          // Validate purchase data
          if (purchase.date != null && purchase.amount != null) {
            String dateStr = purchase.date!.toString().trim();
            if (dateStr.isNotEmpty) {
              double amount = purchase.amount!.toDouble();
              
              // CRITICAL FILTER: Only include days with actual amounts > 0
              if (amount.isFinite && amount > 0) {
                if (combinedData.containsKey(dateStr)) {
                  combinedData[dateStr]!['purchase'] = amount;
                } else {
                  combinedData[dateStr] = {
                    'date': dateStr,
                    'sales': 0.0,
                    'purchase': amount,
                  };
                }
                print('Graph Filter: Added purchase with amount - Date: $dateStr, Amount: $amount');
              } else {
                print('Graph Filter: Skipped purchase with zero/negative amount - Date: $dateStr, Amount: $amount');
              }
            }
          }
        } catch (e) {
          print('Graph Validation: Error processing purchase data - $e');
        }
      }
    } else {
      print('Graph Validation: Purchases data is null or empty');
    }
    
    // Validation: Check if we have any valid data with actual amounts
    if (combinedData.isEmpty) {
      print('Graph Filter: No days found with actual sales/purchase amounts > 0');
      print('Graph Filter: This means all data has zero amounts and will not be displayed');
      return [];
    }
    
    // Convert to list and sort by date with validation
    List<Map<String, dynamic>> result = combinedData.values.toList();
    
    try {
      result.sort((a, b) {
        try {
          // Handle different date formats
          String dateA = a['date'].toString();
          String dateB = b['date'].toString();
          
          // If dates are just numbers (like "00", "01", "15"), sort numerically
          if (RegExp(r'^\d+$').hasMatch(dateA) && RegExp(r'^\d+$').hasMatch(dateB)) {
            return int.parse(dateA).compareTo(int.parse(dateB));
          }
          
          // Otherwise, sort alphabetically
          return dateA.compareTo(dateB);
        } catch (e) {
          print('Graph Validation: Error sorting data - $e');
          return 0; // Keep original order if sorting fails
        }
      });
    } catch (e) {
      print('Graph Validation: Critical error during sorting - $e');
      return [];
    }
    
    // Format dates to show readable labels with validation
    for (var item in result) {
      try {
        String dateStr = item['date'].toString();
        
        // Handle numeric dates (like "00", "01", "15")
        if (RegExp(r'^\d+$').hasMatch(dateStr)) {
          int dayNum = int.parse(dateStr);
          item['month'] = 'Day $dayNum';
        } else {
          // Handle other date formats
          try {
            DateTime date = DateTime.parse(dateStr);
            item['month'] = _getMonthName(date.month);
          } catch (e) {
            item['month'] = dateStr; // Use the date as is
          }
        }
        
        // Final validation of amounts
        double sales = item['sales'] as double;
        double purchase = item['purchase'] as double;
        
        if (!sales.isFinite || !purchase.isFinite || sales < 0 || purchase < 0) {
          print('Graph Validation: Invalid amounts found - Sales: $sales, Purchase: $purchase');
          item['sales'] = 0.0;
          item['purchase'] = 0.0;
        }
      } catch (e) {
        print('Graph Validation: Error formatting date - $e');
        item['month'] = 'Invalid';
        item['sales'] = 0.0;
        item['purchase'] = 0.0;
      }
    }
    
    // Final validation: Check if result has valid data
    if (result.isEmpty) {
      print('Graph Validation: Final result is empty');
      return [];
    }
    
    // Debug print to see processed data
    print('Graph Validation: Successfully processed ${result.length} data points');
    print('Processed data for graph: $result');
    
    return result;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  double getMaxValue(List<Map<String, dynamic>> data) {
    // Validation: Check if data is empty
    if (data.isEmpty) {
      print('Graph Validation: getMaxValue - Data is empty, returning default 1000.0');
      return 1000.0;
    }
    
    try {
      // Validate and calculate max value
      List<double> allValues = [];
      
      for (var item in data) {
        try {
          double sales = item['sales'] as double? ?? 0.0;
          double purchase = item['purchase'] as double? ?? 0.0;
          
          // Validate values
          if (sales.isFinite && purchase.isFinite && sales >= 0 && purchase >= 0) {
            allValues.add(math.max(sales, purchase));
          } else {
            print('Graph Validation: getMaxValue - Invalid values found - Sales: $sales, Purchase: $purchase');
            allValues.add(0.0);
          }
        } catch (e) {
          print('Graph Validation: getMaxValue - Error processing item - $e');
          allValues.add(0.0);
        }
      }
      
      if (allValues.isEmpty) {
        print('Graph Validation: getMaxValue - No valid values found, returning default 100.0');
        return 100.0;
      }
      
      double maxVal = allValues.reduce((a, b) => math.max(a, b));
      
      // If all values are 0, set a minimum scale for visibility
      if (maxVal == 0) {
        print('Graph Validation: getMaxValue - All values are 0, setting minimum scale to 100.0');
        return 100.0;
      }
      
      // Ensure max value is reasonable (not too large)
      if (maxVal > 1000000) {
        print('Graph Validation: getMaxValue - Value too large ($maxVal), capping at 1000000');
        return 1000000.0;
      }
      
      print('Graph Validation: getMaxValue - Calculated max value: $maxVal');
      return maxVal;
    } catch (e) {
      print('Graph Validation: getMaxValue - Critical error - $e');
      return 1000.0;
    }
  }

  void _onTapDown(Offset localPosition, double maxValue, List<Map<String, dynamic>> salesData) {
    // Validation: Check if data is empty
    if (salesData.isEmpty) {
      print('Graph Validation: _onTapDown - Sales data is empty');
      return;
    }
    
    // Validation: Check if maxValue is valid
    if (!maxValue.isFinite || maxValue <= 0) {
      print('Graph Validation: _onTapDown - Invalid maxValue: $maxValue');
      return;
    }
    
    try {
      final padding = 40.0;
      final chartWidth = 248.0 - 2 * padding; // Container width minus padding
      final chartHeight = 248.0 - 2 * padding; // Container height minus padding
      
      // Find the closest data point
      int closestIndex = 0;
      double minDistance = double.infinity;
      
      for (int i = 0; i < salesData.length; i++) {
        try {
          final x = padding + i * (chartWidth / (salesData.length - 1));
          final distance = (localPosition.dx - x).abs();
          
          if (distance < minDistance) {
            minDistance = distance;
            closestIndex = i;
          }
        } catch (e) {
          print('Graph Validation: _onTapDown - Error calculating distance - $e');
        }
      }
      
      // Validation: Check if closestIndex is valid
      if (closestIndex < 0 || closestIndex >= salesData.length) {
        print('Graph Validation: _onTapDown - Invalid closestIndex: $closestIndex');
        return;
      }
      
      // Calculate the Y position for the data point with validation
      try {
        final salesValue = (salesData[closestIndex]['sales'] as double?) ?? 0.0;
        final purchaseValue = (salesData[closestIndex]['purchase'] as double?) ?? 0.0;
        final monthValue = salesData[closestIndex]['month']?.toString() ?? 'Unknown';
        
        // Validate values
        if (!salesValue.isFinite || !purchaseValue.isFinite || salesValue < 0 || purchaseValue < 0) {
          print('Graph Validation: _onTapDown - Invalid values - Sales: $salesValue, Purchase: $purchaseValue');
          return;
        }
        
        final maxValuePoint = math.max(salesValue, purchaseValue);
        final y = padding + chartHeight - (maxValuePoint / maxValue) * chartHeight;
        
        // Validate position
        if (!y.isFinite || y < 0 || y > chartHeight + padding) {
          print('Graph Validation: _onTapDown - Invalid Y position: $y');
          return;
        }
        
        setState(() {
          _selectedData = {
            'month': monthValue,
            'sales': salesValue,
            'purchase': purchaseValue,
          };
          _tooltipPosition = Offset(
            padding + closestIndex * (chartWidth / (salesData.length - 1)),
            y,
          );
          _showTooltip = true;
        });
        
        print('Graph Validation: _onTapDown - Tooltip shown for $monthValue - Sales: $salesValue, Purchase: $purchaseValue');
        
        // Hide tooltip after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showTooltip = false;
            });
          }
        });
      } catch (e) {
        print('Graph Validation: _onTapDown - Error processing data point - $e');
      }
    } catch (e) {
      print('Graph Validation: _onTapDown - Critical error - $e');
    }
  }

  Widget _buildTooltip(Map<String, dynamic> data) {
    // Validation: Check if data is valid
    if (data.isEmpty) {
      print('Graph Validation: _buildTooltip - Data is empty');
      return const SizedBox.shrink();
    }
    
    try {
      // Validate and format data
      String month = data['month']?.toString() ?? 'Unknown';
      double sales = 0.0;
      double purchase = 0.0;
      
      try {
        sales = (data['sales'] as double?) ?? 0.0;
        purchase = (data['purchase'] as double?) ?? 0.0;
        
        // Validate amounts
        if (!sales.isFinite || !purchase.isFinite || sales < 0 || purchase < 0) {
          print('Graph Validation: _buildTooltip - Invalid amounts - Sales: $sales, Purchase: $purchase');
          sales = 0.0;
          purchase = 0.0;
        }
      } catch (e) {
        print('Graph Validation: _buildTooltip - Error parsing amounts - $e');
        sales = 0.0;
        purchase = 0.0;
      }
      
      return GestureDetector(
        onTap: () {
          setState(() {
            _showTooltip = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      month,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showTooltip = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sales: \$${sales.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Purchase: \$${purchase.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Graph Validation: _buildTooltip - Critical error - $e');
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Error displaying data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhite,
        surfaceTintColor: kWhite,
        elevation: 0,
        title: Text(
          'Sales & Purchase Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: kTitleColor,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: kMainColor),
            onSelected: (value) {
              setState(() {
                selectedTime = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'Yesterday', child: Text('Yesterday')),
              const PopupMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
              const PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
              const PopupMenuItem(value: 'Current Month', child: Text('Current Month')),
              const PopupMenuItem(value: 'Last Month', child: Text('Last Month')),
              const PopupMenuItem(value: 'Current Year', child: Text('Current Year')),
            ],
          ),
          IconButton(
            onPressed: () {
              _animationController.reset();
              _fadeController.reset();
              _fadeController.forward();
              Future.delayed(const Duration(milliseconds: 300), () {
                _animationController.forward();
              });
            },
            icon: const Icon(Icons.refresh, color: kMainColor),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final dashboardInfo = ref.watch(dashboardInfoProvider(selectedTime.toLowerCase()));
          
          return dashboardInfo.when(
            data: (dashboard) {
              final processedData = getProcessedData(dashboard.data?.sales, dashboard.data?.purchases);
              final maxValue = getMaxValue(processedData);
              
              if (processedData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Transaction Data',
                        style: TextStyle(
                          color: kGreyTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No sales or purchase transactions found with amounts > 0 for $selectedTime',
                        style: TextStyle(
                          color: kGreyTextColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Graph only shows days with actual transaction amounts',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time period selector and summary
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: kMainColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Period: $selectedTime',
                                    style: const TextStyle(
                                      color: kTitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.analytics, color: kMainColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active Days: ${processedData.length}',
                                    style: const TextStyle(
                                      color: kTitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Filter information
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, color: Colors.blue, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Showing only days with actual transaction amounts',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Main Graph Container
                      _buildMainGraph(theme, maxValue, processedData),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load data',
                    style: TextStyle(
                      color: kGreyTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: kGreyTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildMainGraph(ThemeData theme, double maxValue, List<Map<String, dynamic>> salesData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title
          Text(
            'Sales & Purchase Analytics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: kTitleColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monthly Trends Comparison',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: kGreyTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Line chart container
          Container(
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTapDown: (details) => _onTapDown(details.localPosition, maxValue, salesData),
              onTap: () {
                // Hide tooltip if tapped on empty area
                if (_showTooltip) {
                  setState(() {
                    _showTooltip = false;
                  });
                }
              },
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: LineChartPainter(
                          salesData: salesData,
                          maxValue: maxValue,
                          animation: _animationController.value,
                          salesColor: Colors.green,
                          purchaseColor: Colors.blue,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                  if (_showTooltip && _tooltipPosition != null && _selectedData != null)
                    Positioned(
                      left: _tooltipPosition!.dx - 60,
                      top: _tooltipPosition!.dy - 80,
                      child: _buildTooltip(_selectedData!),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Tap instruction
          Center(
            child: Text(
              'Tap on the graph to view detailed values',
              style: TextStyle(
                color: kGreyTextColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legend with values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendWithValue('Sales', Colors.green, 'Total: \$${salesData.isEmpty ? '0' : salesData.map((e) => e['sales'] as double).reduce((a, b) => a + b).toStringAsFixed(0)}'),
              _buildLegendWithValue('Purchase', Colors.blue, 'Total: \$${salesData.isEmpty ? '0' : salesData.map((e) => e['purchase'] as double).reduce((a, b) => a + b).toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildLegendWithValue(String label, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: kTitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> salesData;
  final double maxValue;
  final double animation;
  final Color salesColor;
  final Color purchaseColor;

  LineChartPainter({
    required this.salesData,
    required this.maxValue,
    required this.animation,
    required this.salesColor,
    required this.purchaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid
    _drawGrid(canvas, size);
    
    // Calculate chart dimensions with padding
    final padding = 40.0;
    final chartWidth = size.width - 2 * padding;
    final chartHeight = size.height - 2 * padding;
    
    // Calculate points
    final salesPoints = _calculatePoints(salesData, 'sales', chartWidth, chartHeight, padding);
    final purchasePoints = _calculatePoints(salesData, 'purchase', chartWidth, chartHeight, padding);
    
    // Draw lines with animation
    _drawLine(canvas, salesPoints, salesColor, 'Sales');
    _drawLine(canvas, purchasePoints, purchaseColor, 'Purchase');
    
    // Draw data points
    _drawDataPoints(canvas, salesPoints, salesColor);
    _drawDataPoints(canvas, purchasePoints, purchaseColor);
    
    // Draw labels
    _drawLabels(canvas, size, padding);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1.0;

    final padding = 40.0;
    
    // Horizontal lines
    for (int i = 0; i <= 5; i++) {
      final y = padding + (size.height - 2 * padding) * i / 5;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }
    
    // Vertical lines
    for (int i = 0; i <= salesData.length - 1; i++) {
      final x = padding + (size.width - 2 * padding) * i / (salesData.length - 1);
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, size.height - padding),
        gridPaint,
      );
    }
  }

  List<Offset> _calculatePoints(List<Map<String, dynamic>> data, String key, double width, double height, double padding) {
    final points = <Offset>[];
    final stepX = width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final value = data[i][key] as int;
      final x = padding + i * stepX;
      final y = padding + height - (value / maxValue) * height;
      points.add(Offset(x, y));
    }
    
    return points;
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color, String label) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // Animate the line drawing
    for (int i = 1; i < points.length; i++) {
      final currentPoint = points[i];
      final animatedY = points[0].dy + (currentPoint.dy - points[0].dy) * animation;
      final animatedPoint = Offset(currentPoint.dx, animatedY);
      
      if (i == 1) {
        path.lineTo(animatedPoint.dx, animatedPoint.dy);
      } else {
        // Create smooth curves
        final prevPoint = points[i - 1];
        final prevAnimatedY = points[0].dy + (prevPoint.dy - points[0].dy) * animation;
        final prevAnimatedPoint = Offset(prevPoint.dx, prevAnimatedY);
        
        final controlPoint1 = Offset(
          prevAnimatedPoint.dx + (animatedPoint.dx - prevAnimatedPoint.dx) / 3,
          prevAnimatedPoint.dy,
        );
        final controlPoint2 = Offset(
          animatedPoint.dx - (animatedPoint.dx - prevAnimatedPoint.dx) / 3,
          animatedPoint.dy,
        );
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          animatedPoint.dx, animatedPoint.dy,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawDataPoints(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      final animatedY = points[0].dy + (point.dy - points[0].dy) * animation;
      final animatedPoint = Offset(point.dx, animatedY);
      
      // Draw outer circle
      canvas.drawCircle(animatedPoint, 6, paint);
      
      // Draw inner white circle
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(animatedPoint, 3, whitePaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size, double padding) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Draw month labels
    for (int i = 0; i < salesData.length; i++) {
      final x = padding + (size.width - 2 * padding) * i / (salesData.length - 1);
      
      textPainter.text = TextSpan(
        text: salesData[i]['month'],
        style: TextStyle(
          color: kGreyTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - padding + 15),
      );
    }

    // Draw Y-axis labels
    for (int i = 0; i <= 5; i++) {
      final y = padding + (size.height - 2 * padding) * i / 5;
      final value = (maxValue * (5 - i) / 5).toInt();
      
      textPainter.text = TextSpan(
        text: '\$${value.toString()}',
        style: TextStyle(
          color: kGreyTextColor,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
