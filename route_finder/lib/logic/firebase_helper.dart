import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:route_finder/logic/google_places_models.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/models.dart';

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

      final user = auth.currentUser;
      if (user != null) {
        debugPrint('User registered: ${user.uid}');
        var callable = functions.httpsCallable('finalizeEmailRegistration');
        var response = await callable.call({'uid': user.uid, 'email': email});
        debugPrint('Finalize registration response: $response');
      }
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

      final user = auth.currentUser;
      if (user != null) {
        debugPrint('Login successful.');
        var callable = functions.httpsCallable('finalizeEmailRegistration');
        var response = await callable.call({
          'uid': user.uid,
          'email': user.email,
        });
        debugPrint('Finalize registration response: $response');
        return {'success': true, 'message': 'Login successful.'};
      }
      return {'success': true, 'message': 'Login successful and navigated.'};
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: $e');
      return {'success': false, 'message': e.message ?? 'Authentication error'};
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // static Future<Map<String, dynamic>> signInWithApple() async {
  //   try {
  //     final appleCredential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     final oauthCredential = OAuthProvider("apple.com").credential(
  //       idToken: appleCredential.identityToken,
  //       accessToken: appleCredential.authorizationCode,
  //     );

  //     final result = await FirebaseAuth.instance.signInWithCredential(
  //       oauthCredential,
  //     );

  //     return {'success': true, 'result': result};
  //   } catch (e) {
  //     debugPrint('Apple sign-in error: $e');
  //     return {'success': false};
  //   }
  // }

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

  static Future<Map<String, dynamic>> finalizeRouteCreation({
    required List<GooglePlace> selectedPlaces,
    required String routeName,
    Location? start,
    Location? end,
  }) async {
    try {
      debugPrint('Finalizing route creation...');
      var startPosition = await getCurrentLocation();
      var endPosition = await getCurrentLocation();

      start ??= startPosition.toLocation();
      end ??= endPosition.toLocation();

      var callable = functions.httpsCallable('finalizeRouteCreation');
      var result = await callable.call({
        'name': routeName,
        'selectedPlaces': selectedPlaces
            .map(
              (place) => {
                'placeId': place.placeId,
                'name': place.name,
                'coordinates': {
                  'latitude': place.geometry!.location.lat,
                  'longitude': place.geometry!.location.lng,
                },
                'rating': place.rating,
                'photos': place.photos.map((e) => e.toJson()).toList(),
                'types': place.types,
                'openingHours': place.openingHours?.toJson(),
              },
            )
            .toList(),
        'start': {
          'coordinates': {
            'latitude': start.coordinate.lat,
            'longitude': start.coordinate.lng,
          },
          'address': start.address,
        },
        'end': {
          'coordinates': {
            'latitude': end.coordinate.lat,
            'longitude': end.coordinate.lng,
          },
          'address': end.address,
        },
      });

      debugPrint("Cloud Function result: ${result.data}");
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error finalizing route creation: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteRoute({
    required String routeId,
  }) async {
    try {
      debugPrint('Deleting route $routeId...');
      var callable = functions.httpsCallable('deleteRoute');
      var result = await callable.call({'routeId': routeId});
      debugPrint('Route deleted successfully: $result');
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error deleting route: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<void> updateRouteStatus(String routeId, String status) async {
    try {
      debugPrint('Updating route status via Cloud Function...');
      var callable = functions.httpsCallable('updateRouteStatus');
      await callable.call({'routeId': routeId, 'status': status});
      debugPrint('Route status updated successfully.');
    } catch (e) {
      debugPrint('Error updating route status: $e');
      rethrow;
    }
  }

  static Future<void> updateWaypointStatus(
    String routeId,
    int waypointIndex, {
    bool? visited,
    bool? skipped,
  }) async {
    debugPrint('Updating waypoint status via Cloud Function...');
    try {
      debugPrint('Updating waypoint status via Cloud Function...');
      var callable = functions.httpsCallable('updateWaypointStatus');
      await callable.call({
        'routeId': routeId,
        'waypointIndex': waypointIndex,
        'visited': visited ?? false,
        'skipped': skipped ?? false,
      });
      debugPrint('Waypoint status updated successfully.');
    } catch (e) {
      debugPrint('Error updating waypoint status: $e');
      rethrow;
    }
  }

  static Future<void> rateRoute({
    required String routeId,
    required int routeRating,
    String? routeReview,
    required List<Map<String, dynamic>> placesRatings,
  }) async {
    try {
      debugPrint('Rating route $routeId via Cloud Function...');
      var callable = functions.httpsCallable('rateRoute');
      await callable.call({
        'routeId': routeId,
        'routeRating': routeRating,
        'routeReview': routeReview,
        'placesRatings': placesRatings,
      });
      debugPrint('Route rated successfully.');
    } catch (e) {
      debugPrint('Error rating route: $e');
      rethrow;
    }
  }
}
