import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/models.dart';
import 'package:route_finder/pages/navigation/main_scaffold.dart';
import 'package:route_finder/logic/firebase_helper.dart';

class RateRoutePage extends StatefulWidget {
  final RouteModel route;
  const RateRoutePage({super.key, required this.route});

  @override
  State<RateRoutePage> createState() => _RateRoutePageState();
}

class _RateRoutePageState extends State<RateRoutePage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  int _rating = -1;
  final TextEditingController _experienceController = TextEditingController();

  late List<int> waypointRatings;
  late List<TextEditingController> waypointExperienceControllers;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    waypointRatings = List.filled(widget.route.waypoints.length, -1);
    waypointExperienceControllers = List.generate(
      widget.route.waypoints.length,
      (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _experienceController.dispose();
    for (var controller in waypointExperienceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacings.lg,
              vertical: AppSpacings.xl,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => context.pushReplacementAnimated(
                        MainScaffold(),
                        animation: NavigationAnimation.fadeScale,
                      ),
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
                          LucideIcons.x300,
                          color: AppColor.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _logoAnimation.value),
                        child: child,
                      );
                    },
                    child: Image.asset("assets/images/logo.png", height: 150),
                  ),

                  SizedBox(height: AppSpacings.xl),

                  AppText(
                    'Route Completed! 🎉',
                    variant: AppTextVariant.heading,
                  ),

                  SizedBox(height: AppSpacings.md),

                  AppText(
                    'Amazing work on finishing ${widget.route.name}!',
                    variant: AppTextVariant.body,
                    textAlign: TextAlign.center,
                    colorOverride: AppColor.textMuted,
                  ),

                  SizedBox(height: AppSpacings.xxl),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(kRadiusLg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacings.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AppText(
                            'Rate this route',
                            variant: AppTextVariant.title,
                          ),

                          SizedBox(height: AppSpacings.md),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rating = index;
                                  });
                                },
                                child: Icon(
                                  _rating >= index
                                      ? Icons.star
                                      : Icons.star_outline,
                                  color: _rating >= index
                                      ? AppColor.primary
                                      : AppColor.textMuted,
                                  size: 48,
                                ),
                              );
                            }),
                          ),

                          SizedBox(height: AppSpacings.xl),

                          AppTextInput(
                            label: "",
                            placeholder: "Share your experience (optional)",
                            controller: _experienceController,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacings.xxl),

                  ...widget.route.waypoints.map(
                    (waypoint) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kRadiusLg),
                      ),
                      margin: const EdgeInsets.only(bottom: AppSpacings.lg),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacings.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
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

                            SizedBox(height: AppSpacings.lg),

                            AppText(
                              'Rate this place',
                              variant: AppTextVariant.title,
                            ),

                            SizedBox(height: AppSpacings.md),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      waypointRatings[widget.route.waypoints
                                              .indexOf(waypoint)] =
                                          index;
                                    });
                                  },
                                  child: Icon(
                                    waypointRatings[widget.route.waypoints
                                                .indexOf(waypoint)] >=
                                            index
                                        ? Icons.star
                                        : Icons.star_outline,
                                    color:
                                        waypointRatings[widget.route.waypoints
                                                .indexOf(waypoint)] >=
                                            index
                                        ? AppColor.primary
                                        : AppColor.textMuted,
                                    size: 48,
                                  ),
                                );
                              }),
                            ),

                            SizedBox(height: AppSpacings.xl),

                            AppTextInput(
                              label: "",
                              placeholder: "Share your experience (optional)",
                              controller:
                                  waypointExperienceControllers[widget
                                      .route
                                      .waypoints
                                      .indexOf(waypoint)],
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacings.lg),

                  AppButton(label: "Submit Ratings", onTap: _submitRatings),

                  SizedBox(
                    height:
                        MediaQuery.of(context).viewInsets.bottom +
                        AppSpacings.xl,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRatings() async {
    if (_rating == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate the route first!')),
      );
      return;
    }

    try {
      // Collect place ratings
      List<Map<String, dynamic>> placesRatings = [];
      for (int i = 0; i < widget.route.waypoints.length; i++) {
        final waypoint = widget.route.waypoints[i];
        final rating = waypointRatings[i];
        final review = waypointExperienceControllers[i].text;

        if (rating > -1) {
          placesRatings.add({
            'placeId': waypoint.placeId,
            'rating': rating + 1,
            'review': review,
          });
        }
      }

      await FirebaseHelper.rateRoute(
        routeId: widget.route.id ?? '',
        routeRating: _rating + 1,
        routeReview: _experienceController.text,
        placesRatings: placesRatings,
      );

      if (mounted) {
        context.pushReplacementAnimated(
          MainScaffold(),
          animation: NavigationAnimation.fadeScale,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting ratings: $e')));
      }
    }
  }
}
