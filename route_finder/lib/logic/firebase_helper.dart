import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseHelper {
  FirebaseHelper._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static User? get currentUser => auth.currentUser;
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  static Future<void> signOut() async {
    await auth.signOut();
  }

  static Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  static Future<void> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<Map<String, dynamic>> signInWithGoogleAndFinalize(
    BuildContext context,
  ) async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      
      if (account == null) {
        return {'success': false, 'message': 'Google sign-in cancelled.'};
      }

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!context.mounted) {
        return {'success': true, 'message': 'Login successful.'};
      }
      return {'success': true, 'message': 'Login successful and navigated.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Authentication error'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>> signInWithApple() async {

    try {
      
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken, 
        accessToken: appleCredential.authorizationCode,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      return {'success': true, 'result': result};

    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      return {'success': false};
    }
  }
}
