// lib/utils/navigator_creator.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:route_finder/logic/models.dart';

/// Available built-in transition animations.
enum NavigationAnimation {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  rotate,
  fadeScale,
  none,
}

/// Small helper exposing quick navigation helpers with custom transitions.
class NavigatorCreator {
  NavigatorCreator._(); // static only

  /// Push a page with a chosen animation.
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    NavigationAnimation animation = NavigationAnimation.slideFromRight,
    Duration duration = const Duration(milliseconds: 360),
    Curve curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    RouteSettings? settings,
    bool maintainState = true,
    bool opaque = true,
    bool barrierDismissible = false,
    bool fullscreenDialog = false,
  }) {
    final route = _createRoute<T>(
      page,
      animation: animation,
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      fullscreenDialog: fullscreenDialog,
    );
    return Navigator.of(context).push<T>(route);
  }

  /// Replace current route with [page].
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    NavigationAnimation animation = NavigationAnimation.slideFromRight,
    Duration duration = const Duration(milliseconds: 360),
    Curve curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    RouteSettings? settings,
    bool maintainState = true,
    bool opaque = true,
    bool fullscreenDialog = false,
  }) {
    final route = _createRoute<T>(
      page,
      animation: animation,
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
      opaque: opaque,
      fullscreenDialog: fullscreenDialog,
    );
    return Navigator.of(context).pushReplacement<T, TO>(route);
  }

  /// Push and remove until [predicate] returns true.
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    NavigationAnimation animation = NavigationAnimation.slideFromRight,
    Duration duration = const Duration(milliseconds: 360),
    Curve curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    RouteSettings? settings,
    bool maintainState = true,
    bool opaque = true,
    bool fullscreenDialog = false,
  }) {
    final route = _createRoute<T>(
      page,
      animation: animation,
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
      opaque: opaque,
      fullscreenDialog: fullscreenDialog,
    );
    return Navigator.of(context).pushAndRemoveUntil<T>(route, predicate);
  }

  /// Pop helper
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Internal route factory used by push variants.
  static PageRoute<T> _createRoute<T>(
    Widget page, {
    NavigationAnimation animation = NavigationAnimation.slideFromRight,
    required Duration duration,
    required Curve curve,
    RouteSettings? settings,
    bool maintainState = true,
    bool opaque = true,
    bool barrierDismissible = false,
    bool fullscreenDialog = false,
  }) {
    // If no animation requested, use a MaterialPageRoute for native look.
    if (animation == NavigationAnimation.none) {
      return MaterialPageRoute<T>(
        builder: (_) => page,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animationPrimary, animationSecondary) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      transitionsBuilder:
          (context, animationPrimary, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animationPrimary,
              curve: curve,
            );

            switch (animation) {
              case NavigationAnimation.slideFromRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                );

              case NavigationAnimation.slideFromLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                );

              case NavigationAnimation.slideFromBottom:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                );

              case NavigationAnimation.slideFromTop:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -1.0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                );

              case NavigationAnimation.fade:
                return FadeTransition(
                  opacity: animationPrimary.drive(CurveTween(curve: curve)),
                  child: child,
                );

              case NavigationAnimation.scale:
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                  child: FadeTransition(
                    opacity: animationPrimary.drive(
                      CurveTween(curve: const Interval(0.0, 0.9)),
                    ),
                    child: child,
                  ),
                );

              case NavigationAnimation.rotate:
                return RotationTransition(
                  turns: Tween<double>(begin: 0.15, end: 0.0).animate(curved),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
                    child: child,
                  ),
                );

              case NavigationAnimation.fadeScale:
                return FadeTransition(
                  opacity: animationPrimary.drive(CurveTween(curve: curve)),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
                    child: child,
                  ),
                );

              case NavigationAnimation.none:
                return child;
            }
          },
    );
  }
}

/// Convenient BuildContext extensions to call the helpers more succinctly.
extension NavigatorCreatorExt on BuildContext {
  Future<T?> pushAnimated<T>(
    Widget page, {
    NavigationAnimation animation = NavigationAnimation.slideFromRight,
    Duration duration = const Duration(milliseconds: 360),
    Curve curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    RouteSettings? settings,
    bool maintainState = true,
    bool opaque = true,
    bool fullscreenDialog = false,
  }) => NavigatorCreator.push<T>(
    this,
    page,
    animation: animation,
    duration: duration,
    curve: curve,
    settings: settings,
    maintainState: maintainState,
    opaque: opaque,
    fullscreenDialog: fullscreenDialog,
  );

  Future<T?> pushReplacementAnimated<T, TO>(
    Widget page, {
    NavigationAnimation animation = NavigationAnimation.slideFromRight,
    Duration duration = const Duration(milliseconds: 360),
    Curve curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    RouteSettings? settings,
    bool maintainState = true,
    bool opaque = true,
    bool fullscreenDialog = false,
  }) => NavigatorCreator.pushReplacement<T, TO>(
    this,
    page,
    animation: animation,
    duration: duration,
    curve: curve,
    settings: settings,
    maintainState: maintainState,
    opaque: opaque,
    fullscreenDialog: fullscreenDialog,
  );

  void popAnimated<T extends Object?>([T? result]) =>
      NavigatorCreator.pop<T>(this, result);
}

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  return await Geolocator.getCurrentPosition();
}

extension CapitalizeFirst on String {
  String capitalizeFirst() => this[0].toUpperCase() + substring(1);
  String capitalizeFirstLetters() =>
      split(" ").map((e) => e.capitalizeFirst()).join(" ");
}

double calculateDistance(Coordinate start, Coordinate end) {
  return Geolocator.distanceBetween(start.lat, start.lng, end.lat, end.lng);
}

List<Coordinate> decodePolyline(String encoded) {
  List<Coordinate> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    poly.add(
      Coordinate(lat: (lat / 1E5).toDouble(), lng: (lng / 1E5).toDouble()),
    );
  }
  return poly;
}
