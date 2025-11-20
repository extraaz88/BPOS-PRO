import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_pos/Screens/Authentication/forgot_password.dart';
import 'package:mobile_pos/Screens/Authentication/login_form.dart';
import 'package:mobile_pos/Screens/Authentication/register_screen.dart';
import 'package:mobile_pos/Screens/Authentication/sign_in.dart';
import 'package:mobile_pos/Screens/Customers/customer_list.dart';
import 'package:mobile_pos/Screens/Expense/expense_list.dart';
import 'package:mobile_pos/Screens/Home/home.dart';
import 'package:mobile_pos/Screens/Products/add_product.dart';
import 'package:mobile_pos/Screens/Products/product_list_screen.dart';
import 'package:mobile_pos/Screens/Report/reports.dart';
import 'package:mobile_pos/Screens/Sales/add_discount.dart';
import 'package:mobile_pos/Screens/Sales/add_promo_code.dart';
import 'package:mobile_pos/Screens/Sales/sales_contact.dart';
import 'package:mobile_pos/Screens/SplashScreen/on_board.dart';
import 'package:mobile_pos/Screens/SplashScreen/splash_screen.dart';
import 'package:mobile_pos/Screens/vat_&_tax/tax_report.dart';
import 'package:provider/provider.dart' as pro;
import 'package:showcaseview/showcaseview.dart';
import 'firebase_options.dart';

import 'Screens/Due Calculation/due_list_screen.dart';
import 'Screens/Income/income_list.dart';
import 'Screens/Loss_Profit/loss_profit_screen.dart';
import 'Screens/Purchase List/purchase_list_screen.dart';
import 'Screens/Purchase/choose_supplier_screen.dart';
import 'Screens/Sales List/sales_list_screen.dart';
import 'Screens/custom_print/custom_print.dart';
import 'Screens/language/language_provider.dart';
import 'Screens/stock_list/stock_list_main.dart';
import 'Screens/Graphs/animated_sales_purchase_graph.dart';
import 'core/theme/theme.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for desktop platforms (Windows, Linux, macOS)
  // Note: If you're using sqflite on desktop, you need to add sqflite_common_ffi
  // to pubspec.yaml and uncomment the code below
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      // Uncomment these lines if you add sqflite_common_ffi to pubspec.yaml:
      // import 'package:sqflite_common_ffi/sqflite_ffi.dart';
      // databaseFactory = databaseFactoryFfi;
      print('⚠️ Running on desktop - ensure sqflite_common_ffi is configured if using database');
    } catch (e) {
      print('⚠️ Database initialization note: $e');
    }
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    FirebaseAuth.instance;
  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return pro.ChangeNotifierProvider<LanguageChangeProvider>(
      create: (context) => LanguageChangeProvider(),
      child: pro.Consumer<LanguageChangeProvider>(
        builder: (context, languageProvider, child) {
          return ShowCaseWidget(
            builder: (context) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: languageProvider.currentLocale,
                localizationsDelegates: const [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                title: 'BHARAT BILL',
                initialRoute: '/',
                builder: EasyLoading.init(),
                routes: {
                   '/': (context) => const SplashScreen(),
                  '/onBoard': (context) => const OnBoard(),
                  '/signIn': (context) => const SignInScreen(),
                  '/loginForm': (context) =>
                      const LoginForm(isEmailLogin: true),
                  '/signup': (context) => const RegisterScreen(),
                  '/forgotPassword': (context) => const ForgotPassword(),
                  '/home': (context) => const Home(),
                  '/AddProducts': (context) => const AddProduct(),
                  '/Products': (context) => const ProductList(),
                  '/salesCustomer': (context) => const SalesContact(),
                  '/addPromoCode': (context) => const AddPromoCode(),
                  '/customPrint': (context) => const CustomPrintScreen(),
                  '/addDiscount': (context) => const AddDiscount(),
                  '/Sales': (context) => const SalesContact(),
                  '/Parties': (context) => const CustomerList(),
                  '/Expense': (context) => const ExpenseList(),
                  '/Income': (context) => const IncomeList(),
                  '/tax': (context) => const TaxReport(),
                  '/Stock': (context) => const StockList(isFromReport: false),
                  '/Purchase': (context) => const PurchaseContacts(),
                  '/Reports': (context) => const Reports(),
                  '/Due List': (context) => const DueCalculationContactScreen(),
                  '/Sales List': (context) => const SalesListScreen(),
                  '/Purchase List': (context) => const PurchaseListScreen(),
                  '/Loss/Profit': (context) => const LossProfitScreen(),
                  '/AnimatedGraphs': (context) =>
                      const AnimatedSalesPurchaseGraph(),
                },
                theme: AcnooTheme.kLightTheme(context),
              );
            },
          );
        },
      ),
    );
  }
}
