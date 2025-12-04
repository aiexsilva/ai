import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:route_finder/logic/models.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseHelper {
  FirebaseHelper._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
    region: 'europe-southwest1',
  );

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

      final googleAuth = account.authentication;
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

      final result = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      return {'success': true, 'result': result};
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      return {'success': false};
    }
  }

  static Future<List<LatLng>> generateRoutePolylines({
    required Location start,
    required Location end,
    List<Location>? waypoints,
  }) async {
    try {
      debugPrint('Generating route polylines via Cloud Function...');

      final result = await functions
          .httpsCallable('generateRoutePolylines')
          .call({
            'start': {
              'coordinates': {
                'latitude': start.coordinate.lat,
                'longitude': start.coordinate.lng,
              },
              'address': start.address, // Assuming name is address or similar
            },
            'end': {
              'coordinates': {
                'latitude': end.coordinate.lat,
                'longitude': end.coordinate.lng,
              },
              'address': end.address,
            },
            'waypoints': waypoints
                ?.map(
                  (w) => {
                    'coordinates': {
                      'latitude': w.coordinate.lat,
                      'longitude': w.coordinate.lng,
                    },
                    'address': w.address,
                  },
                )
                .toList(),
          });

      debugPrint("Cloud Function result: ${result.data}");

      final data = result.data as Map<String, dynamic>;
      final List<dynamic> coords = data['polyline'] ?? [];

      debugPrint("Route polyline: $coords");

      return coords
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList();
    } catch (e) {
      debugPrint("Error generating route: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> createRouteWithKeywords({
    required Location start,
    required List<String> keywords,
    required int radius,
  }) async {
    try {
      final result = await functions
          .httpsCallable('createRouteWithKeywords')
          .call({
            'start': {
              'coordinates': {
                'latitude': start.coordinate.lat,
                'longitude': start.coordinate.lng,
              },
              'address': start.address,
            },
            'keywords': keywords,
            'radius': radius,
          });

      debugPrint("Cloud Function result: ${result.data}");

      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error generating route: $e");
      return {'success': false, 'error': e.toString()};
    }
  }
}
