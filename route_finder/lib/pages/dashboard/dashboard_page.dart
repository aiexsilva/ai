import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/google_places_models.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/models.dart';

import 'package:route_finder/pages/landing/landing_page.dart';
import 'package:route_finder/pages/map_test.dart';
import 'package:route_finder/pages/routes/route_creation.dart';
import 'package:route_finder/pages/routes/routes_list_map_view_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final List<String> _selectedChips = [];
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = false;

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
    _controller.dispose();
    super.dispose();
  }

  List<RouteModel> get _routes => [
    RouteModel(
      name: "Porto's Historic Heart",
      duration: 120,
      description:
          "A walking tour of Porto's most iconic landmarks, from the world's most beautiful bookshop to the top of its famous tower.",
      keywords: ["history", "architecture", "books", "views"],
      distance: 2.1,
      difficulty: Difficulty.easy,
      pointsofinterest: [
        POI(
          rating: 4.7,
          name: "Livraria Lello",
          description:
              "An iconic and ornate bookstore, often cited as one of the most beautiful in the world.",
          keywords: ["books", "architecture", "art nouveau"],
          imagePath: "assets/images/museum.jpg",
          coordinate: Coordinate(lat: 41.1469, lng: -8.6149),
        ),
        POI(
          rating: 4.6,
          name: "Clérigos Tower",
          description:
              "A baroque bell tower offering panoramic views of Porto after a climb of 240 steps.",
          keywords: ["tower", "viewpoint", "baroque"],
          imagePath: "assets/images/cathedral.jpg",
          coordinate: Coordinate(lat: 41.1456, lng: -8.6148),
        ),
        POI(
          rating: 4.8,
          name: "São Francisco Church",
          description:
              "A stunning example of Gothic architecture with an incredibly rich gold-leaf Baroque interior.",
          keywords: ["church", "gold", "gothic", "baroque"],
          imagePath: "assets/images/cathedral.jpg",
          coordinate: Coordinate(lat: 41.1410, lng: -8.6159),
        ),
      ],
    ),
    RouteModel(
      name: "Douro Riverside Gardens",
      duration: 90,
      description:
          "A relaxing walk through lush gardens with breathtaking views over the Douro River and the city.",
      keywords: ["nature", "gardens", "scenic", "river"],
      distance: 3.0,
      difficulty: Difficulty.easy,
      pointsofinterest: [
        POI(
          rating: 4.6,
          name: "Crystal Palace Gardens",
          description:
              "Landscaped gardens with roaming peacocks and incredible panoramic views of the Douro.",
          keywords: ["gardens", "views", "nature", "peacocks"],
          imagePath: "assets/images/park.jpg",
          coordinate: Coordinate(lat: 41.1483, lng: -8.6256),
        ),
        POI(
          rating: 4.5,
          name: "Passeio Alegre Garden",
          description:
              "A charming garden where the Douro River meets the Atlantic, featuring fountains and a mini-golf course.",
          keywords: ["gardens", "fountain", "river mouth"],
          imagePath: "assets/images/gardens.jpg",
          coordinate: Coordinate(lat: 41.1475, lng: -8.6698),
        ),
      ],
    ),
  ];

  double _value = 2;
  void _onChanged(double value) {
    setState(() {
      _value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceLight,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: AppSpacings.md,
        children: [
          GestureDetector(
            child: Container(
              width: 54,
              height: 54,

              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kPrimary, kPrimaryVariant]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(LucideIcons.plus300, color: Colors.white, size: 24),
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.search300,
                  color: kTextPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        left: false,
        right: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: AppSpacings.lg),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimaryVariant],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacings.lg),
                      child: AppText(
                        'RF',
                        variant: AppTextVariant.title,
                        colorOverride: Colors.white,
                      ),
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      FirebaseHelper.signOut();
                      context.pushAnimated(LandingPage());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[100] ?? Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacings.lg),
                        child: Center(
                          child: Icon(
                            LucideIcons.user300,
                            color: kTextPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: AppSpacings.lg),
              child: Divider(height: 1, color: Colors.grey[100]),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacings.lg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacings.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SearchChipsBar(
                          placeholder: "Ex: Culture, Nature, Art...",
                          onChipAdded: (value) {
                            setState(() => _selectedChips.add(value));
                          },
                          onChipRemoved: (value) {
                            setState(() => _selectedChips.remove(value));
                          },
                          suggestions: [
                            "Culture",
                            "Nature",
                            "Art",
                            "History",
                            "Food",
                            "Architecture",
                            "Parks",
                            "Museums",
                            "Street Art",
                            "Landmarks",
                            "Shopping",
                            "Nightlife",
                            "Scenic Views",
                            "Waterfronts",
                            "Gardens",
                          ],
                        ),
                        if (_selectedChips.isNotEmpty) ...[
                          SizedBox(height: AppSpacings.lg),
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.centerLeft,
                              children: [
                                AppText(
                                  "Radius: ${_value.toStringAsFixed(1)}km",
                                  variant: AppTextVariant.title,
                                ),
                                Positioned(
                                  right: AppSpacings.lg,
                                  child: Slider(
                                    value: _value,
                                    onChanged: _onChanged,
                                    min: 1,
                                    max: 10,
                                    thumbColor: kPrimary,
                                    activeColor: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSpacings.lg),
                          AppButton(
                            label: "Generate Routes",
                            fullWidth: true,
                            enabled: !_isLoading,
                            onTap: _generateRoutes,
                            leading: RotationTransition(
                              turns: _animation,
                              child: Icon(
                                LucideIcons.wandSparkles300,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: AppSpacings.xl),
                        Row(
                          children: [
                            AppText(
                              "Routes near you",
                              variant: AppTextVariant.heading,
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () => context.pushAnimated(
                                RoutesListMapViewPage(routes: _routes),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kBgLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[100] ?? Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacings.lg),
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.map300,
                                      color: kTextPrimary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacings.lg),
                        Column(
                          spacing: AppSpacings.lg,
                          children: _routes
                              .map((route) => RouteCard(route: route))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateRoutes() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _controller.repeat();

    try {
      Position? location;

      try {
        location = await getCurrentLocation();
      } catch (e) {
        if (!context.mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }

      final startLocation = location.toLocation();

      final result = await FirebaseHelper.createRouteWithKeywords(
        start: startLocation,
        keywords: _selectedChips,
        radius: _value.toInt() * 1000,
      );

      GooglePlacesResponse response = GooglePlacesResponse.fromJson(result);

      List<GooglePlace> uniquePlaces = response.results.toSet().toList();

      // for each place, say the name and thevicinity
      for (var place in uniquePlaces) {
        debugPrint(place.name);
        debugPrint(place.vicinity);
      }

      context.pushAnimated(
        RouteCreationPage(poiList: uniquePlaces),
        animation: NavigationAnimation.fadeScale,
      );

      if (!context.mounted) return;
      setState(() => _isLoading = false);
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isLoading = false);
      }
    }
  }
}
