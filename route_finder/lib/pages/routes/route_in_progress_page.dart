import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/helpers.dart' hide decodePolyline;

import 'package:route_finder/logic/models.dart';
import 'package:route_finder/pages/routes/rate_route_page.dart';

class RouteInProgressPage extends StatefulWidget {
  final RouteModel route;
  const RouteInProgressPage({super.key, required this.route});

  @override
  State<RouteInProgressPage> createState() => _RouteInProgressPageState();
}

class _RouteInProgressPageState extends State<RouteInProgressPage> {
  Set<Polyline> polylines = <Polyline>{};
  Set<Marker> markers = <Marker>{};
  late RouteModel _currentRoute;
  Position? _currentPosition;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.route;
    _loadPolylines();
    _loadMarkers();
    _startTrip();
    _getCurrentLocation();
  }

  Future<void> _startTrip() async {
    if (_currentRoute.status != 'active') {
      await FirebaseHelper.updateRouteStatus(_currentRoute.id!, 'active');

      // update current route
      final updatedDoc = await FirebaseHelper.firestore
          .collection('routes')
          .doc(_currentRoute.id)
          .get();
      setState(() {
        _currentRoute = RouteModel.fromJson(updatedDoc.data() ?? {});
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _loadPolylines() {
    setState(() {
      final encodedPolyline = _currentRoute.routeData['encodedPolyline'];
      List<Coordinate> polylinePoints = decodePolyline(encodedPolyline);
      final polyline = Polyline(
        polylineId: const PolylineId('route_polyline'),
        points: polylinePoints.map((c) => LatLng(c.lat, c.lng)).toList(),
        color: AppColor.primary,
        width: 5,
      );
      polylines.add(polyline);
    });
  }

  void _loadMarkers() {
    setState(() {
      markers.clear();
      final start = _currentRoute.start.coordinate;
      final end = _currentRoute.end.coordinate;

      // Start Marker
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(start.lat, start.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // End Marker
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(end.lat, end.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );

      // Waypoints
      for (int i = 0; i < _currentRoute.waypoints.length; i++) {
        final waypoint = _currentRoute.waypoints[i];
        markers.add(
          Marker(
            markerId: MarkerId('waypoint_$i'),
            position: LatLng(
              waypoint.coordinates.lat,
              waypoint.coordinates.lng,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              waypoint.visited
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueAzure,
            ),
            alpha: waypoint.skipped ? 0.5 : 1.0,
          ),
        );
      }
    });
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    final Set<Marker> customMarkers = {};
    final start = _currentRoute.start.coordinate;
    final end = _currentRoute.end.coordinate;

    // Custom Start Marker
    final startIcon = await createCircleBitmapDescriptor(
      Colors.white,
      40,
      borderColor: AppColor.primary,
      borderWidth: 3,
    );
    customMarkers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(start.lat, start.lng),
        icon: startIcon,
        anchor: const Offset(0.5, 0.5),
      ),
    );

    // Custom End Marker
    final endIcon = await createCircleBitmapDescriptor(
      Colors.white,
      40,
      borderColor: Colors.green,
      borderWidth: 3,
    );
    customMarkers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(end.lat, end.lng),
        icon: endIcon,
        anchor: const Offset(0.5, 0.5),
      ),
    );

    // Custom Intermediate Waypoints
    for (int i = 0; i < _currentRoute.waypoints.length; i++) {
      final waypoint = _currentRoute.waypoints[i];
      final isVisited = waypoint.visited;
      final isSkipped = waypoint.skipped;

      final icon = await createCircleBitmapDescriptor(
        isVisited ? Colors.green : (isSkipped ? Colors.grey : AppColor.primary),
        40,
        borderColor: Colors.white,
        borderWidth: 2,
      );

      customMarkers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: LatLng(waypoint.coordinates.lat, waypoint.coordinates.lng),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    if (mounted) {
      setState(() {
        markers = customMarkers;
      });
    }
  }

  Future<void> _handleWaypointAction(bool visited) async {
    if (_isLoading) return;

    final index = _currentRoute.currentWaypointIndex;
    if (index >= _currentRoute.waypoints.length - 1) {
      debugPrint("_handleWaypointAction: completed");
      setState(() => _isLoading = true);
      try {
        debugPrint(
          "Updating route status to completed for ride ${_currentRoute.toJson().toString()}",
        );
        await FirebaseHelper.updateRouteStatus(_currentRoute.id!, 'completed');
        if (mounted) {
          context.pushAnimated(RateRoutePage(route: _currentRoute));
        }
      } catch (e) {
        debugPrint("Error completing route: $e");
        if (mounted) {
          AppToast.show(context, "Error completing route. Please try again.");
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // Optimistic Update
    setState(() {
      _isLoading = true;
      final updatedWaypoints = List<Waypoint>.from(_currentRoute.waypoints);
      updatedWaypoints[index] = updatedWaypoints[index].copyWith(
        visited: visited,
        skipped: !visited,
      );

      _currentRoute = _currentRoute.copyWith(
        waypoints: updatedWaypoints,
        currentWaypointIndex: index + 1,
      );
      _loadMarkers();
    });

    try {
      await FirebaseHelper.updateWaypointStatus(
        _currentRoute.id!,
        index,
        visited: visited,
        skipped: !visited,
      );

      // Optional: Sync with server to be sure
      final updatedDoc = await FirebaseHelper.firestore
          .collection('routes')
          .doc(_currentRoute.id)
          .get();

      if (mounted) {
        // Only update if we haven't moved on (basic check)
        final serverRoute = RouteModel.fromDocument(updatedDoc);
        if (serverRoute.currentWaypointIndex ==
            _currentRoute.currentWaypointIndex) {
          setState(() {
            _currentRoute = serverRoute;
            _loadMarkers();
          });
        }
      }
    } catch (e) {
      debugPrint("Error updating waypoint: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getDistanceToNextWaypoint() {
    if (_currentPosition == null) return "Calculating...";
    final index = _currentRoute.currentWaypointIndex;
    if (index >= _currentRoute.waypoints.length) return "Arrived";

    final waypoint = _currentRoute.waypoints[index];
    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      waypoint.coordinates.lat,
      waypoint.coordinates.lng,
    );

    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentRoute.currentWaypointIndex + 1;
    final totalSteps = _currentRoute.waypoints.length;
    final progress = currentStep / totalSteps;
    final isCompleted =
        _currentRoute.currentWaypointIndex >= _currentRoute.waypoints.length;

    Waypoint? nextWaypoint;
    if (!isCompleted) {
      nextWaypoint =
          _currentRoute.waypoints[_currentRoute.currentWaypointIndex];
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Stack(
          children: [
            // Map
            GoogleMap(
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer(),
                ),
                Factory<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
                ),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              }.toSet(),
              initialCameraPosition: CameraPosition(
                target: () {
                  final start = _currentRoute.start.coordinate;
                  if (start.lat != 0 || start.lng != 0) {
                    return start.toLatLng();
                  }
                  if (polylines.isNotEmpty) {
                    return polylines.first.points.first;
                  }
                  return const LatLng(0, 0);
                }(),
                zoom: 15,
              ),
              markers: markers,
              polylines: polylines,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
            ),

            // Top Row
            Positioned(
              top: AppSpacings.xxl * 2,
              left: AppSpacings.lg,
              right: AppSpacings.lg,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacings.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: AppColor.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacings.lg),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacings.lg,
                        vertical: AppSpacings.lg,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kRadiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  _currentRoute.name,
                                  variant: AppTextVariant.body,
                                  weightOverride: FontWeight.w600,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacings.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    kRadiusLg,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColor.primary,
                                        ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacings.md),
                          AppText(
                            "$currentStep/$totalSteps",
                            variant: AppTextVariant.body,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Modal
            if (!isCompleted && nextWaypoint != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacings.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(kRadiusXl),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: AppSpacings.lg),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     AppText(
                      //       "NEXT STOP",
                      //       variant: AppTextVariant.title,
                      //       style: const TextStyle(
                      //         color: AppColor.primary,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //     GestureDetector(
                      //       onTap: () {},
                      //       child: Row(
                      //         children: [
                      //           AppText(
                      //             "All stops",
                      //             variant: AppTextVariant.body,
                      //             style: const TextStyle(
                      //               color: AppColor.primary,
                      //             ),
                      //           ),
                      //           const Icon(
                      //             LucideIcons.chevronUp,
                      //             size: 16,
                      //             color: AppColor.primary,
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: AppSpacings.md),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(kRadiusMd),
                            child: Image.network(
                              "https://places.googleapis.com/v1/${nextWaypoint.photos.first.name}/media?maxWidthPx=400&key=${dotenv.env['GOOGLE_PLACES_API_KEY'] ?? ''}",
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacings.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  nextWaypoint.name,
                                  variant: AppTextVariant.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  nextWaypoint.types.isNotEmpty
                                      ? nextWaypoint.types.first
                                            .replaceAll('_', ' ')
                                            .toUpperCase()
                                      : 'PLACE',
                                  variant: AppTextVariant.body,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.navigation,
                                      size: 16,
                                      color: AppColor.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    AppText(
                                      "~${_getDistanceToNextWaypoint()} away",
                                      variant: AppTextVariant.body,
                                      style: const TextStyle(
                                        color: AppColor.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacings.xl),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: "Skip",
                              onTap: () => _handleWaypointAction(false),
                              variant: AppButtonVariant.outline,
                              isLoading: _isLoading,
                              leading: const Icon(
                                LucideIcons.skipForward,
                                size: 20,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacings.md),
                          Expanded(
                            child: AppButton(
                              label: "Mark Visited",
                              onTap: () => _handleWaypointAction(true),
                              isLoading: _isLoading,
                              leading: const Icon(
                                LucideIcons.check,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
