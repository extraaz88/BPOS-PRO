import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../firebase_options.dart';

class FirebasePhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;
  static String? _phoneNumber;

  // Check if Firebase is initialized
  static Future<void> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase is not initialized. Please call Firebase.initializeApp() first.');
      }
      
      // Additional check to ensure Firebase Auth is available
      // _auth is a static final field, so it can't be null
    } catch (e) {
      print('Firebase initialization check failed: $e');
      throw Exception('Firebase initialization error: $e');
    }
  }

  // Reinitialize Firebase if needed
  static Future<void> reinitializeFirebase() async {
    try {
      // Clear existing apps
      for (var app in Firebase.apps) {
        await app.delete();
      }
      
      // Reinitialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      print('Firebase reinitialized successfully');
    } catch (e) {
      print('Firebase reinitialization failed: $e');
      throw Exception('Failed to reinitialize Firebase: $e');
    }
  }

  // Send OTP to phone number
  static Future<String?> sendOTPToPhone(String phoneNumber) async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();
      
      _phoneNumber = phoneNumber;
      
      // Format phone number with country code if not already formatted
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Add +91 for India if no country code
        formattedPhone = '+91$phoneNumber';
      }

      // Show loading toast
      _showLoadingToast('Sending OTP...');

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          try {
            await _auth.signInWithCredential(credential);
            _showSuccessToast('Phone verified automatically!');
          } catch (e) {
            _showErrorToast('Auto-verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          String errorMessage = _getErrorMessage(e.code);
          _showErrorToast(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          print('OTP sent successfully to $formattedPhone');
          _showSuccessToast('OTP sent to $formattedPhone');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          print('Auto-retrieval timeout for $formattedPhone');
        },
        timeout: const Duration(seconds: 60),
      );

      return 'OTP sent to $formattedPhone';
    } catch (e) {
      print('Error sending OTP: $e');
      
      // Check if it's a missing client error and try to reinitialize
      if (e.toString().contains('missing client') || e.toString().contains('client')) {
        try {
          _showLoadingToast('Reinitializing Firebase...');
          await reinitializeFirebase();
          _showSuccessToast('Firebase reinitialized. Please try again.');
          return 'Firebase reinitialized. Please try again.';
        } catch (reinitError) {
          print('Firebase reinitialization failed: $reinitError');
          _showErrorToast('Firebase configuration error. Please restart the app.');
          return 'Error: Firebase configuration error';
        }
      }
      
      String errorMessage = _getErrorMessage(e.toString());
      _showErrorToast(errorMessage);
      return 'Error: $e';
    }
  }

  // Verify OTP code
  static Future<UserCredential?> verifyOTP(String otpCode) async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();
      
      if (_verificationId == null) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      _showLoadingToast('Verifying OTP...');

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      _showSuccessToast('Phone verified successfully!');
      return userCredential;
    } catch (e) {
      String errorMessage = _getErrorMessage(e.toString());
      _showErrorToast(errorMessage);
      throw Exception('Invalid OTP: $e');
    }
  }

  // Resend OTP
  static Future<String?> resendOTP() async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();
      
      if (_phoneNumber == null) {
        _showErrorToast('Phone number not found. Please start verification again.');
        return 'Phone number not found. Please start verification again.';
      }
      _showLoadingToast('Resending OTP...');
      return await sendOTPToPhone(_phoneNumber!);
    } catch (e) {
      String errorMessage = _getErrorMessage(e.toString());
      _showErrorToast(errorMessage);
      return 'Error: $e';
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
    _phoneNumber = null;
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // Get user phone number
  static String? getUserPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  // Delete user account
  static Future<void> deleteUser() async {
    await _auth.currentUser?.delete();
    _verificationId = null;
    _phoneNumber = null;
  }

  // Update phone number
  static Future<void> updatePhoneNumber(String newPhoneNumber) async {
    // This requires re-authentication
    // For now, we'll just update the stored phone number
    _phoneNumber = newPhoneNumber;
  }

  // Toast methods
  static void _showLoadingToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Get user-friendly error messages
  static String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later';
      case 'app-not-authorized':
        return 'App not authorized for phone authentication';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      case 'credential-already-in-use':
        return 'This phone number is already in use';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'unknown':
        return 'An unknown error occurred. Please try again';
      default:
        if (errorCode.contains('blocked')) {
          return 'Account temporarily blocked. Please try again later';
        } else if (errorCode.contains('reCAPTCHA')) {
          return 'reCAPTCHA verification failed. Please try again';
        } else if (errorCode.contains('certificate')) {
          return 'App verification failed. Please try again';
        } else if (errorCode.contains('missing client') || errorCode.contains('client')) {
          return 'Firebase configuration error. Please restart the app';
        } else if (errorCode.contains('INVALID_CERT_HASH')) {
          return 'App verification failed. Please check your app configuration';
        }
        return 'Error: $errorCode';
    }
  }
}
