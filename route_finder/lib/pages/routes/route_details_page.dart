import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/helpers.dart' hide decodePolyline;
import 'package:route_finder/logic/models.dart';
import 'package:route_finder/pages/routes/route_in_progress_page.dart';

class RouteDetailsPage extends StatefulWidget {
  final RouteModel route;
  const RouteDetailsPage({super.key, required this.route});

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  Set<Polyline> polylines = <Polyline>{};
  Set<Marker> markers = <Marker>{};

  @override
  void initState() {
    super.initState();
    _loadPolylines();
    _loadMarkers();
  }

  void _loadPolylines() {
    setState(() {
      final encodedPolyline = widget.route.routeData['encodedPolyline'];
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
    // 1. Initial load with default markers
    setState(() {
      final start = widget.route.start.coordinate;
      final end = widget.route.end.coordinate;

      // Start Marker
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(start.lat, start.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: "Start",
            snippet: widget.route.start.address,
          ),
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
          infoWindow: InfoWindow(
            title: "End",
            snippet: widget.route.end.address,
          ),
        ),
      );

      // Intermediate Waypoints (Default)
      for (int i = 0; i < widget.route.waypoints.length; i++) {
        final waypoint = widget.route.waypoints[i];
        markers.add(
          Marker(
            markerId: MarkerId('waypoint_$i'),
            position: LatLng(
              waypoint.coordinates.lat,
              waypoint.coordinates.lng,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: waypoint.name,
              snippet: "Stop ${i + 1}",
            ),
          ),
        );
      }
    });

    // 2. Load custom bitmap markers asynchronously
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    final Set<Marker> customMarkers = {};
    final start = widget.route.start.coordinate;
    final end = widget.route.end.coordinate;

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
        infoWindow: InfoWindow(
          title: "Start",
          snippet: widget.route.start.address,
        ),
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
        infoWindow: InfoWindow(title: "End", snippet: widget.route.end.address),
        anchor: const Offset(0.5, 0.5),
      ),
    );

    // Custom Intermediate Waypoints
    for (int i = 0; i < widget.route.waypoints.length; i++) {
      final waypoint = widget.route.waypoints[i];
      final icon = await createCircleBitmapDescriptor(
        AppColor.primary,
        40,
        borderColor: Colors.white,
        borderWidth: 2,
      );
      customMarkers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: LatLng(waypoint.coordinates.lat, waypoint.coordinates.lng),
          icon: icon,
          infoWindow: InfoWindow(
            title: waypoint.name,
            snippet: "Stop ${i + 1}",
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(AppSpacings.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(kRadiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.arrowLeft300,
                            color: AppColor.textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 250,
                            child: AppText(
                              widget.route.name,
                              variant: AppTextVariant.heading,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacings.xxl),

                SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    child: Stack(
                      children: [
                        GoogleMap(
                          gestureRecognizers:
                              <Factory<OneSequenceGestureRecognizer>>{
                                Factory<VerticalDragGestureRecognizer>(
                                  () => VerticalDragGestureRecognizer(),
                                ),
                                Factory<HorizontalDragGestureRecognizer>(
                                  () => HorizontalDragGestureRecognizer(),
                                ),
                                Factory<ScaleGestureRecognizer>(
                                  () => ScaleGestureRecognizer(),
                                ),
                                Factory<PanGestureRecognizer>(
                                  () => PanGestureRecognizer(),
                                ),
                              }.toSet(),
                          initialCameraPosition: CameraPosition(
                            target: () {
                              final start = widget.route.start.coordinate;
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
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacings.lg,
                              horizontal: AppSpacings.xxl * 3,
                            ),
                            child: AppButton(
                              label: 'Start',
                              onTap: () {
                                context.pushAnimated(
                                  RouteInProgressPage(route: widget.route),
                                );
                              },
                              leading: Icon(
                                LucideIcons.play,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: AppSpacings.xxl),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacings.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText("Waypoints", variant: AppTextVariant.heading),

                        SizedBox(height: AppSpacings.lg),

                        ...widget.route.waypoints.map((waypoint) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacings.lg,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColor.background,
                                borderRadius: BorderRadius.circular(kRadiusMd),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacings.lg),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        kRadiusMd,
                                      ),
                                      child: Image.network(
                                        "https://places.googleapis.com/v1/${waypoint.photos.first.name}/media?maxWidthPx=400&key=${dotenv.env['GOOGLE_PLACES_API_KEY'] ?? ''}",
                                        width: 75,
                                        height: 75,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacings.lg),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            waypoint.name,
                                            variant: AppTextVariant.title,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                          SizedBox(height: AppSpacings.sm),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                              AppText(
                                                waypoint.rating.toString(),
                                                variant: AppTextVariant.body,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
