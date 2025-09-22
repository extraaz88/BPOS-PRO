import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';
import 'package:mobile_pos/Screens/Profile%20Screen/profile_details.dart';
import 'package:nb_utils/nb_utils.dart';

// Import required screens for navigation
import '../Sales/add_sales.dart';
import '../Purchase/add_and_edit_purchase.dart';
import '../Customers/add_customer.dart';
import '../Products/add_product.dart';
import '../Report/reports.dart';

import '../../GlobalComponents/app_drawer.dart';
import '../../Provider/profile_provider.dart';
import '../../constant.dart';
import '../Customers/Provider/customer_provider.dart';
import 'Provider/banner_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController pageController = PageController(initialPage: 0);

  bool _isRefreshing = false;

  Future<void> refreshAllProviders({required WidgetRef ref}) async {
    if (_isRefreshing) return; // Prevent multiple refresh calls

    _isRefreshing = true;
    try {
      ref.refresh(summaryInfoProvider);
      ref.refresh(bannerProvider);
      ref.refresh(businessInfoProvider);
      ref.refresh(businessSettingProvider);
      ref.refresh(partiesProvider);
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

                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildQuickActionCard(
                          icon: Icons.shopping_cart,
                          title: 'New Sale',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AddSalesScreen(customerModel: null)),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.shopping_bag,
                          title: 'New Purchase',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AddAndUpdatePurchaseScreen(
                                          customerModel: null)),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.people,
                          title: 'Add Customer',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddParty()),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.inventory,
                          title: 'Add Product',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddProduct()),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.analytics,
                          title: 'Dashboard',
                          color: Colors.red,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DashboardScreen()),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.assessment,
                          title: 'Reports',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Reports()),
                            );
                          },
                        ),
                      ],
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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