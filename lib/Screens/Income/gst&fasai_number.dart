import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class GSTIfscScreen extends StatefulWidget {
  @override
  _GSTIfscScreenState createState() => _GSTIfscScreenState();
}

class _GSTIfscScreenState extends State<GSTIfscScreen>
    with SingleTickerProviderStateMixin {

  // Controllers
  final TextEditingController gstController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController userController = TextEditingController();

  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    loadSavedData();

    // Animation Setup
    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0.8, end: 1.1)
        .animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    animationController.dispose();
    gstController.dispose();
    ifscController.dispose();
    userController.dispose();
    super.dispose();
  }

  // Load from Local Storage
  Future<void> loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gstController.text = prefs.getString("gst") ?? "";
    ifscController.text = prefs.getString("ifsc") ?? "";
    userController.text = prefs.getString("user") ?? "";
    setState(() {});
  }

  // Save to Local Storage
  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("gst", gstController.text);
    await prefs.setString("ifsc", ifscController.text);
    await prefs.setString("user", userController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved Successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ScaleTransition(
                scale: animation,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(Icons.verified, color: Colors.white, size: 55),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "GST & IFSC Form",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              buildTextField("User Name", Icons.person, userController),
              const SizedBox(height: 15),

              buildTextField("GST Number", Icons.numbers, gstController),
              const SizedBox(height: 15),

              buildTextField("IFSC Code", Icons.account_balance, ifscController),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "SAVE",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Input Widget
  Widget buildTextField(String label, IconData icon, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }
}
