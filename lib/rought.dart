import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String baseUrl = "https://bharatbill.live/api/v1";
}

BuildContext? globalContext;
void showToast(String msg) {
  ScaffoldMessenger.of(globalContext!).showSnackBar(SnackBar(content: Text(msg)));
}

class AuthRepo {
  // ---------------- SEND OTP API ----------------
  Future<bool> sendOtp({
    required String phone,
    required String email,
    required BuildContext context,
  }) async {
    globalContext = context;
    try {
      EasyLoading.show(status: "Sending OTP...");
      final url = Uri.parse("${ApiConfig.baseUrl}/whatsapp/send-otp");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "email": email}),
      );

      EasyLoading.dismiss();
      print("SEND OTP RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        showToast("OTP sent to WhatsApp");
        return true;
      } else {
        showToast("Failed to send OTP");
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      showToast("Error: $e");
      return false;
    }
  }

  // ---------------- VERIFY OTP + SIGNUP ----------------
  Future<bool> verifyAndRegister({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String otp,
    required BuildContext context,
  }) async {
    globalContext = context;

    try {
      EasyLoading.show(status: "Verifying OTP...");

      // -------- VERIFY OTP FIRST ---------
      final url = Uri.parse("${ApiConfig.baseUrl}/whatsapp/verify-otp");

      final verifyResponse = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phone,
          "email": email,
          "otp": otp,
        }),
      );

      print("VERIFY OTP RESPONSE: ${verifyResponse.body}");

      if (verifyResponse.statusCode != 200) {
        EasyLoading.dismiss();
        showToast("OTP invalid!");
        return false;
      }

      // Second Step → SIGN UP user
      final signUpUrl = Uri.parse("${ApiConfig.baseUrl}/sign-up");

      final registerResponse = await http.post(
        signUpUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
      );

      EasyLoading.dismiss();
      print("SIGNUP RESPONSE: ${registerResponse.body}");

      if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
        showToast("Registration Successful!");

        // Save Login Token
        final jsonData = jsonDecode(verifyResponse.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", jsonData["token"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );

        return true;
      } else {
        showToast("Registration Failed!");
        return false;
      }

    } catch (e) {
      EasyLoading.dismiss();
      showToast("Error: $e");
      return false;
    }
  }
}

// --------------------------------------------------
//                   SIGN UP SCREEN
// --------------------------------------------------

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final phone = TextEditingController();

  @override
  Widget build(BuildContext context) {
    globalContext = context;

    return Scaffold(
      appBar: AppBar(title: Text("Register Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: "Password")),
            TextField(controller: phone, decoration: InputDecoration(labelText: "Phone Number (+91...)")),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                bool sent = await AuthRepo().sendOtp(
                  phone: phone.text.trim(),
                  email: email.text.trim(),
                  context: context,
                );

                if (sent) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerifyOtpScreen(
                        name: name.text,
                        email: email.text,
                        password: pass.text,
                        phone: phone.text,
                      ),
                    ),
                  );
                }
              },
              child: Text("Verify Number"),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
//                OTP VERIFY SCREEN
// --------------------------------------------------

class VerifyOtpScreen extends StatelessWidget {
  final String name, email, password, phone;
  final otpController = TextEditingController();

  VerifyOtpScreen({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    globalContext = context;

    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Enter 6 Digit OTP", style: TextStyle(fontSize: 18)),
            TextField(
              controller: otpController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "OTP"),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await AuthRepo().verifyAndRegister(
                  name: name,
                  email: email,
                  password: password,
                  phone: phone,
                  otp: otpController.text.trim(),
                  context: context,
                );
              },
              child: Text("Verify & Register"),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
//                   HOME SCREEN
// --------------------------------------------------

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HOME")),
      body: Center(
        child: Text("Welcome to Home Screen 🎉", style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
