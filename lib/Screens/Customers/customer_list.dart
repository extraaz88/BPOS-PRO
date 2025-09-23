import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/Customers/Provider/customer_provider.dart';
import 'package:mobile_pos/Screens/Customers/add_customer.dart';
import 'package:mobile_pos/Screens/Customers/customer_details.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/widgets/empty_widget/_empty_widget.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';
import '../../currency.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList>
    with SingleTickerProviderStateMixin {
  Color color = Colors.white;
  bool _isRefreshing = false; // Prevents multiple refresh calls
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _selectedIndex = widget.initialTab;
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    // ignore: unused_result
    ref.refresh(partiesProvider);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  List<dynamic> _filterCustomers(List<dynamic> allCustomers) {
    if (_selectedIndex == 0) {
      // Customer tab - show only Customer
      return allCustomers
          .where((customer) => customer.type == 'Customer')
          .toList();
    } else {
      // Supplier tab - show only Supplier
      return allCustomers
          .where((customer) => customer.type == 'Supplier')
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, __) {
        final providerData = ref.watch(partiesProvider);
        final businessInfo = ref.watch(businessInfoProvider);
        return businessInfo.when(data: (details) {
          return GlobalPopup(
            child: Scaffold(
              backgroundColor: kWhite,
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text(
                  lang.S.of(context).partyList,
                ),
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.black),
                elevation: 0.0,
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: _theme.colorScheme.primary,
                  labelColor: _theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(lang.S.of(context).customers),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business, size: 20),
                          const SizedBox(width: 8),
                          Text(lang.S.of(context).suppliers),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Customer Tab
                  RefreshIndicator(
                    onRefresh: () => refreshData(ref),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: providerData.when(data: (allCustomers) {
                        final customers = _filterCustomers(allCustomers);
                        return customers.isNotEmpty
                            ? ListView.builder(
                                itemCount: customers.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (_, index) {
                                  customers[index].type == 'Customer'
                                      ? color = const Color(0xFF56da87)
                                      : Colors.white;

                                  return ListTile(
                                    visualDensity:
                                        const VisualDensity(vertical: -2),
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () {
                                      CustomerDetails(
                                        party: customers[index],
                                      ).launch(context);
                                    },
                                    leading: customers[index].image != null
                                        ? Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: DAppColors.kBorder,
                                                  width: 0.3),
                                              image: DecorationImage(
                                                  image: NetworkImage(
                                                    '${APIConfig.domain}${customers[index].image ?? ''}',
                                                  ),
                                                  fit: BoxFit.cover),
                                            ),
                                          )
                                        : CircleAvatarWidget(
                                            name: customers[index].name),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            customers[index].name ?? '',
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                            style: _theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.black,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$currency${customers[index].due}',
                                          style: _theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            customers[index].type ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: color,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          customers[index].due != null &&
                                                  customers[index].due != 0
                                              ? lang.S.of(context).due
                                              : 'No Due',
                                          style: _theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: customers[index].due !=
                                                        null &&
                                                    customers[index].due != 0
                                                ? const Color(0xFFff5f00)
                                                : DAppColors.kSecondary,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      IconlyLight.arrow_right_2,
                                      size: 18,
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: EmptyWidget(
                                  message: TextSpan(text: "No Customers Found"),
                                ),
                              );
                      }, error: (e, stack) {
                        return Text(e.toString());
                      }, loading: () {
                        return const Center(child: CircularProgressIndicator());
                      }),
                    ),
                  ),
                  // Supplier Tab
                  RefreshIndicator(
                    onRefresh: () => refreshData(ref),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: providerData.when(data: (allCustomers) {
                        final suppliers = _filterCustomers(allCustomers);
                        return suppliers.isNotEmpty
                            ? ListView.builder(
                                itemCount: suppliers.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (_, index) {
                                  suppliers[index].type == 'Supplier'
                                      ? color = const Color(0xFFA569BD)
                                      : Colors.white;

                                  return ListTile(
                                    visualDensity:
                                        const VisualDensity(vertical: -2),
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () {
                                      CustomerDetails(
                                        party: suppliers[index],
                                      ).launch(context);
                                    },
                                    leading: suppliers[index].image != null
                                        ? Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: DAppColors.kBorder,
                                                  width: 0.3),
                                              image: DecorationImage(
                                                  image: NetworkImage(
                                                    '${APIConfig.domain}${suppliers[index].image ?? ''}',
                                                  ),
                                                  fit: BoxFit.cover),
                                            ),
                                          )
                                        : CircleAvatarWidget(
                                            name: suppliers[index].name),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            suppliers[index].name ?? '',
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                            style: _theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.black,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$currency${suppliers[index].due}',
                                          style: _theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            suppliers[index].type ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: color,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          suppliers[index].due != null &&
                                                  suppliers[index].due != 0
                                              ? lang.S.of(context).due
                                              : 'No Due',
                                          style: _theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: suppliers[index].due !=
                                                        null &&
                                                    suppliers[index].due != 0
                                                ? const Color(0xFFff5f00)
                                                : DAppColors.kSecondary,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      IconlyLight.arrow_right_2,
                                      size: 18,
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: EmptyWidget(
                                  message: TextSpan(text: "No Suppliers Found"),
                                ),
                              );
                      }, error: (e, stack) {
                        return Text(e.toString());
                      }, loading: () {
                        return const Center(child: CircularProgressIndicator());
                      }),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ElevatedButton.icon(
                  style: OutlinedButton.styleFrom(
                    maximumSize: const Size(double.infinity, 48),
                    minimumSize: const Size(double.infinity, 48),
                    disabledBackgroundColor:
                        _theme.colorScheme.primary.withValues(alpha: 0.15),
                    disabledForegroundColor:
                        const Color(0xff567DF4).withOpacity(0.05),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddParty()));

                    // If a customer/supplier was added, refresh the current tab
                    if (result != null) {
                      // ignore: unused_result
                      ref.refresh(partiesProvider);
                    }
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    "Add Customer/Supplier",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _theme.textTheme.bodyMedium?.copyWith(
                      color: _theme.colorScheme.primaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }, error: (e, stack) {
          return Text(e.toString());
        }, loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
      },
    );
  }
}