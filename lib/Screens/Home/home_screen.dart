import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';
import 'package:mobile_pos/Screens/Profile%20Screen/profile_details.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:showcaseview/showcaseview.dart';

// Import required screens for navigation
import '../Sales/add_sales.dart';
import '../Purchase/add_and_edit_purchase.dart';
import '../Customers/add_customer.dart';
import '../Products/add_product.dart';
import '../Products/low_stock_products_screen.dart';
import '../Report/reports.dart';

import '../../GlobalComponents/app_drawer.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/product_provider.dart';
import '../../constant.dart';
import '../Customers/Provider/customer_provider.dart';
import 'Provider/banner_provider.dart';
import '../../services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Repository/constant_functions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController pageController = PageController(initialPage: 0);

  bool _isRefreshing = false;
  bool _showcaseStarted = false;

  // Showcase keys
  final GlobalKey _addSaleKey = GlobalKey();
  final GlobalKey _addPurchaseKey = GlobalKey();
  final GlobalKey _addCustomerKey = GlobalKey();
  final GlobalKey _addProductKey = GlobalKey();
  final GlobalKey _dashboardKey = GlobalKey();
  final GlobalKey _reportsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Start showcase after widget is built - wait for cards to load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if showcase was already shown
      final prefs = await SharedPreferences.getInstance();
      final showcaseShown = prefs.getBool('home_showcase_shown') ?? false;

      if (showcaseShown) {
        print('📌 Home showcase already shown, skipping...');
        return;
      }

      // Wait for async data and widgets to be built
      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted && !_showcaseStarted) {
        print('🎯 Starting showcase...');
        try {
          // Start showcasing the important buttons
          ShowCaseWidget.of(context).startShowCase([
            _addSaleKey,
            _addPurchaseKey,
            _addCustomerKey,
            _addProductKey,
            _dashboardKey,
            _reportsKey,
          ]);
          print('✅ Showcase started successfully');

          // Mark showcase as shown
          await prefs.setBool('home_showcase_shown', true);
        } catch (e) {
          print('❌ Showcase error: $e');
        }
        _showcaseStarted = true;
      }
    });
  }

  Future<void> refreshAllProviders({required WidgetRef ref}) async {
    if (_isRefreshing) return; // Prevent multiple refresh calls

    _isRefreshing = true;
    try {
      // ignore: unused_result
      ref.refresh(summaryInfoProvider);
      // ignore: unused_result
      ref.refresh(bannerProvider);
      // ignore: unused_result
      ref.refresh(businessInfoProvider);
      // ignore: unused_result
      ref.refresh(businessSettingProvider);
      // ignore: unused_result
      ref.refresh(partiesProvider);
      // ignore: unused_result
      ref.refresh(getExpireDateProvider(ref));
      await Future.delayed(const Duration(seconds: 3));
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (_, ref, __) {
      final businessInfo = ref.watch(businessInfoProvider);
      return businessInfo.when(data: (details) {
        return Scaffold(
            backgroundColor: kBackgroundColor,
            drawer: AppDrawer(businessDetails: details),
            appBar: AppBar(
              backgroundColor: kWhite,
              titleSpacing: 5,
              surfaceTintColor: kWhite,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kMainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu,
                      color: kMainColor,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                // Showcase trigger button
                // IconButton(
                //   icon: Container(
                //     padding: EdgeInsets.all(8),
                //     decoration: BoxDecoration(
                //       color: Colors.green.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       Icons.play_circle_outline,
                //       color: Colors.green,
                //       size: 20,
                //     ),
                //   ),
                //   onPressed: () {
                //     // Reset showcase flag
                //     _showcaseStarted = false;
                //     // Start showcase manually
                //     WidgetsBinding.instance.addPostFrameCallback((_) async {
                //       await Future.delayed(const Duration(milliseconds: 500));
                //       if (mounted) {
                //         try {
                //           ShowCaseWidget.of(context).startShowCase([
                //             _addSaleKey,
                //             _addPurchaseKey,
                //             _addCustomerKey,
                //             _addProductKey,
                //             _dashboardKey,
                //             _reportsKey,
                //           ]);
                //           print('✅ Showcase started manually via button');
                //         } catch (e) {
                //           print('❌ Showcase error: $e');
                //         }
                //       }
                //     });
                //   },
                //   tooltip: 'Show Tour',
                // ),
                IconButton(
                    onPressed: () async => refreshAllProviders(ref: ref),
                    icon: const Icon(Icons.refresh)),
                GestureDetector(
                  onTap: () {
                    const ProfileDetails().launch(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17.5),
                      border: Border.all(color: kMainColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kMainColor.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.5),
                      child: details.pictureUrl == null
                          ? Image.asset(
                              'images/no_shop_image.png',
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              '${APIConfig.domain}${details.pictureUrl}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  color: kMainColor,
                                  size: 20,
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.user?.role == 'staff'
                        ? '${details.companyName ?? ''} [${details.user?.name ?? ''}]'
                        : details.companyName ?? '',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FutureBuilder<Map<String, String?>>(
                    future: Future.wait([
                      getOriginalApiCategoryName(),
                      getShopCategory(),
                    ]).then((results) => <String, String?>{
                      'original': results[0],
                      'mapped': results[1],
                    }),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final displayCategory = snapshot.data!['original'] ?? snapshot.data!['mapped'];
                        if (displayCategory != null && displayCategory != 'All Category' && displayCategory.isNotEmpty) {
                          return Text(
                            displayCategory,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.0,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kMainColor, kMainColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            details.user?.name ?? 'User',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Manage your business efficiently',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Low Stock Alert Section
                    Consumer(
                      builder: (context, ref, child) {
                        final lowStockCount = ref.watch(lowStockCountProvider);
                        return lowStockCount.when(
                          data: (count) {
                            if (count > 0) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 24),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.warning,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Low Stock Alert',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[800],
                                            ),
                                          ),
                                          Text(
                                            '$count products are running low on stock',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LowStockProductsScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'View',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                          loading: () => SizedBox.shrink(),
                          error: (error, stack) => SizedBox.shrink(),
                        );
                      },
                    ),

                    // Quick Actions Grid
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTitleColor,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Build quick actions dynamically based on permissions
                    FutureBuilder<List<Widget>>(
                      future: _buildQuickActionCards(ref),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final cards = snapshot.data!;
                        if (cards.isEmpty) {
                          return Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'No actions available. Contact admin for access.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: cards,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ));
      }, error: (e, stack) {
        return Text(e.toString());
      }, loading: () {
        return const Center(child: CircularProgressIndicator());
      });
    });
  }

  // Build quick action cards based on user permissions and shop features
  Future<List<Widget>> _buildQuickActionCards(WidgetRef ref) async {
    final permissionService = PermissionService();
    final role = await permissionService.getUserRole();
    final visibility = await permissionService.getVisibilityPermissions();

    // Get shop features
    final prefs = await SharedPreferences.getInstance();
    final shopFeatures = prefs.getStringList('shop_features') ?? [];

    // If role is not 'staff', show all quick actions based on shop features
    if (role != 'staff') {
      return _getAllQuickActionCards(ref, shopFeatures);
    }

    // If no visibility data for staff, show all quick actions based on shop features
    if (visibility == null) {
      return _getAllQuickActionCards(ref, shopFeatures);
    }

    List<Widget> cards = [];

    // Add Sale card if permission granted and feature enabled
    if (visibility[PermissionService.SALE_PERMISSION] == true &&
        shopFeatures.contains('sale')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.shopping_cart,
        title: 'New Sale',
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddSalesScreen(customerModel: null)),
          );
        },
        showcaseKey: _addSaleKey,
        showcaseDescription: 'Create a new sale transaction here',
      ));
    }

    // Add Purchase card if permission granted and feature enabled
    if (visibility[PermissionService.PURCHASE_PERMISSION] == true &&
        shopFeatures.contains('purchase')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.shopping_bag,
        title: 'New Purchase',
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddAndUpdatePurchaseScreen(supplierModel: null)),
          );
        },
        showcaseKey: _addPurchaseKey,
        showcaseDescription: 'Create a new purchase transaction here',
      ));
    }

    // Add Customer/Supplier card if permission granted and feature enabled
    if (visibility[PermissionService.PARTIES_PERMISSION] == true &&
        shopFeatures.contains('parties')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.people,
        title: 'Add Customer/Supplier',
        color: Colors.orange,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddParty()),
          );
          // If a customer/supplier was added, refresh data
          if (result != null) {
            refreshAllProviders(ref: ref);
          }
        },
        showcaseKey: _addCustomerKey,
        showcaseDescription: 'Add new customer or supplier here',
      ));
    }

    // Add Product card if permission granted and feature enabled
    if (visibility[PermissionService.PRODUCT_PERMISSION] == true &&
        shopFeatures.contains('product')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.inventory,
        title: 'Add Product',
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProduct()),
          );
        },
        showcaseKey: _addProductKey,
        showcaseDescription: 'Add a new product to your inventory',
      ));
    }

    // Add Dashboard card if permission granted and feature enabled
    if (visibility[PermissionService.DASHBOARD_PERMISSION] == true &&
        shopFeatures.contains('dashboard')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.analytics,
        title: 'Dashboard',
        color: Colors.red,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        },
        showcaseKey: _dashboardKey,
        showcaseDescription: 'View your business dashboard and analytics',
      ));
    }

    // Add Reports card if permission granted and feature enabled
    if (visibility[PermissionService.REPORTS_PERMISSION] == true &&
        shopFeatures.contains('reports')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.assessment,
        title: 'Reports',
        color: Colors.teal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Reports()),
          );
        },
        showcaseKey: _reportsKey,
        showcaseDescription: 'View detailed business reports',
      ));
    }

    return cards;
  }

  // Get all quick action cards (for admin/owner with full access) filtered by shop features
  List<Widget> _getAllQuickActionCards(
      WidgetRef ref, List<String> shopFeatures) {
    List<Widget> cards = [];

    // Add Sale card if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('sale')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.shopping_cart,
        title: 'New Sale',
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddSalesScreen(customerModel: null)),
          );
        },
        showcaseKey: _addSaleKey,
        showcaseDescription: 'Create a new sale transaction here',
      ));
    }

    // Add Purchase card if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('purchase')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.shopping_bag,
        title: 'New Purchase',
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddAndUpdatePurchaseScreen(supplierModel: null)),
          );
        },
        showcaseKey: _addPurchaseKey,
        showcaseDescription: 'Create a new purchase transaction here',
      ));
    }

    // Add Customer/Supplier card if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('parties')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.people,
        title: 'Add Customer/Supplier',
        color: Colors.orange,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddParty()),
          );
          if (result != null) {
            refreshAllProviders(ref: ref);
          }
        },
        showcaseKey: _addCustomerKey,
        showcaseDescription: 'Add new customer or supplier here',
      ));
    }

    // Add Product card if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('product')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.inventory,
        title: 'Add Product',
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProduct()),
          );
        },
        showcaseKey: _addProductKey,
        showcaseDescription: 'Add a new product to your inventory',
      ));
    }

    // Add Dashboard card if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('dashboard')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.analytics,
        title: 'Dashboard',
        color: Colors.red,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        },
        showcaseKey: _dashboardKey,
        showcaseDescription: 'View your business dashboard and analytics',
      ));
    }

    // Add Reports card if feature enabled
    if (shopFeatures.isEmpty || shopFeatures.contains('reports')) {
      cards.add(_buildQuickActionCard(
        icon: Icons.assessment,
        title: 'Reports',
        color: Colors.teal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Reports()),
          );
        },
        showcaseKey: _reportsKey,
        showcaseDescription: 'View detailed business reports',
      ));
    }

    return cards;
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    GlobalKey? showcaseKey,
    String? showcaseDescription,
  }) {
    Widget cardWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: kTitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Wrap with Showcase if key provided
    if (showcaseKey != null && showcaseDescription != null) {
      return Showcase(
        key: showcaseKey,
        description: showcaseDescription,
        child: cardWidget,
      );
    }
    return cardWidget;
  }
}

String getDayLeftInExpiring(
    {required String? expireDate, required bool shortMSG}) {
  if (expireDate == null) {
    return shortMSG ? 'N/A' : 'Subscribe Now';
  }

  final expiringDay = DateTime.parse(expireDate);
  return shortMSG
      ? '${expiringDay.difference(DateTime.now()).inDays}\nDays Left'
      : '${expiringDay.difference(DateTime.now()).inDays} Days Left';
}
