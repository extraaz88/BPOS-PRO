// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Authentication/Phone%20Auth/phone_auth_screen.dart';
import 'package:mobile_pos/Screens/Authentication/phone_otp_verification_screen.dart';
import 'package:mobile_pos/Screens/Authentication/otp_verification_screen.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../services/firebase_phone_auth_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../constant.dart';
import 'login_form.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool showPass1 = true;
  bool showPass2 = true;
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  bool passwordShow = false;
  String? givenPassword;
  String? givenPassword2;

  late String email;
  late String phoneNumber;
  late String password;
  late String passwordConfirmation;
  String verificationMethod = 'both'; // 'email', 'phone', or 'both'

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate() && givenPassword == givenPassword2) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future<void> _registerWithFirebase() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      String? emailResult;
      String? phoneResult;

      // Send OTP based on selected verification method
      if (verificationMethod == 'email' || verificationMethod == 'both') {
        emailResult = await FirebaseAuthService.sendOTPToEmail(email);
      }
      
      if (verificationMethod == 'phone' || verificationMethod == 'both') {
        phoneResult = await FirebasePhoneAuthService.sendOTPToPhone(phoneNumber);
      }
      
      // Close loading dialog
      Navigator.pop(context);

      // Handle results based on verification method
      if (verificationMethod == 'email') {
        if (emailResult != null && emailResult.contains('OTP sent')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                email: email,
                password: password,
              ),
            ),
          );
        } else {
          _showErrorMessage('Email OTP failed: ${emailResult ?? 'Unknown error'}');
        }
      } else if (verificationMethod == 'phone') {
        if (phoneResult != null && phoneResult.contains('OTP sent')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhoneOTPVerificationScreen(
                phoneNumber: '+91$phoneNumber',
                isLogin: false,
              ),
            ),
          );
        } else {
          _showErrorMessage('Phone OTP failed: ${phoneResult ?? 'Unknown error'}');
        }
      } else if (verificationMethod == 'both') {
        if ((emailResult != null && emailResult.contains('OTP sent')) && 
            (phoneResult != null && phoneResult.contains('OTP sent'))) {
          _showVerificationMethodDialog();
        } else {
          String errorMessage = 'Failed to send OTP';
          if (emailResult != null && !emailResult.contains('OTP sent')) {
            errorMessage = 'Email OTP failed: $emailResult';
          } else if (phoneResult != null && !phoneResult.contains('OTP sent')) {
            errorMessage = 'Phone OTP failed: $phoneResult';
          }
          _showErrorMessage(errorMessage);
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showErrorMessage('Registration failed: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showVerificationMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Verification Method'),
        content: const Text('We have sent OTP to both your email and phone. Choose which method you want to use for verification:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to email OTP verification
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPVerificationScreen(
                    email: email,
                    password: password,
                  ),
                ),
              );
            },
            child: const Text('Verify via Email'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to phone OTP verification
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhoneOTPVerificationScreen(
                    phoneNumber: '+91$phoneNumber',
                    isLogin: false,
                  ),
                ),
              );
            },
            child: const Text('Verify via Phone'),
          ),
        ],
      ),
    );
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
                          // Email Field
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Email Address',
                              hintText: 'Enter your email address',
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email cannot be empty';
                              } else if (!value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              email = value!;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Phone Number Field
                          TextFormField(
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Phone Number',
                              hintText: 'Enter your phone number',
                              prefixIcon: const Icon(Icons.phone_outlined),
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
                            obscureText: showPass1,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: lang.S.of(context).password,
                              hintText: lang.S.of(context).pleaseEnterAPassword,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPass1 = !showPass1;
                                  });
                                },
                                icon: Icon(showPass1 ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            onChanged: (value) {
                              givenPassword = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                //return 'Password can\'t be empty';
                                return lang.S.of(context).passwordCannotBeEmpty;
                              } else if (value.length < 4) {
                                //return 'Please enter a bigger password';
                                return lang.S.of(context).pleaseEnterABiggerPassword;
                              } else if (value.length < 4) {
                                //return 'Please enter a bigger password';
                                return lang.S.of(context).pleaseEnterABiggerPassword;
                              }
                              return null;
                            },
                            onSaved: (value) {
                              password = value!;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            obscureText: showPass2,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: lang.S.of(context).confirmPass,
                              hintText: lang.S.of(context).pleaseEnterAConfirmPassword,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPass2 = !showPass2;
                                  });
                                },
                                icon: Icon(showPass2 ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            onChanged: (value) {
                              givenPassword2 = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                //return 'Password can\'t be empty';
                                return lang.S.of(context).passwordCannotBeEmpty;
                              } else if (value.length < 4) {
                                // return 'Please enter a bigger password';
                                return lang.S.of(context).pleaseEnterABiggerPassword;
                              } else if (givenPassword != givenPassword2) {
                                //return 'Password Not mach';
                                return lang.S.of(context).passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Verification Method Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Verification Method:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: kMainColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Email Only'),
                                value: 'email',
                                groupValue: verificationMethod,
                                onChanged: (value) {
                                  setState(() {
                                    verificationMethod = value!;
                                  });
                                },
                                activeColor: kMainColor,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Phone Only'),
                                value: 'phone',
                                groupValue: verificationMethod,
                                onChanged: (value) {
                                  setState(() {
                                    verificationMethod = value!;
                                  });
                                },
                                activeColor: kMainColor,
                              ),
                            ),
                          ],
                        ),
                        RadioListTile<String>(
                          title: const Text('Both Email & Phone'),
                          value: 'both',
                          groupValue: verificationMethod,
                          onChanged: (value) {
                            setState(() {
                              verificationMethod = value!;
                            });
                          },
                          activeColor: kMainColor,
                        ),
                      ],
                    ),
                  ),
                  
                  ElevatedButton(
                    onPressed: () async {
                      if (validateAndSave()) {
                        await _registerWithFirebase();
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
                      lang.S.of(context).register,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lang.S.of(context).haveAcc,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: kMainColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          const LoginForm(
                            isEmailLogin: true,
                          ).launch(context);
                          // Navigator.pushNamed(context, '/loginForm');
                        },
                        child: Text(
                          lang.S.of(context).logIn,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: kMainColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      const PhoneAuth().launch(context);
                    },
                    child: Text(lang.S.of(context).loginWithPhone),
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
