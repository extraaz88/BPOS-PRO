import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Authentication/register_screen.dart';
import 'package:mobile_pos/Screens/Authentication/phone_otp_verification_screen.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/services/firebase_phone_auth_service.dart';

import '../../constant.dart';
import 'forgot_password.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key, required this.isEmailLogin}) : super(key: key);

  final bool isEmailLogin;

  @override
  // ignore: library_private_types_in_public_api
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool showPassword = true;
  late String phoneNumber, password;
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> _loginWithFirebase() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Send OTP to phone number
      String? result = await FirebasePhoneAuthService.sendOTPToPhone(phoneNumber);
      
      // Close loading dialog
      Navigator.pop(context);

      if (result != null && result.contains('OTP sent')) {
        // Navigate to phone OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneOTPVerificationScreen(
              phoneNumber: '+91$phoneNumber',
              isLogin: true,
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        body: Consumer(builder: (context, ref, child) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('images/logoandname.png'),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Form(
                      key: globalKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          TextFormField(
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Phone Number',
                              hintText: 'Enter your phone number',
                              prefixText: '+91 ',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number cannot be empty';
                              } else if (value.length != 10) {
                                return 'Please enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              phoneNumber = value!;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            keyboardType: TextInputType.text,
                            obscureText: showPassword,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: lang.S.of(context).password,
                              hintText: lang.S.of(context).pleaseEnterAPassword,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                                icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                //return 'Password can\'t be empty';
                                return lang.S.of(context).passwordCannotBeEmpty;
                              } else if (value.length < 4) {
                                //return 'Please enter a bigger password';
                                return lang.S.of(context).pleaseEnterABiggerPassword;
                              }
                              return null;
                            },
                            onSaved: (value) {
                              // loginProvider.password = value!;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.isEmailLogin,
                    child: Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPassword()));
                            // const ForgotPassword().launch(context);
                          },
                          child: Text(
                            lang.S.of(context).forgotPassword,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: kGreyTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (validateAndSave()) {
                        await _loginWithFirebase();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      lang.S.of(context).logIn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.isEmailLogin,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.S.of(context).noAcc,
                          style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigator.pushNamed(context, '/signup');
                            // const RegisterScreen().launch(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          child: Text(
                            lang.S.of(context).register,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: kMainColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
