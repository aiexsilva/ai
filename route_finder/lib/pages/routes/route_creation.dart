import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/google_places_models.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/models.dart';
import 'package:route_finder/pages/dashboard/dashboard_page.dart';

class RouteCreationPage extends ConsumerStatefulWidget {
  final List<GooglePlace> poiList;
  const RouteCreationPage({super.key, required this.poiList});

  @override
  ConsumerState<RouteCreationPage> createState() => _RouteCreationPageState();
}

class _RouteCreationPageState extends ConsumerState<RouteCreationPage>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _cardSwiperController = CardSwiperController();
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = false;

  bool allCardsSwiped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _cardSwiperController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var selectedPlaces = ref.watch(selectedPlacesProvider);

    return Scaffold(
      backgroundColor: kSurfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacings.xl),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacings.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          ref
                              .read(selectedPlacesProvider.notifier)
                              .clearPlaces();
                          ref.invalidate(selectedPlacesProvider);
                          context.popAnimated();
                        },
                        child: SizedBox(
                          height: 44,
                          width: 44,
                          child: Icon(LucideIcons.arrowLeft, color: kTextMuted),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              'Building route',
                              variant: AppTextVariant.body,
                              weightOverride: FontWeight.w700,
                            ),
                            SizedBox(height: AppSpacings.md),
                            AppText(
                              '${selectedPlaces.places.length} places selected',
                              variant: AppTextVariant.caption,
                              colorOverride: kTextMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (selectedPlaces.places.isNotEmpty) ...[
                SizedBox(height: AppSpacings.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacings.lg,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: selectedPlaces.places.map((place) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacings.md),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: kAccent.withValues(alpha: 0.1),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacings.md + AppSpacings.sm,
                              vertical: AppSpacings.sm,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin300,
                                  color: kAccent,
                                  size: 20,
                                ),
                                SizedBox(width: AppSpacings.md),
                                AppText(
                                  place.name,
                                  variant: AppTextVariant.label,
                                  colorOverride: kAccent,
                                  weightOverride: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              if (!allCardsSwiped && widget.poiList.isNotEmpty)
                Expanded(
                  child: CardSwiper(
                    cardsCount: widget.poiList.length,
                    controller: _cardSwiperController,
                    numberOfCardsDisplayed: widget.poiList.length > 1 ? 2 : 1,
                    isLoop: false,
                    allowedSwipeDirection: AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                    ),
                    onSwipe: (previousIndex, currentIndex, direction) {
                      debugPrint("Swiping angle: ${direction.angle}");
                      debugPrint("currentIndex: $currentIndex");
                      debugPrint("previousIndex: $previousIndex");
                      if (direction == CardSwiperDirection.right) {
                        Future.microtask(() {
                          ref
                              .read(selectedPlacesProvider.notifier)
                              .addPlace(widget.poiList[previousIndex]);
                        });
                      }

                      if (previousIndex == widget.poiList.length - 1) {
                        setState(() {
                          allCardsSwiped = true;
                        });
                      }

                      return true;
                    },
                    cardBuilder:
                        (
                          context,
                          index,
                          horizontalOffsetPercentage,
                          verticalOffsetPercentage,
                        ) {
                          debugPrint(
                            horizontalOffsetPercentage.toDouble().toString(),
                          );
                          return PlaceCard(
                            place: widget.poiList[index],
                            swipeProgress:
                                (horizontalOffsetPercentage.toDouble() / 360),
                          );
                        },
                  ),
                ),
              if (allCardsSwiped) ...[
                if (selectedPlaces.places.isEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacings.lg,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.frown300, size: 64, color: kPrimary),
                          SizedBox(height: AppSpacings.lg),
                          AppText(
                            'Route not created',
                            variant: AppTextVariant.heading,
                            colorOverride: kTextPrimary,
                            weightOverride: FontWeight.w600,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacings.md),
                          AppText(
                            'Please select at least one\n place to create a route',
                            variant: AppTextVariant.body,
                            colorOverride: kTextMuted,
                            weightOverride: FontWeight.w400,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacings.lg),
                          AppButton(
                            label: "Try Again",
                            onTap: () {
                              context.pushReplacementAnimated(
                                DashboardPage(),
                                animation: NavigationAnimation.fade,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (selectedPlaces.places.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacings.lg,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.sparkle, size: 64, color: kPrimary),
                          SizedBox(height: AppSpacings.lg),
                          AppText(
                            'Route created!',
                            variant: AppTextVariant.heading,
                            colorOverride: kTextPrimary,
                            weightOverride: FontWeight.w600,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacings.md),
                          AppText(
                            'You selected ${selectedPlaces.places.length} amazing place${selectedPlaces.places.length > 1 ? 's' : ''}',
                            variant: AppTextVariant.body,
                            colorOverride: kTextMuted,
                            weightOverride: FontWeight.w400,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacings.lg),
                          AppButton(
                            label: "Create Route",
                            enabled: !_isLoading,
                            leading: RotationTransition(
                              turns: _animation,
                              child: Icon(
                                LucideIcons.wandSparkles300,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            onTap: _finalizeRoute,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (widget.poiList.isEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacings.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.frown300, size: 64, color: kPrimary),
                        SizedBox(height: AppSpacings.lg),
                        AppText(
                          'No places found',
                          variant: AppTextVariant.heading,
                          colorOverride: kTextPrimary,
                          weightOverride: FontWeight.w600,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacings.md),
                        AppText(
                          'We couldn\'t find any\nplaces for your search',
                          variant: AppTextVariant.body,
                          colorOverride: kTextMuted,
                          weightOverride: FontWeight.w400,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacings.lg),
                        AppButton(
                          label: "Try Again",
                          onTap: () {
                            context.pushReplacementAnimated(
                              DashboardPage(),
                              animation: NavigationAnimation.fade,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finalizeRoute() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _controller.repeat();

    try {
      await FirebaseHelper.finalizeRouteCreation(
        selectedPlaces: ref.read(selectedPlacesProvider.notifier)._places,
      );
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isLoading = false);
      }
    }
  }
}

class PlaceCard extends StatelessWidget {
  final GooglePlace place;
  final double swipeProgress;

  const PlaceCard({
    super.key,
    required this.place,
    required this.swipeProgress,
  });

  @override
  Widget build(BuildContext context) {
    String photoUrl = "";
    if (place.photos.isNotEmpty) {
      var photoName = place.photos[0].name;
      photoUrl =
          "https://places.googleapis.com/v1/$photoName/media?maxWidthPx=400&key=${dotenv.env['GOOGLE_PLACES_API_KEY'] ?? ''}";
    }

    final double threshold = 0.3;

    final double addOpacity = (swipeProgress > 0)
        ? (swipeProgress / threshold).clamp(0.0, 1.0)
        : 0.0;

    final double notAddOpacity = (swipeProgress < 0)
        ? (swipeProgress.abs() / threshold).clamp(0.0, 1.0)
        : 0.0;

    final double cardOpacity = (1 - swipeProgress.abs()).clamp(0.2, 1.0);

    return Stack(
      children: [
        Opacity(
          opacity: cardOpacity,
          child: Card(
            color: kBgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacings.xl),
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          : Container(
                              color: kBgLight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.image300,
                                      size: 100,
                                      color: kTextMuted,
                                    ),
                                    AppText(
                                      'No image available',
                                      variant: AppTextVariant.body,
                                      colorOverride: kTextMuted,
                                      weightOverride: FontWeight.w400,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, .95],
                              colors: [
                                kBgLight.withValues(alpha: .0),
                                kBgLight,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacings.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: place.types.map((type) {
                              if (type.contains("point_of_interest")) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacings.md,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: kPrimary.withValues(alpha: 0.1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacings.md + AppSpacings.sm,
                                    vertical: AppSpacings.sm,
                                  ),
                                  child: AppText(
                                    type
                                        .replaceAll("_", " ")
                                        .capitalizeFirstLetters(),
                                    variant: AppTextVariant.label,
                                    colorOverride: kPrimary,
                                    weightOverride: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacings.lg),
                      AppText(
                        place.name,
                        variant: AppTextVariant.heading,
                        colorOverride: kTextPrimary,
                        weightOverride: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacings.md),
                      if (place.summary != null && place.summary!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacings.md,
                          ),
                          child: AppText(
                            place.summary ?? "No summary available",
                            variant: AppTextVariant.body,
                            colorOverride: kTextMuted,
                            weightOverride: FontWeight.w400,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(height: AppSpacings.xl),
                      FutureBuilder(
                        future: getCurrentLocation(),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.hasData) {
                            final Position currentLocation =
                                asyncSnapshot.data!;
                            final Coordinate currentLocationCoordinate =
                                Coordinate(
                                  lat: currentLocation.latitude,
                                  lng: currentLocation.longitude,
                                );

                            return Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin300,
                                  color: kTextMuted,
                                  size: 20,
                                ),
                                SizedBox(width: AppSpacings.sm),
                                AppText(
                                  "${(calculateDistance(currentLocationCoordinate, Coordinate(lat: (place.geometry?.location.lat ?? 0), lng: (place.geometry?.location.lng ?? 0))) / 1000).toStringAsFixed(2)}km",
                                  variant: AppTextVariant.label,
                                  colorOverride: kTextMuted,
                                  weightOverride: FontWeight.w400,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(width: AppSpacings.md),
                                Icon(
                                  LucideIcons.clock3300,
                                  color: kTextMuted,
                                  size: 20,
                                ),
                                SizedBox(width: AppSpacings.sm),
                                AppText(
                                  place.openingHours?.openNow == true
                                      ? "Open now"
                                      : "Closed",
                                  variant: AppTextVariant.label,
                                  colorOverride: kTextMuted,
                                  weightOverride: FontWeight.w400,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: AppSpacings.xxl * 2,
          right: AppSpacings.lg,
          child: Transform.rotate(
            angle: 0.25,
            child: Opacity(
              opacity: addOpacity,
              child: Container(
                padding: EdgeInsets.all(AppSpacings.md),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 4.0),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.withValues(alpha: 0.2),
                ),
                child: AppText(
                  "LIKE",
                  variant: AppTextVariant.title,
                  weightOverride: FontWeight.w900,
                  colorOverride: Colors.green,
                ),
              ),
            ),
          ),
        ),
        // Not Add Overlay
        Positioned(
          top: AppSpacings.xl,
          left: AppSpacings.lg,
          child: Transform.rotate(
            angle: -0.25,
            child: Opacity(
              opacity: notAddOpacity,
              child: Container(
                padding: EdgeInsets.all(AppSpacings.md),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 4.0),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.withValues(alpha: 0.2),
                ),
                child: AppText(
                  "NOPE",
                  variant: AppTextVariant.title,
                  weightOverride: FontWeight.w900,
                  colorOverride: Colors.red,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSpacings.lg,
          right: AppSpacings.lg,
          child: Container(
            decoration: BoxDecoration(
              color: kBgLight,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacings.md,
              vertical: AppSpacings.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: AppSpacings.sm),
                AppText(
                  place.rating.toStringAsFixed(1),
                  variant: AppTextVariant.title,
                  colorOverride: kTextPrimary,
                  weightOverride: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SelectedPlacesNotifier extends ChangeNotifier {
  final List<GooglePlace> _places = [];

  List<GooglePlace> get places => List.unmodifiable(_places);

  void addPlace(GooglePlace place) {
    _places.add(place);
    debugPrint("Added place: ${place.name}");
    notifyListeners();
  }

  void removePlace(GooglePlace place) {
    _places.remove(place);
    notifyListeners();
  }

  void clearPlaces() {
    _places.clear();
    notifyListeners();
  }

  void setPlaces(List<GooglePlace> newPlaces) {
    _places
      ..clear()
      ..addAll(newPlaces);
    notifyListeners();
  }
}

final selectedPlacesProvider = ChangeNotifierProvider<SelectedPlacesNotifier>((
  ref,
) {
  return SelectedPlacesNotifier();
});
