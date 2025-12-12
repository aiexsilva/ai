import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/google_places_models.dart';
import 'package:route_finder/logic/helpers.dart';

import 'package:route_finder/logic/models.dart';
import 'package:route_finder/logic/providers.dart';

import 'package:route_finder/pages/routes/route_creation.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
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

  double _value = 2;
  void _onChanged(double value) {
    setState(() {
      _value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRoutesAsync = ref.watch(userRoutesProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacings.xl),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Good ${DateTime.now().hour < 12
                              ? "morning"
                              : DateTime.now().hour < 18
                              ? "afternoon"
                              : "evening"}!",
                          variant: AppTextVariant.title,
                          weightOverride: FontWeight.w500,
                          colorOverride: AppColor.textMuted,
                        ),
                        SizedBox(height: AppSpacings.sm),
                        AppText(
                          "Where to today?",
                          variant: AppTextVariant.heading,
                          weightOverride: FontWeight.w600,
                          colorOverride: AppColor.textPrimary,
                        ),
                      ],
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        ref.read(navigationIndexProvider.notifier).setIndex(3);
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

                Padding(
                  padding: const EdgeInsets.only(top: AppSpacings.lg),
                  child: Divider(height: 1, color: Colors.grey[100]),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacings.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.6, 1],
                            colors: [AppColor.primary, Colors.amber],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacings.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.sparkle300,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: AppSpacings.md),
                                  AppText(
                                    "Start Adventure",
                                    variant: AppTextVariant.body,
                                    colorOverride: Colors.white,
                                  ),
                                ],
                              ),

                              SizedBox(height: AppSpacings.md),

                              AppText(
                                "Create Your Perfect Route",
                                variant: AppTextVariant.title,
                                colorOverride: Colors.white,
                                weightOverride: FontWeight.w700,
                              ),

                              SizedBox(height: AppSpacings.lg),

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
                                        colorOverride: Colors.white,
                                      ),
                                      Positioned(
                                        right: AppSpacings.lg,
                                        child: Slider(
                                          value: _value,
                                          onChanged: _onChanged,
                                          min: 1,
                                          max: 10,
                                          thumbColor: Colors.white,
                                          activeColor: Colors.white,
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
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColor.primary,
                                  leading: RotationTransition(
                                    turns: _animation,
                                    child: Icon(
                                      LucideIcons.wandSparkles300,
                                      size: 24,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: AppSpacings.xl),
                      Row(
                        children: [
                          AppText(
                            "Your routes",
                            variant: AppTextVariant.heading,
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(navigationIndexProvider.notifier)
                                  .setIndex(1);
                            },
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
                      userRoutesAsync.when(
                        data: (routes) {
                          debugPrint("Routes: ${routes.length}");

                          if (routes.isEmpty) {
                            return const Center(
                              child: AppText(
                                "No routes found",
                                variant: AppTextVariant.body,
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacings.lg,
                            children: [
                              for (int i = 0; i < routes.length; i += 2)
                                if (i + 1 < routes.length)
                                  Row(
                                    spacing: AppSpacings.lg,
                                    children: [
                                      Expanded(
                                        child: SavedRouteCard(route: routes[i]),
                                      ),
                                      Expanded(
                                        child: SavedRouteCard(
                                          route: routes[i + 1],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  SavedRouteCard(route: routes[i]),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
