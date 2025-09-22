import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_pos/Screens/Authentication/profile_setup_screen.dart';
import 'package:mobile_pos/services/firebase_auth_service.dart';

import '../../constant.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const OTPVerificationScreen({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email is verified
      bool isVerified = await FirebaseAuthService.verifyEmailOTP();
      
      if (isVerified) {
        
        // Update password to the actual password
        try {
          await FirebaseAuthService.updatePassword(widget.password);
        } catch (e) {
          print('Error updating password: $e');
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to profile setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileSetup(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your email and click the verification link'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      String? result = await FirebaseAuthService.sendOTPToEmail(widget.email);
      
      if (result != null && result.contains('OTP sent')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.green,
          ),
        );
        _startResendCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        title: Text(
          'Verify Email',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'images/BharatBill.png',
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'We have sent a verification link to:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                widget.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: kMainColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.blue[600],
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Check your email inbox and click the verification link to verify your account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify Email',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Resend Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the email? ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: _resendCountdown > 0 || _isResending ? null : _resendOTP,
                    child: Text(
                      _isResending
                          ? 'Sending...'
                          : _resendCountdown > 0
                              ? 'Resend in ${_resendCountdown}s'
                              : 'Resend OTP',
                      style: TextStyle(
                        color: _resendCountdown > 0 || _isResending 
                            ? Colors.grey 
                            : kMainColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Back to Login
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Back to Login',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: kMainColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
