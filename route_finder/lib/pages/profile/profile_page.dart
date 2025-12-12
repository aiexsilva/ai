import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/providers.dart';
import 'package:route_finder/pages/landing/landing_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final routes = ref.watch(userRoutesProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: user.when(
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacings.lg),
                child: Column(
                  children: [
                    // Profile Picture & Name
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        image: const DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/300'),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacings.lg),
                    AppText(
                      user.email.split("@").first,
                      variant: AppTextVariant.heading,
                    ),
                    AppText(
                      user.id,
                      variant: AppTextVariant.body,
                      colorOverride: AppColor.textMuted,
                    ),
                    const SizedBox(height: AppSpacings.xl),

                    // Stats Grid
                    routes.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: AppText("Error loading routes: $error"),
                      ),
                      data: (routes) {
                        return Column(
                          children: [
                            Row(
                              spacing: AppSpacings.md,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: LucideIcons.route,
                                    value: routes
                                        .where(
                                          (route) =>
                                              route.status == "completed",
                                        )
                                        .length
                                        .toString(),
                                    label: "Routes Completed",
                                    color: Colors.amber,
                                  ),
                                ),
                                Expanded(
                                  child: _StatCard(
                                    icon: LucideIcons.mapPin,
                                    value: routes
                                        .where(
                                          (route) => route.waypoints.isNotEmpty,
                                        )
                                        .where(
                                          (route) =>
                                              route.status == "completed",
                                        )
                                        .map((route) => route.waypoints.length)
                                        .reduce((a, b) => a + b)
                                        .toString(),
                                    label: "Places Visited",
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacings.md),

                            SizedBox(
                              width: double.infinity,
                              child: _StatCard(
                                icon: LucideIcons.footprints,
                                value:
                                    "${routes.where((route) => route.status == "completed").map((route) => route.routeData['totalDistance'] as double).reduce((a, b) => a + b).toStringAsFixed(2)} km",
                                label: "Distance Travelled",
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacings.xl),

                    // Logout Button
                    AppButton(
                      label: "Log Out",
                      onTap: () {
                        FirebaseHelper.signOut();
                        context.pushAnimated(const LandingPage());
                      },
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacings.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacings.md),
          AppText(value, variant: AppTextVariant.heading),
          AppText(
            label,
            variant: AppTextVariant.label,
            colorOverride: AppColor.textMuted,
          ),
        ],
      ),
    );
  }
}
