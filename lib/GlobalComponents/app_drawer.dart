import 'package:flutter/material.dart';
import 'package:mobile_pos/Screens/Customers/customer_list.dart';
import 'package:mobile_pos/Screens/Expense/expense_list.dart';
import 'package:mobile_pos/Screens/Income/income_list.dart';
import 'package:mobile_pos/Screens/Products/product_list_screen.dart';
import 'package:mobile_pos/Screens/Profile%20Screen/profile_details.dart';
import 'package:mobile_pos/Screens/Purchase%20List/purchase_list_screen.dart';
import 'package:mobile_pos/Screens/Purchase/add_and_edit_purchase.dart';
import 'package:mobile_pos/Screens/Report/reports.dart';
import 'package:mobile_pos/Screens/Sales%20List/sales_list_screen.dart';
import 'package:mobile_pos/Screens/Sales/add_sales.dart';
import 'package:mobile_pos/Screens/Settings/settings_screen.dart';
import 'package:mobile_pos/Screens/stock_list/stock_list_main.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/extraazwebview.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';

class AppDrawer extends StatelessWidget {
  final dynamic businessDetails;

  const AppDrawer({
    super.key,
    required this.businessDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header with Profile Icon
            _buildDrawerHeader(context),

            // Main Modules Section
            _buildDrawerItem(
              icon: Icons.shopping_cart,
              title: 'Sales',
              subtitle: '',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AddSalesScreen(customerModel: null)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_bag,
              title: 'Purchase',
              subtitle: '',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AddAndUpdatePurchaseScreen(customerModel: null)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Parties',
              subtitle: '',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerList()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.inventory,
              title: 'Products',
              subtitle: '',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductList()),
                );
              },
            ),

            // Lists Section
            _buildDrawerItem(
              icon: Icons.list_alt,
              title: 'Sales List',
              subtitle: '',
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesListScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_basket,
              title: 'Purchase List',
              subtitle: '',
              color: Colors.indigo,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PurchaseListScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.people_outline,
              title: 'Customer List',
              subtitle: '',
              color: Colors.cyan,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerList()),
                );
              },
            ),

            // Analytics Section
            _buildDrawerItem(
              icon: Icons.analytics,
              title: 'Dashboard',
              subtitle: '',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.assessment,
              title: 'Reports',
              subtitle: '',
              color: Colors.deepPurple,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Reports()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.inventory_2,
              title: 'Stock List',
              subtitle: '',
              color: Colors.brown,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StockList(isFromReport: false)),
                );
              },
            ),

            // Financial Section
            _buildDrawerItem(
              icon: Icons.money_off,
              title: 'Expenses',
              subtitle: '',
              color: Colors.red[600]!,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpenseList()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.attach_money,
              title: 'Income',
              subtitle: '',
              color: Colors.green[600]!,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IncomeList()),
                );
              },
            ),

            // Settings Section
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: '',
              color: Colors.grey[600]!,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingScreen()),
                );
              },
            ),

            SizedBox(height: 8),

            // Extraaaz Branding
            _buildExtraaazBranding(context),

            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kMainColor,
            kMainColor.withOpacity(0.9),
            kMainColor.withOpacity(0.7),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -15,
            left: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileDetails()),
                );
              },
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: businessDetails.pictureUrl != null
                          ? ClipOval(
                              child: Image.network(
                                '${APIConfig.domain}${businessDetails.pictureUrl}',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 32,
                                    color: kMainColor,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 32,
                              color: kMainColor,
                            ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessDetails.user?.name ?? 'User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Tap to edit profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            spreadRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraaazBranding(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kMainColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExtraaazWebView()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "extraazLogo",
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.asset(
                      "images/extraaaz-logo-white-DIqhPNzv.webp",
                      height: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Powered by Extraaaz",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}