import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_pos/Screens/Report/Screens/due_report_screen.dart';
import 'package:mobile_pos/Screens/Report/Screens/expense_report.dart';
import 'package:mobile_pos/Screens/Report/Screens/expire_report.dart';
import 'package:mobile_pos/Screens/Report/Screens/purchase_report.dart';
import 'package:mobile_pos/Screens/Report/Screens/sales_report_screen.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../services/permission_service.dart';
import '../Loss_Profit/loss_profit_screen.dart';
import '../stock_list/stock_list_main.dart';
import 'Screens/income_report.dart';
import 'Screens/purchase_return_report.dart';
import 'Screens/sales_return_report_screen.dart';

class Reports extends StatefulWidget {
  const Reports({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ReportsState createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          title: Text(
            lang.S.of(context).reports,
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.0,
        ),
        body: FutureBuilder<List<Widget>>(
          future: _buildReportCards(context),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final reportCards = snapshot.data!;
            if (reportCards.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No reports available. Contact admin for access.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            
            return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                  children: reportCards,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build report cards based on user permissions
  Future<List<Widget>> _buildReportCards(BuildContext context) async {
    final permissionService = PermissionService();
    final role = await permissionService.getUserRole();
    final visibility = await permissionService.getVisibilityPermissions();
    
    List<Widget> cards = [];
    
    // If role is not 'staff', show all reports
    if (role != 'staff') {
      return _getAllReportCards(context);
    }
    
    // If no visibility data for staff, show all reports
    if (visibility == null) {
      return _getAllReportCards(context);
    }
    
    // Sales Report - show ONLY if salePermission or salesListPermission is true
    if (visibility[PermissionService.SALE_PERMISSION] == true || 
        visibility[PermissionService.SALES_LIST_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          const SalesReportScreen().launch(context);
        },
        iconPath: 'assets/salesReport.svg',
        title: lang.S.of(context).salesReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Purchase Report - show if purchasePermission or purchaseListPermission is true
    if (visibility[PermissionService.PURCHASE_PERMISSION] == true || 
        visibility[PermissionService.PURCHASE_LIST_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          const PurchaseReportScreen().launch(context);
        },
        iconPath: 'assets/purchaseReport.svg',
        title: lang.S.of(context).purchaseReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Due Report - show if dueListPermission is true
    if (visibility[PermissionService.DUE_LIST_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          const DueReportScreen().launch(context);
        },
        iconPath: 'assets/duereport.svg',
        title: lang.S.of(context).dueReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Stock Report - show if stockPermission is true
    if (visibility[PermissionService.STOCK_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StockList(isFromReport: true),
            ),
          );
        },
        iconPath: 'assets/stock.svg',
        title: lang.S.of(context).stockReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Expired List - show if stockPermission or productPermission is true
    if (visibility[PermissionService.STOCK_PERMISSION] == true || 
        visibility[PermissionService.PRODUCT_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpiredList()));
        },
        iconPath: 'assets/expenseReport.svg',
        title: lang.S.of(context).expiredList,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Loss/Profit Report - show if lossProfitPermission is true
    if (visibility[PermissionService.LOSS_PROFIT_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LossProfitScreen()));
        },
        iconPath: 'assets/lossprofit.svg',
        title: lang.S.of(context).lossProfitReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Income Report - show if addIncomePermission is true
    if (visibility[PermissionService.ADD_INCOME_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const IncomeReport()));
        },
        iconPath: 'assets/incomeReport.svg',
        title: lang.S.of(context).incomeReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Expense Report - show if addExpensePermission is true
    if (visibility[PermissionService.ADD_EXPENSE_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseReport()));
        },
        iconPath: 'assets/expenseReport.svg',
        title: lang.S.of(context).expenseReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    
    // Sales Return Report - DON'T show for staff (only admin/owner can see)
    // Staff ko sales return report nahi dikhega
    // Commented out - only admin/owner will see this in _getAllReportCards()
    
    /* 
    if (visibility[PermissionService.SALE_PERMISSION] == true || 
        visibility[PermissionService.SALES_LIST_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          const SalesReturnReportScreen().launch(context);
        },
        iconPath: 'assets/salesReport.svg',
        title: lang.S.of(context).salesReturnReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    */
    
    // Purchase Return Report - DON'T show for staff (only admin/owner can see)
    // Staff ko purchase return report nahi dikhega
    // Commented out - only admin/owner will see this in _getAllReportCards()
    
    /* 
    if (visibility[PermissionService.PURCHASE_PERMISSION] == true || 
        visibility[PermissionService.PURCHASE_LIST_PERMISSION] == true) {
      cards.add(ReportCard(
        pressed: () {
          const PurchaseReturnReportScreen().launch(context);
        },
        iconPath: 'assets/purchaseReport.svg',
        title: lang.S.of(context).purchaseReturnReport,
      ));
      cards.add(const SizedBox(height: 16));
    }
    */
    
    return cards;
  }
  
  // Get all report cards (for admin/owner with full access)
  List<Widget> _getAllReportCards(BuildContext context) {
    return [
                ReportCard(
                    pressed: () {
                      const SalesReportScreen().launch(context);
                    },
                    iconPath: 'assets/salesReport.svg',
        title: lang.S.of(context).salesReport,
      ),
                const SizedBox(height: 16),
                ReportCard(
                    pressed: () {
                      const PurchaseReportScreen().launch(context);
                    },
                    iconPath: 'assets/purchaseReport.svg',
        title: lang.S.of(context).purchaseReport,
      ),
                const SizedBox(height: 16),
                ReportCard(
                    pressed: () {
                      const DueReportScreen().launch(context);
                    },
                    iconPath: 'assets/duereport.svg',
        title: lang.S.of(context).dueReport,
      ),
                const SizedBox(height: 16),
                ReportCard(
                    pressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
              builder: (context) => const StockList(isFromReport: true),
            ),
          );
                    },
                    iconPath: 'assets/stock.svg',
        title: lang.S.of(context).stockReport,
      ),
                const SizedBox(height: 16),
                ReportCard(
                    pressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpiredList()));
                    },
                    iconPath: 'assets/expenseReport.svg',
        title: lang.S.of(context).expiredList,
      ),
                const SizedBox(height: 16),
                ReportCard(
                    pressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LossProfitScreen()));
                    },
                    iconPath: 'assets/lossprofit.svg',
        title: lang.S.of(context).lossProfitReport,
                ),
      const SizedBox(height: 16),
                ReportCard(
                  pressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const IncomeReport()));
                  },
                  iconPath: 'assets/incomeReport.svg',
                  title: lang.S.of(context).incomeReport,
                ),
                const SizedBox(height: 16),
                ReportCard(
                  pressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseReport()));
                  },
                  iconPath: 'assets/expenseReport.svg',
                  title: lang.S.of(context).expenseReport,
                ),
                const SizedBox(height: 16),
                ReportCard(
                  pressed: () {
                    const SalesReturnReportScreen().launch(context);
                  },
                  iconPath: 'assets/salesReport.svg',
                  title: lang.S.of(context).salesReturnReport,
                ),
                const SizedBox(height: 16),
                ReportCard(
                  pressed: () {
                    const PurchaseReturnReportScreen().launch(context);
                  },
                  iconPath: 'assets/purchaseReport.svg',
                  title: lang.S.of(context).purchaseReturnReport,
                ),
                const SizedBox(height: 16),
    ];
  }
}

// ignore: must_be_immutable
class ReportCard extends StatelessWidget {
  ReportCard({
    Key? key,
    required this.pressed,
    required this.iconPath,
    required this.title,
  }) : super(key: key);

  // ignore: prefer_typing_uninitialized_variables
  var pressed;
  String iconPath, title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pressed,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: kWhite, boxShadow: [BoxShadow(color: const Color(0xff473232).withOpacity(0.05), blurRadius: 8, spreadRadius: -1, offset: const Offset(0, 3)), BoxShadow(color: const Color(0xff0C1A4B).withOpacity(0.24), blurRadius: 1)]),
        child: ListTile(
          horizontalTitleGap: 16,
          visualDensity: const VisualDensity(horizontal: -4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: SvgPicture.asset(
            iconPath,
            height: 38,
            width: 38,
          ),
          title: Text(
            title,
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: kMainColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}
