import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  if (v is bool) return v ? 1.0 : 0.0;
  return 0.0;
}

List<String> _toStringList(dynamic v) {
  if (v == null) return <String>[];
  if (v is List) {
    return v
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return <String>[];
}

class Coordinate {
  final double lat;
  final double lng;

  const Coordinate({required this.lat, required this.lng});

  factory Coordinate.fromJson(dynamic src) {
    if (src == null) return const Coordinate(lat: 0.0, lng: 0.0);
    if (src is Coordinate) return src;
    if (src is Map) {
      final dynamic latV =
          src['lat'] ?? src['latitude'] ?? src['latitud'] ?? src['Latitude'];
      final dynamic lngV =
          src['lng'] ?? src['longitude'] ?? src['lon'] ?? src['Longitude'];
      if (latV != null && lngV != null) {
        return Coordinate(lat: _toDouble(latV), lng: _toDouble(lngV));
      }
    }
    return const Coordinate(lat: 0.0, lng: 0.0);
  }

  Map<String, dynamic> toJson() => {'latitude': lat, 'longitude': lng};

  @override
  String toString() => 'Coordinate(latitude: $lat, longitude: $lng)';

  LatLng toLatLng() => LatLng(lat, lng);
}

class Location {
  final String address;
  final Coordinate coordinate;

  const Location({required this.address, required this.coordinate});

  factory Location.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] ?? '').toString();
    final coordinate = Coordinate.fromJson(
      json['coordinate'] ??
          json['coordinates'] ??
          json['coords'] ??
          json['location'] ??
          json['latlng'] ??
          json['geo'] ??
          json['geopoint'],
    );
    return Location(address: address, coordinate: coordinate);
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'coordinates': coordinate.toJson(),
  };
}

extension PositionToLocation on Position {
  Location toLocation() {
    return Location(
      address: 'Current Location',
      coordinate: Coordinate(lat: latitude, lng: longitude),
    );
  }
}

class Photo {
  final int height;
  final List<String> htmlAttributions;
  final String name;
  final int width;

  Photo({
    required this.height,
    required this.htmlAttributions,
    required this.name,
    required this.width,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      height: json['height'] as int? ?? 0,
      htmlAttributions: _toStringList(json['html_attributions']),
      name: json['name'] as String? ?? '',
      width: json['width'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'html_attributions': htmlAttributions,
      'name': name,
      'width': width,
    };
  }
}

class Waypoint {
  final Coordinate coordinates;
  final String name;
  final Map<String, dynamic> openingHours;
  final List<Photo> photos;
  final String placeId;
  final double rating;
  final List<String> types;

  final bool visited;
  final bool skipped;

  Waypoint({
    required this.coordinates,
    required this.name,
    required this.openingHours,
    required this.photos,
    required this.placeId,
    required this.rating,
    required this.types,
    this.visited = false,
    this.skipped = false,
  });

  Waypoint copyWith({
    Coordinate? coordinates,
    String? name,
    Map<String, dynamic>? openingHours,
    List<Photo>? photos,
    String? placeId,
    double? rating,
    List<String>? types,
    bool? visited,
    bool? skipped,
  }) {
    return Waypoint(
      coordinates: coordinates ?? this.coordinates,
      name: name ?? this.name,
      openingHours: openingHours ?? this.openingHours,
      photos: photos ?? this.photos,
      placeId: placeId ?? this.placeId,
      rating: rating ?? this.rating,
      types: types ?? this.types,
      visited: visited ?? this.visited,
      skipped: skipped ?? this.skipped,
    );
  }

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      coordinates: Coordinate.fromJson(json['coordinates']),
      name: json['name'] as String? ?? '',
      openingHours: Map<String, dynamic>.from(json['opening_hours'] ?? {}),
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      placeId: json['placeId'] as String? ?? json['placeId'] as String? ?? '',
      rating: _toDouble(json['rating']),
      types: _toStringList(json['types']),
      visited: json['visited'] as bool? ?? false,
      skipped: json['skipped'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates.toJson(),
      'name': name,
      'opening_hours': openingHours,
      'photos': photos.map((e) => e.toJson()).toList(),
      'placeId': placeId,
      'rating': rating,
      'types': types,
      'visited': visited,
      'skipped': skipped,
    };
  }
}

class RouteModel {
  final String? id;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String createdBy;
  final Location start;
  final Location end;
  final String name;
  final List<Waypoint> waypoints;
  final Map<String, dynamic> routeData;
  final String status;
  final int currentWaypointIndex;

  const RouteModel({
    this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.start,
    required this.end,
    required this.name,
    required this.waypoints,
    required this.routeData,
    this.status = 'planned',
    this.currentWaypointIndex = 0,
  });

  RouteModel copyWith({
    String? id,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdBy,
    Location? start,
    Location? end,
    String? name,
    List<Waypoint>? waypoints,
    Map<String, dynamic>? routeData,
    String? status,
    int? currentWaypointIndex,
  }) {
    return RouteModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      start: start ?? this.start,
      end: end ?? this.end,
      name: name ?? this.name,
      waypoints: waypoints ?? this.waypoints,
      routeData: routeData ?? this.routeData,
      status: status ?? this.status,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
    );
  }

  factory RouteModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return RouteModel(
      id: json['routeId'] as String? ?? id,
      createdAt: json['created_at'] as Timestamp? ?? Timestamp.now(),
      updatedAt: json['updated_at'] as Timestamp? ?? Timestamp.now(),
      createdBy: json['created_by'] as String? ?? '',
      start: Location.fromJson(Map<String, dynamic>.from(json['start'] ?? {})),
      end: Location.fromJson(Map<String, dynamic>.from(json['end'] ?? {})),
      name: json['name'] as String? ?? 'Unnamed Route',
      waypoints:
          (json['waypoints'] as List<dynamic>?)
              ?.map(
                (e) => Waypoint.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          [],
      routeData: {
        'distance': _toDouble(
          json['totalDistance'] ?? json['routeData']?['totalDistance'],
        ),
        'encodedPolyline':
            (json['encodedPolyline'] ?? json['routeData']?['encodedPolyline'])
                ?.toString() ??
            '',
        'totalDistance': _toDouble(
          json['totalDistance'] ?? json['routeData']?['totalDistance'],
        ),
      },
      status: json['status'] as String? ?? 'planned',
      currentWaypointIndex: json['currentWaypointIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'start': start.toJson(),
      'end': end.toJson(),
      'name': name,
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
      'totalDistance': routeData['distance'],
      'encodedPolyline': routeData['encodedPolyline'],
      'status': status,
      'currentWaypointIndex': currentWaypointIndex,
    };
  }

  static RouteModel fromDocument(DocumentSnapshot doc) {
    debugPrint('Parsing RouteModel from doc: ${doc.id}');
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      debugPrint('Document data is null for ${doc.id}');
      return RouteModel(
        id: doc.id,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        createdBy: '',
        start: const Location(
          address: '',
          coordinate: Coordinate(lat: 0, lng: 0),
        ),
        end: const Location(
          address: '',
          coordinate: Coordinate(lat: 0, lng: 0),
        ),
        name: 'Error Route',
        waypoints: [],
        routeData: {},
      );
    }
    try {
      debugPrint('RouteModel data: $data');
      return RouteModel.fromJson(data, id: doc.id);
    } catch (e, stack) {
      debugPrint('Error parsing RouteModel ${doc.id}: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final List<String> routeIds;

  UserModel({required this.id, required this.email, required this.routeIds});

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return UserModel(id: doc.id, email: '', routeIds: []);
    }
    return UserModel(
      id: doc.id,
      email: data['email']?.toString() ?? '',
      routeIds: List<String>.from(data['routeIds'] ?? []),
    );
  }
}
