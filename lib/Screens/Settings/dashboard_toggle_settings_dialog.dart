import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Provider/add_to_cart.dart';
import '../../constant.dart';

class DashboardToggleSettingsDialog extends ConsumerStatefulWidget {
  const DashboardToggleSettingsDialog({super.key});

  @override
  ConsumerState<DashboardToggleSettingsDialog> createState() =>
      _DashboardToggleSettingsDialogState();
}

class _DashboardToggleSettingsDialogState
    extends ConsumerState<DashboardToggleSettingsDialog> {
  bool _isToggleEnabled = false;
  bool _restrictZeroStockTransactions = false;
  bool _roundOffEnabled = false;
  bool _billSummaryEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadToggleSetting();
  }

  Future<void> _loadToggleSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isToggleEnabled =
          prefs.getBool('dashboard_payment_toggle_enabled') ?? false;
      _restrictZeroStockTransactions =
          prefs.getBool(kZeroStockRestrictionKey) ?? false;
      _roundOffEnabled =
          prefs.getBool(kSalesRoundOffToggleKey) ?? false;
      _billSummaryEnabled =
          prefs.getBool(kSalesBillSummaryToggleKey) ?? true;
    });
  }

  Future<void> _saveToggleSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_payment_toggle_enabled', value);
    if (!mounted) return;
    setState(() {
      _isToggleEnabled = value;
    });
  }

  Future<void> _saveZeroStockSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kZeroStockRestrictionKey, value);
    if (!mounted) return;
    setState(() {
      _restrictZeroStockTransactions = value;
    });
  }

  Future<void> _saveRoundOffSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kSalesRoundOffToggleKey, value);
    if (!mounted) return;
    setState(() {
      _roundOffEnabled = value;
    });
    try {
      ref.read(cartNotifier).updateRoundOffEnabled(value);
    } catch (_) {
      // Cart notifier might not be initialized in some contexts.
    }
  }

  Future<void> _saveBillSummarySetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kSalesBillSummaryToggleKey, value);
    if (!mounted) return;
    setState(() {
      _billSummaryEnabled = value;
    });
  }

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;

  // Responsive text
  final titleFontSize = isMobile ? 16.0 : 18.0;
  final labelFontSize = isMobile ? 14.0 : 16.0;
  final subtitleFontSize = isMobile ? 12.0 : 13.0;
  final sectionTitleFontSize = isMobile ? 12.0 : 14.0;

  final verticalSpacing = isMobile ? 12.0 : 16.0;
  final smallSpacing = isMobile ? 6.0 : 8.0;
  final largeSpacing = isMobile ? 16.0 : 24.0;

  return Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.3,
        title: Text(
          'Dashboard Toggle Settings',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: kTitleColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: kMainColor),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------
            // PAYMENT METHOD SECTION
            // ----------------------
            Text(
              'Enable payment method toggles on dashboard',
              style: TextStyle(
                fontSize: sectionTitleFontSize,
                color: kGreyTextColor,
              ),
            ),

            SizedBox(height: verticalSpacing),

            _buildToggleItem(
              label: 'Show Payment Method Toggles',
              value: _isToggleEnabled,
              onChanged: _saveToggleSetting,
              description: _isToggleEnabled
                  ? 'Payment method toggles will be visible on dashboard'
                  : 'Payment method toggles will be hidden on dashboard',
              labelFontSize: labelFontSize,
              subtitleFontSize: subtitleFontSize,
              smallSpacing: smallSpacing,
            ),

            SizedBox(height: largeSpacing),

            // ----------------------
            // SALES PREFERENCES
            // ----------------------
            Text(
              'Sales Preferences',
              style: TextStyle(
                fontSize: sectionTitleFontSize,
                color: kGreyTextColor,
              ),
            ),

            SizedBox(height: verticalSpacing),

            _buildToggleItem(
              label: 'Enable Sale Amount Round Off',
              value: _roundOffEnabled,
              onChanged: _saveRoundOffSetting,
              description: _roundOffEnabled
                  ? 'Sale totals will be rounded according to your selected method.'
                  : 'Sale totals will use the exact calculated amount without round off.',
              labelFontSize: labelFontSize,
              subtitleFontSize: subtitleFontSize,
              smallSpacing: smallSpacing,
            ),

            _buildToggleItem(
              label: 'Show Bill Summary Screen',
              value: _billSummaryEnabled,
              onChanged: _saveBillSummarySetting,
              description: _billSummaryEnabled
                  ? 'A bill summary will appear before final invoice generation.'
                  : 'Sales will skip the bill summary and go straight to invoice.',
              labelFontSize: labelFontSize,
              subtitleFontSize: subtitleFontSize,
              smallSpacing: smallSpacing,
            ),

            SizedBox(height: largeSpacing),

            // ----------------------
            // ZERO STOCK CONTROL
            // ----------------------
            Text(
              'Control product sale/purchase when stock is zero or marked out-of-stock',
              style: TextStyle(
                fontSize: sectionTitleFontSize,
                color: kGreyTextColor,
              ),
            ),

            SizedBox(height: verticalSpacing),

            _buildToggleItem(
              label: 'Prevent Out-of-Stock Transactions',
              value: _restrictZeroStockTransactions,
              onChanged: _saveZeroStockSetting,
              description: _restrictZeroStockTransactions
                  ? 'Out-of-stock items cannot be added to Sale or Purchase carts.'
                  : 'Out-of-stock items can still be sold or purchased.',
              labelFontSize: labelFontSize,
              subtitleFontSize: subtitleFontSize,
              smallSpacing: smallSpacing,
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildToggleItem({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required String description,
    required double labelFontSize,
    required double subtitleFontSize,
    required double smallSpacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  color: kTitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: kMainColor,
              onChanged: onChanged,
            ),
          ],
        ),
        SizedBox(height: smallSpacing),
        Text(
          description,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: kGreyTextColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        Divider(color: Colors.black,),
      ],
    );
  }
}
