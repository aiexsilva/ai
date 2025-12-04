import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTestPage extends StatefulWidget {
  final List<LatLng>? polylines;
  const MapTestPage({super.key, this.polylines});

  @override
  State<MapTestPage> createState() => _MapTestPageState();
}

class _MapTestPageState extends State<MapTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Test')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(41.37943746011691, -8.420000),
        ),
        polylines: widget.polylines != null
            ? {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: widget.polylines!,
                  color: Colors.blue,
                  width: 5,
                ),
              }
            : {},
      ),
    );
  }
}
