import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send OTP to email
  static Future<String?> sendOTPToEmail(String email) async {
    try {
      // Create a new user with email and password (temporary)
      // This will send a verification email
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'temporary_password_123', // Temporary password
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();
      
      return 'OTP sent to $email';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // If email already exists, sign in and send verification
        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: 'temporary_password_123',
          );
          await _auth.currentUser?.sendEmailVerification();
          return 'OTP sent to $email';
        } catch (signInError) {
          // If sign in fails, try to send password reset (which includes verification)
          await _auth.sendPasswordResetEmail(email: email);
          return 'OTP sent to $email';
        }
      } else {
        return 'Error: ${e.message}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Verify email with OTP (check if email is verified)
  static Future<bool> verifyEmailOTP() async {
    try {
      await _auth.currentUser?.reload();
      User? user = _auth.currentUser;
      return user?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Create user with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is verified
  static bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Resend verification email
  static Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Delete user account
  static Future<void> deleteUser() async {
    await _auth.currentUser?.delete();
  }

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }
}
