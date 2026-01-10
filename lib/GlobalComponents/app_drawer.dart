import 'package:flutter/material.dart';
import 'package:mobile_pos/Combo/combo_list_screen.dart';
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
import 'package:mobile_pos/Screens/saloon_service_list.dart';
import 'package:mobile_pos/Screens/Waste_management/waste_management_screen.dart';
import 'package:mobile_pos/Screens/HoldOrders/hold_orders_screen.dart';
//import 'package:mobile_pos/Screens/Combo/combo_list_screen.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/extraazwebview.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';
import 'package:mobile_pos/services/permission_service.dart';
import 'package:mobile_pos/Screens/Settings/dashboard_toggle_settings_dialog.dart';
import 'package:mobile_pos/thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends ConsumerWidget {
  final dynamic businessDetails;

  const AppDrawer({
    super.key,
    required this.businessDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: FutureBuilder<List<Widget>>(
          future: _buildDrawerItems(context, ref),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // Drawer Header with Profile Icon
                _buildDrawerHeader(context),
                ...snapshot.data!,
                SizedBox(height: 8),
                // Extraaaz Branding
                _buildExtraaazBranding(context),
                SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build drawer items dynamically based on permissions and shop features
  Future<List<Widget>> _buildDrawerItems(BuildContext context, WidgetRef ref) async {
    final permissionService = PermissionService();
    final role = await permissionService.getUserRole();
    final visibility = await permissionService.getVisibilityPermissions();

    // Get shop features
    final prefs = await SharedPreferences.getInstance();
    final shopFeatures = prefs.getStringList('shop_features') ?? [];

    List<Widget> items = [];

    // If role is not 'staff', show all screens based on shop features
    if (role != 'staff') {
      return _getAllDrawerItems(context, shopFeatures, ref);
    }

    // If no visibility data for staff, show all screens based on shop features
    if (visibility == null) {
      return _getAllDrawerItems(context, shopFeatures, ref);
    }

    // Add Sales item if permission granted and feature enabled
    if (visibility[PermissionService.SALE_PERMISSION] == true &&
        shopFeatures.contains('sale')) {
      items.add(_buildDrawerItem(
        icon: Icons.shopping_cart,
        title: 'Sales',
        subtitle: '',
        color: Colors.green,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddSalesScreen(customerModel: null)),
          );
        },
      ));
    }

    // Add Purchase item if permission granted and feature enabled
    if (visibility[PermissionService.PURCHASE_PERMISSION] == true &&
        shopFeatures.contains('purchase')) {
      items.add(_buildDrawerItem(
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
                    AddAndUpdatePurchaseScreen(supplierModel: null)),
          );
        },
      ));
    }

    // Add Products item if permission granted and feature enabled
    if (visibility[PermissionService.PRODUCT_PERMISSION] == true &&
        shopFeatures.contains('product')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Sales List item if permission granted and feature enabled
    if (visibility[PermissionService.SALES_LIST_PERMISSION] == true &&
        shopFeatures.contains('sale')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Purchase List item if permission granted and feature enabled
    if (visibility[PermissionService.PURCHASE_LIST_PERMISSION] == true &&
        shopFeatures.contains('purchase')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Customer/Supplier List item if permission granted and feature enabled
    if (visibility[PermissionService.PARTIES_PERMISSION] == true &&
        shopFeatures.contains('parties')) {
      items.add(_buildDrawerItem(
        icon: Icons.people_outline,
        title: 'Customer/Supplier List',
        subtitle: '',
        color: Colors.cyan,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CustomerList()),
          );
        },
      ));
    }

    // Add Hold Orders - Always visible for staff
    items.add(_buildDrawerItem(
      icon: Icons.pending_actions,
      title: 'Hold Orders',
      subtitle: '',
      color: Colors.orange,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HoldOrdersScreen()),
        );
      },
    ));

    // Add Dashboard item if permission granted and feature enabled
    if (visibility[PermissionService.DASHBOARD_PERMISSION] == true &&
        shopFeatures.contains('dashboard')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Reports item if permission granted and feature enabled
    if (visibility[PermissionService.REPORTS_PERMISSION] == true &&
        shopFeatures.contains('reports')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Stock List item if permission granted and feature enabled
    if (visibility[PermissionService.STOCK_PERMISSION] == true &&
        shopFeatures.contains('stock')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Waste Management item if permission granted and feature enabled
    if (visibility[PermissionService.STOCK_PERMISSION] == true &&
        shopFeatures.contains('stock')) {
      items.add(_buildDrawerItem(
        icon: Icons.delete_outline,
        title: 'Waste Management',
        subtitle: '',
        color: Colors.red[600]!,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const WasteManagementScreen()),
          );
        },
      ));
    }

    // Add Expenses item if permission granted and feature enabled
    if (visibility[PermissionService.ADD_EXPENSE_PERMISSION] == true &&
        shopFeatures.contains('expense')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Income item if permission granted and feature enabled
    if (visibility[PermissionService.ADD_INCOME_PERMISSION] == true &&
        shopFeatures.contains('income')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Saloon Service List - Only for salon category
    if (visibility[PermissionService.SALE_PERMISSION] == true &&
        shopFeatures.contains('salon_service')) {
      items.add(_buildDrawerItem(
        icon: Icons.content_cut,
        title: 'Saloon Service List',
        subtitle: '',
        color: Colors.orange,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SaloonServiceListScreen()),
          );
        },
      ));
    }

    // Printer Connect - Always visible
    items.add(_buildDrawerItem(
      icon: Icons.print,
      title: 'Connect Printer',
      subtitle: '',
      color: Colors.blue[700]!,
      onTap: () async {
        Navigator.pop(context);
        final thermalPrinter = ref.read(thermalPrinterProvider);
        await thermalPrinter.getBluetooth();
        await thermalPrinter.listOfBluDialog(context: context);
      },
    ));

    // Toggle Settings - Always visible
    items.add(_buildDrawerItem(
      icon: Icons.toggle_on,
      title: 'Toggle Settings',
      subtitle: '',
      color: Colors.blue[600]!,
      onTap: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => const DashboardToggleSettingsDialog(),
        );
      },
    ));

    // Settings - Always visible
    items.add(_buildDrawerItem(
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
    ));

    return items;
  }

  // Get all drawer items (for admin/owner with full access) filtered by shop features
  List<Widget> _getAllDrawerItems(
      BuildContext context, List<String> shopFeatures, WidgetRef ref) {
    List<Widget> items = [];

    // Add Sales if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('sale')) {
      items.add(_buildDrawerItem(
        icon: Icons.shopping_cart,
        title: 'Sales',
        subtitle: '',
        color: Colors.green,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddSalesScreen(customerModel: null)),
          );
        },
      ));
    }

    // Add Purchase if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('purchase')) {
      items.add(_buildDrawerItem(
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
                    AddAndUpdatePurchaseScreen(supplierModel: null)),
          );
        },
      ));
    }

    // Add Products if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('product')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Combo
    items.add(_buildDrawerItem(
      icon: Icons.shopping_basket_outlined,
      title: 'Combo',
      subtitle: '',
      color: Colors.indigo,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ComboListScreen()),
        );
      },
    ));

    // Add Sales List if sale feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('sale')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Purchase List if purchase feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('purchase')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Customer/Supplier List if parties feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('parties')) {
      items.add(_buildDrawerItem(
        icon: Icons.people_outline,
        title: 'Customer/Supplier List',
        subtitle: '',
        color: Colors.cyan,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CustomerList()),
          );
        },
      ));
    }

    // Add Hold Orders - Always visible
    items.add(_buildDrawerItem(
      icon: Icons.pending_actions,
      title: 'Hold Orders',
      subtitle: '',
      color: Colors.orange,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HoldOrdersScreen()),
        );
      },
    ));

    // Add Dashboard if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('dashboard')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Reports if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('reports')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Stock List if stock feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('stock')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Waste Management if stock feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('stock')) {
      items.add(_buildDrawerItem(
        icon: Icons.delete_outline,
        title: 'Waste Management',
        subtitle: '',
        color: Colors.red[600]!,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const WasteManagementScreen()),
          );
        },
      ));
    }

    // Add Expenses if expense feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('expense')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Income if income feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('income')) {
      items.add(_buildDrawerItem(
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
      ));
    }

    // Add Saloon Service List - Only for salon category
    if (shopFeatures.isEmpty || shopFeatures.contains('salon_service')) {
      items.add(_buildDrawerItem(
        icon: Icons.content_cut,
        title: 'Saloon Service List',
        subtitle: '',
        color: Colors.orange,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SaloonServiceListScreen()),
          );
        },
      ));
    }

    // Printer Connect - Always visible
    items.add(_buildDrawerItem(
      icon: Icons.print,
      title: 'Connect Printer',
      subtitle: '',
      color: Colors.blue[700]!,
      onTap: () async {
        Navigator.pop(context);
        final thermalPrinter = ref.read(thermalPrinterProvider);
        await thermalPrinter.getBluetooth();
        await thermalPrinter.listOfBluDialog(context: context);
      },
    ));

    // Toggle Settings - Always visible
    items.add(_buildDrawerItem(
      icon: Icons.toggle_on,
      title: 'POS Feature Controls',
      subtitle: '',
      color: Colors.blue[600]!,
      onTap: () {
        Navigator.pop(context);
        showDialog(
         // fullscreenDialog: true,
          context: context,
          builder: (context) => const DashboardToggleSettingsDialog(),
        );
      },
    ));

    // Settings - Always visible
    items.add(_buildDrawerItem(
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
    ));

    return items;
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