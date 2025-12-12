import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geolocator/geolocator.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/models.dart';

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) => UserModel.fromDocument(snapshot));
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final userRoutesProvider = StreamProvider<List<RouteModel>>((ref) {
  final userAsyncValue = ref.watch(userProvider);

  return userAsyncValue.when(
    data: (userModel) {
      if (userModel == null || userModel.routeIds.isEmpty) {
        return Stream.value([]);
      }

      debugPrint('User routes: ${userModel.routeIds}');

      final idsToQuery = userModel.routeIds.take(30).toList();

      debugPrint('Ids to query: $idsToQuery');

      return FirebaseFirestore.instance
          .collection('routes')
          .where(FieldPath.documentId, whereIn: idsToQuery)
          .snapshots()
          .map((snapshot) {
            debugPrint('Firestore snapshot docs: ${snapshot.docs.length}');
            for (var doc in snapshot.docs) {
              debugPrint('Doc data: ${doc.data()}');
            }
            return snapshot.docs
                .map((doc) => RouteModel.fromDocument(doc))
                .toList();
          });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final userLocationProvider = FutureProvider<Position>((ref) async {
  return await getCurrentLocation();
});

final communityRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final locationAsync = ref.watch(userLocationProvider);

  return locationAsync.when(
    data: (position) async {
      try {
        debugPrint('Fetching community routes...');
        final result = await FirebaseHelper.functions
            .httpsCallable('getCommunityRoutes')
            .call({
              'location': {
                'coordinates': {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                },
                'address': 'Current Location',
              },
              'radius': 50000,
            });
        debugPrint('Result: ${result.data}');
        final data = Map<String, dynamic>.from(result.data as Map);
        final routesData = data['routes'] as List<dynamic>;

        return routesData.map((routeData) {
          return RouteModel.fromJson(
            Map<String, dynamic>.from(routeData as Map),
            id: routeData['routeId'] ?? '',
          );
        }).toList();
      } catch (e) {
        debugPrint('Error fetching community routes: $e');
        return [];
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}
