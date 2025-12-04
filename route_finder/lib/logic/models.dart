import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:route_finder/logic/google_places_models.dart';

enum Difficulty { easy, medium, hard }

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
  if (v is String) {
    return v
        .split(RegExp(r'[,\s;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return <String>[];
}

String _difficultyToString(Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return 'easy';
    case Difficulty.medium:
      return 'medium';
    case Difficulty.hard:
      return 'hard';
  }
}

Difficulty _difficultyFromString(String? s) {
  if (s == null) return Difficulty.medium;
  final v = s.toLowerCase();
  switch (v) {
    case 'easy':
    case 'e':
      return Difficulty.easy;
    case 'hard':
    case 'h':
      return Difficulty.hard;
    case 'medium':
    default:
      return Difficulty.medium;
  }
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
    if (src is List && src.length >= 2) {
      return Coordinate(lat: _toDouble(src[0]), lng: _toDouble(src[1]));
    }
    if (src is String) {
      final parts = src
          .split(RegExp(r'[,\s;]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) return Coordinate(lat: lat, lng: lng);
      }
    }
    try {
      final dyn = src as dynamic;
      final latV = dyn.latitude;
      final lngV = dyn.longitude;
      if (latV != null && lngV != null) {
        return Coordinate(lat: _toDouble(latV), lng: _toDouble(lngV));
      }
    } catch (_) {}
    return const Coordinate(lat: 0.0, lng: 0.0);
  }

  Map<String, dynamic> toJson() => {'latitude': lat, 'longitude': lng};

  Coordinate copyWith({double? lat, double? lng}) =>
      Coordinate(lat: lat ?? this.lat, lng: lng ?? this.lng);

  @override
  String toString() => 'Coordinate(latitude: $lat, longitude: $lng)';
}

class POI {
  final double rating;
  final String name;
  final String description;
  final List<String> keywords;
  final String imagePath;
  final Coordinate coordinate;

  const POI({
    required this.rating,
    required this.name,
    required this.description,
    required this.keywords,
    required this.imagePath,
    required this.coordinate,
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    final rating = _toDouble(json['rating'] ?? json['rate'] ?? 0);
    final name = (json['name'] ?? '').toString();
    final description = (json['description'] ?? json['desc'] ?? '').toString();
    final keywords = _toStringList(
      json['keywords'] ?? json['keyword'] ?? json['tags'],
    );
    final imagePath =
        (json['imagePath'] ??
                json['imagepath'] ??
                json['image'] ??
                json['photo'] ??
                '')
            .toString();
    final coordinate = Coordinate.fromJson(
      json['coordinate'] ??
          json['coords'] ??
          json['location'] ??
          json['latlng'] ??
          json['geo'] ??
          json['geopoint'],
    );
    return POI(
      rating: rating,
      name: name,
      description: description,
      keywords: keywords,
      imagePath: imagePath,
      coordinate: coordinate,
    );
  }

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'name': name,
    'description': description,
    'keywords': keywords,
    'imagePath': imagePath,
    'coordinate': coordinate.toJson(),
  };

  POI copyWith({
    double? rating,
    String? name,
    String? description,
    List<String>? keywords,
    String? imagePath,
    Coordinate? coordinate,
  }) {
    return POI(
      rating: rating ?? this.rating,
      name: name ?? this.name,
      description: description ?? this.description,
      keywords: keywords ?? this.keywords,
      imagePath: imagePath ?? this.imagePath,
      coordinate: coordinate ?? this.coordinate,
    );
  }

  @override
  String toString() =>
      'POI(name: $name, rating: $rating, coordinate: $coordinate)';
}

extension POIFromGooglePlaces on POI {
  POI fromGooglePlacesPlace(GooglePlace place) {
    return POI(
      rating: place.rating,
      name: place.name,
      description: place.vicinity,
      keywords: place.types,
      imagePath: '',
      coordinate: place.geometry?.location ?? const Coordinate(lat: 0, lng: 0),
    );
  }
}

class RouteModel {
  final String name;
  final String description;
  final List<String> keywords;
  final double distance;
  final double duration;
  final Difficulty difficulty;
  final List<POI> pointsofinterest;

  const RouteModel({
    required this.name,
    required this.description,
    required this.keywords,
    required this.distance,
    required this.difficulty,
    required this.duration,
    required this.pointsofinterest,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final rawPois =
        json['pointsofinterest'] ??
        json['pointsOfInterest'] ??
        json['pois'] ??
        json['points_of_interest'] ??
        <dynamic>[];
    final List<POI> pois = <POI>[];
    if (rawPois is List) {
      for (final item in rawPois) {
        if (item == null) continue;
        if (item is Map<String, dynamic>) {
          pois.add(POI.fromJson(item));
        } else if (item is Map) {
          pois.add(POI.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map) {
              pois.add(POI.fromJson(Map<String, dynamic>.from(decoded)));
            }
          } catch (_) {}
        }
      }
    }
    final name = (json['name'] ?? '').toString();
    final description = (json['description'] ?? json['desc'] ?? '').toString();
    final keywords = _toStringList(json['keywords'] ?? json['tags']);
    final distance = _toDouble(
      json['distance'] ?? json['length'] ?? json['dist'] ?? 0,
    );
    final duration = _toDouble(json['duration'] ?? json['time'] ?? 0);
    final difficulty = _difficultyFromString(json['difficulty']?.toString());

    return RouteModel(
      name: name,
      description: description,
      keywords: keywords,
      distance: distance,
      difficulty: difficulty,
      pointsofinterest: pois,
      duration: duration,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'keywords': keywords,
    'distance': distance,
    'difficulty': _difficultyToString(difficulty),
    'duration': duration.toString(),
    'pointsofinterest': pointsofinterest.map((p) => p.toJson()).toList(),
  };

  RouteModel copyWith({
    String? name,
    String? description,
    List<String>? keywords,
    double? distance,
    double? duration,
    Difficulty? difficulty,
    List<POI>? pointsofinterest,
  }) {
    return RouteModel(
      name: name ?? this.name,
      description: description ?? this.description,
      keywords: keywords ?? this.keywords,
      distance: distance ?? this.distance,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      pointsofinterest: pointsofinterest ?? this.pointsofinterest,
    );
  }

  @override
  String toString() =>
      'RouteModel(name: $name, distance: $distance, difficulty: ${_difficultyToString(difficulty)})';
}

class Location {
  final String address;
  final Coordinate coordinate;

  const Location({required this.address, required this.coordinate});

  factory Location.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] ?? '').toString();
    final coordinate = Coordinate.fromJson(
      json['coordinate'] ??
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
      address: 'Sem Endereço',
      coordinate: Coordinate(lat: latitude, lng: longitude),
    );
  }
}
