import 'models.dart';

class GooglePlacesResponse {
  final List<dynamic> htmlAttributions;
  final List<GooglePlace> results;
  final String status;

  GooglePlacesResponse({
    required this.htmlAttributions,
    required this.results,
    required this.status,
  });

  factory GooglePlacesResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] ?? json['places'];
    return GooglePlacesResponse(
      htmlAttributions: json['html_attributions'] as List<dynamic>? ?? [],
      results:
          (resultsList as List<dynamic>?)
              ?.map(
                (e) =>
                    GooglePlace.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          [],
      status: json['status'] as String? ?? 'OK',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'html_attributions': htmlAttributions,
      'results': results.map((e) => e.toJson()).toList(),
      'status': status,
    };
  }
}

class GooglePlace {
  final String businessStatus;
  final Geometry? geometry;
  final String icon;
  final String iconBackgroundColor;
  final String iconMaskBaseUri;
  final String? internationalPhoneNumber;
  final String name;
  final OpeningHours? openingHours;
  final List<Photo> photos;
  final String placeId;
  final int? priceLevel;
  final double rating;
  final String reference;
  final String scope;
  final List<String> types;
  final int userRatingsTotal;
  final String vicinity;
  final String? summary;

  GooglePlace({
    required this.businessStatus,
    this.geometry,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconMaskBaseUri,
    this.internationalPhoneNumber,
    required this.name,
    this.openingHours,
    required this.photos,
    required this.placeId,
    this.priceLevel,
    required this.rating,
    required this.reference,
    required this.scope,
    required this.types,
    required this.userRatingsTotal,
    required this.vicinity,
    this.summary,
  });

  factory GooglePlace.fromJson(Map<String, dynamic> json) {
    return GooglePlace(
      businessStatus: json['businessStatus'] as String? ?? '',
      geometry: json['location'] != null
          ? Geometry(
              location: Coordinate.fromJson(json['location']),
              viewport: Viewport(
                northeast: const Coordinate(lat: 0, lng: 0),
                southwest: const Coordinate(lat: 0, lng: 0),
              ),
            )
          : null,
      icon: json['icon'] as String? ?? '',
      iconBackgroundColor: json['iconBackgroundColor'] as String? ?? '',
      iconMaskBaseUri: json['iconMaskBaseUri'] as String? ?? '',
      internationalPhoneNumber: json['internationalPhoneNumber'] as String?,
      name: (json['displayName'] as Map?)?['text'] as String? ?? '',
      openingHours: json['regularOpeningHours'] != null
          ? OpeningHours.fromJson(
              Map<String, dynamic>.from(json['regularOpeningHours'] as Map),
            )
          : null,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      placeId: json['id'] as String? ?? '',
      priceLevel: json['priceLevel'] as int?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reference: json['name'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      types:
          (json['types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      userRatingsTotal: json['userRatingCount'] as int? ?? 0,
      vicinity: json['formattedAddress'] as String? ?? '',
      summary: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_status': businessStatus,
      'geometry': geometry?.toJson(),
      'icon': icon,
      'icon_background_color': iconBackgroundColor,
      'icon_mask_base_uri': iconMaskBaseUri,
      'international_phone_number': internationalPhoneNumber,
      'name': name,
      'opening_hours': openingHours?.toJson(),
      'photos': photos.map((e) => e.toJson()).toList(),
      'placeId': placeId,
      'price_level': priceLevel,
      'rating': rating,
      'reference': reference,
      'scope': scope,
      'types': types,
      'user_ratings_total': userRatingsTotal,
      'vicinity': vicinity,
      'summary': summary,
    };
  }
}

class Geometry {
  final Coordinate location;
  final Viewport viewport;

  Geometry({required this.location, required this.viewport});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: Coordinate.fromJson(json['location']),
      viewport: Viewport.fromJson(
        Map<String, dynamic>.from(json['viewport'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'location': location.toJson(), 'viewport': viewport.toJson()};
  }
}

class Viewport {
  final Coordinate northeast;
  final Coordinate southwest;

  Viewport({required this.northeast, required this.southwest});

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      northeast: Coordinate.fromJson(json['northeast']),
      southwest: Coordinate.fromJson(json['southwest']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'northeast': northeast.toJson(), 'southwest': southwest.toJson()};
  }
}

class OpeningHours {
  final bool openNow;

  OpeningHours({required this.openNow});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(openNow: json['openNow'] as bool? ?? false);
  }

  Map<String, dynamic> toJson() {
    return {'open_now': openNow};
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
      height: json['heightPx'] as int? ?? 0,
      htmlAttributions:
          (json['authorAttributions'] as List<dynamic>?)
              ?.map((e) => (e as Map)['displayName'] as String? ?? '')
              .toList() ??
          [],
      name: json['name'] as String? ?? '',
      width: json['widthPx'] as int? ?? 0,
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
