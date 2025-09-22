import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile_pos/Screens/SplashScreen/on_board.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/model/business_info_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Repository/API/business_info_repo.dart';
import '../../currency.dart';
import '../Home/home.dart';
import '../language/language_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _backgroundController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _loadingFadeAnimation;
  late Animation<double> _backgroundGradientAnimation;

  void getPermission() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  int retryCount = 0;

  checkUserValidity() async {
    final bool isConnected = await InternetConnection().hasInternetAccess;
    if (isConnected) {
      nextPage();
    } else {
      if (retryCount < 3) {
        retryCount++;
        checkUserValidity();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("No Internet Connection"),
            content: const Text(
                "Please check your internet connection and try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  checkUserValidity();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    getPermission();
    CurrencyMethods().getCurrencyFromLocalDatabase();
    checkUserValidity();
    setLanguage();
  }

  void _initializeAnimations() {
    // Main fade controller for all elements
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Background gradient controller
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Logo animations with premium fade effects
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    // Text fade animation with delay
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
    ));

    // Loading fade animation
    _loadingFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeInOut),
    ));

    // Background animations
    _backgroundGradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // Start animations with premium timing
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> setLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode =
        prefs.getString('lang') ?? 'en'; // Default to English code
    setState(() {
      selectedLanguage = savedLanguageCode;
    });
    context.read<LanguageChangeProvider>().changeLocale(savedLanguageCode);
  }

  Future<void> nextPage() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(seconds: 3));
    if (prefs.getString('token') != null) {
      BusinessInformation? data;
      data = await BusinessRepository().checkBusinessData();
      if (data == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const OnBoard()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Home()));
      }
    } else {
      CurrencyMethods().removeCurrencyFromLocalDatabase();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const OnBoard()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    kMainColor
                        .withOpacity(0.05 * _backgroundGradientAnimation.value),
                    kMainColor
                        .withOpacity(0.1 * _backgroundGradientAnimation.value),
                  ],
                  stops: [
                    0.0,
                    0.5 * _backgroundGradientAnimation.value,
                    1.0,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Premium Logo Animation
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: Container(
                              height: 250,
                              width: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: kMainColor.withOpacity(
                                        0.1 * _logoFadeAnimation.value),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                                image: const DecorationImage(
                                  image: AssetImage(splashLogo),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    // Premium Text and Loading Animation
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // App Name with premium styling
                              FadeTransition(
                                opacity: _textFadeAnimation,
                                child: Text(
                                  appsName,
                                  textAlign: TextAlign.center,
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    color: kMainColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 32,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Powered by text
                              FadeTransition(
                                opacity: _textFadeAnimation,
                                child: Text(
                                  '${lang.S.of(context).poweredBy} $companyName',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Premium Loading Animation
                              FadeTransition(
                                opacity: _loadingFadeAnimation,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer ring
                                      SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            kMainColor.withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                      // Inner ring
                                      SizedBox(
                                        width: 35,
                                        height: 35,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            kMainColor,
                                          ),
                                        ),
                                      ),
                                      // Center dot
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: kMainColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}