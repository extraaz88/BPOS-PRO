import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';



class GSTIfscScreen extends StatefulWidget {
  @override
  _GSTIfscScreenState createState() => _GSTIfscScreenState();
}

class _GSTIfscScreenState extends State<GSTIfscScreen>
    with TickerProviderStateMixin {

  final TextEditingController gstController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();

  late AnimationController logoController;
  late AnimationController fadeController;
  late AnimationController buttonSlideController;
  late AnimationController buttonPressController;

  late Animation<double> logoAnimation;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  // For SAVE button press effect
  late Animation<double> buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    loadSavedData();

    // LOGO ANIMATION
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    logoAnimation = Tween<double>(begin: 0.9, end: 1.13)
        .animate(CurvedAnimation(parent: logoController, curve: Curves.easeInOut));

    // FIELDS FADE-IN
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    fadeController.forward();

    // BUTTON SLIDE-IN
    buttonSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: buttonSlideController, curve: Curves.easeOut));
    buttonSlideController.forward();

    // BUTTON PRESS ANIMATION
    buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );

    buttonScaleAnimation =
        Tween<double>(begin: 1.0, end: 0.9).animate(buttonPressController);
  }

  @override
  void dispose() {
    logoController.dispose();
    fadeController.dispose();
    buttonSlideController.dispose();
    buttonPressController.dispose();
    gstController.dispose();
    ifscController.dispose();
    super.dispose();
  }

  // Load Local Storage
  Future<void> loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gstController.text = prefs.getString("gst") ?? "";
    ifscController.text = prefs.getString("ifsc") ?? "";
    setState(() {});
  }

  // Save Data
  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("gst", gstController.text);
    await prefs.setString("ifsc", ifscController.text);

    // 🎉 Flutter Toast
    Fluttertoast.showToast(
      msg: "Saved Successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [

              // ANIMATED LOGO
              ScaleTransition(
                scale: logoAnimation,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.lightBlue.shade200,
                        Colors.blue.shade400,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "images/BharatBill.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              FadeTransition(
                opacity: fadeAnimation,
                child: const Text(
                  "GST & IFSC Details",
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              FadeTransition(
                opacity: fadeAnimation,
                child: buildField("GST Number", Icons.numbers, gstController),
              ),
              const SizedBox(height: 15),

              FadeTransition(
                opacity: fadeAnimation,
                child: buildField("IFSC Code", Icons.account_balance, ifscController),
              ),

              const SizedBox(height: 25),

              // SAVE BUTTON + PRESS ANIMATION
              SlideTransition(
                position: slideAnimation,
                child: GestureDetector(
                  onTapDown: (_) => buttonPressController.forward(),
                  onTapUp: (_) {
                    buttonPressController.reverse();
                    saveData(); // SAVE data
                  },
                  child: ScaleTransition(
                    scale: buttonScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 45, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 10,
                            offset: const Offset(2, 4),
                          )
                        ],
                      ),
                      child: const Text(
                        "SAVE",
                        style: TextStyle(
                            fontSize: 18, color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Field Widget
  Widget buildField(String label, IconData icon, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }
}
