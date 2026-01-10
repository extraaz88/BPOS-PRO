import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';
import 'package:mobile_pos/Screens/Home/home_screen.dart';
import 'package:mobile_pos/Screens/Home/components/bottom_nav.dart';
import 'package:mobile_pos/Screens/Report/reports.dart';
import 'package:mobile_pos/Screens/Settings/settings_screen.dart';
import 'package:mobile_pos/Screens/Calendar/calendar_screen.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:shared_preferences/shared_preferences.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isDeviceConnected = false;
  bool isAlertSet = false;
  bool isNoInternet = false;
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  set tabIndex(int v) {
    _tabIndex = v;
    setState(() {});
  }

  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _tabIndex);
  }

  // Build bottom navigation items based on permissions
  List<BottomNavigationBarItem> _buildBottomNavItems(
      bool hasDashboardPermission, bool hasCalendarFeature) {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: _buildNavIcon(Icons.home_outlined, Icons.home_rounded, 0),
        label: 'Home',
      ),
    ];

    if (hasDashboardPermission) {
      items.add(
        BottomNavigationBarItem(
          icon: _buildNavIcon(
              Icons.dashboard_outlined, Icons.dashboard_rounded, items.length),
          label: 'Dashboard',
        ),
      );
    }

    if (hasCalendarFeature) {
      items.add(
        BottomNavigationBarItem(
          icon: _buildNavIcon(Icons.calendar_month_outlined,
              Icons.calendar_month_rounded, items.length),
          label: 'Calendar',
        ),
      );
    }

    items.addAll([
      BottomNavigationBarItem(
        icon: _buildNavIcon(
            Icons.analytics_outlined, Icons.analytics_rounded, items.length),
        label: 'Reports',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(
            Icons.settings_outlined, Icons.settings_rounded, items.length),
        label: 'Settings',
      ),
    ]);

    return items;
  }

  // Build navigation icon with animation support
  Widget _buildNavIcon(IconData inactiveIcon, IconData activeIcon, int index) {
    final isSelected = _tabIndex == index;
    return Icon(
      isSelected ? activeIcon : inactiveIcon,
      size: isSelected ? 26 : 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              lang.S.of(context).areYouSure,
              //'Are you sure?'
            ),
            content: Text(
              lang.S.of(context).doYouWantToExitTheApp,
              //'Do you want to exit the app?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  lang.S.of(context).no,
                  //'No'
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  lang.S.of(context).yes,
                  //  'Yes'
                ),
              ),
            ],
          ),
        );
        return shouldPop ??
            false; // Allow default back button behavior if dialog is dismissed
      },
      child: Consumer(builder: (context, ref, __) {
        final profile = ref.watch(businessInfoProvider);
        ref.watch(getExpireDateProvider(ref));

        // Determine which tabs to show based on permissions
        // If role is not 'staff', show all tabs
        final userRole = profile.value?.user?.role ?? '';
        final hasDashboardPermission = userRole != 'staff'
            ? true
            : (profile.value?.user?.visibility?.dashboardPermission ?? true);

        return FutureBuilder<List<String>>(
          future: SharedPreferences.getInstance().then((prefs) => prefs.getStringList('shop_features') ?? []),
          builder: (context, snapshot) {
            final shopFeatures = snapshot.data ?? [];
            final hasCalendarFeature = shopFeatures.isEmpty || shopFeatures.contains('salon_service');

            // Build the list of screens
            List<Widget> screens = [const HomeScreen()];
            if (hasDashboardPermission) {
              screens.add(const DashboardScreen());
            }
            if (hasCalendarFeature) {
              screens.add(const CalendarScreen());
            }
            screens.addAll([const Reports(), const SettingScreen()]);

            return GlobalPopup(
              child: Scaffold(
                body: PageView(
                  controller: pageController,
                  onPageChanged: (v) {
                    tabIndex = v;
                  },
                  children: screens,
                ),
                bottomNavigationBar: CustomBottomNav(
                  currentIndex: _tabIndex,
                  onTap: (index) {
                    setState(() {
                      _tabIndex = index;
                      pageController.jumpToPage(index);
                    });
                  },
                  items: _buildBottomNavItems(hasDashboardPermission, hasCalendarFeature),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
