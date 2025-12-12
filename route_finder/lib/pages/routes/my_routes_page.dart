import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/models.dart';
import 'package:route_finder/logic/providers.dart';

class MyRoutesPage extends ConsumerStatefulWidget {
  const MyRoutesPage({super.key});

  @override
  ConsumerState<MyRoutesPage> createState() => _MyRoutesPageState();
}

class _MyRoutesPageState extends ConsumerState<MyRoutesPage> {
  int _selectedTab = 1;

  @override
  Widget build(BuildContext context) {
    final userRoutesAsync = ref.watch(userRoutesProvider);

    final allRoutes = userRoutesAsync.value ?? [];
    final activeCount = allRoutes.where((r) => r.status == 'active').length;
    final savedCount = allRoutes.where((r) => r.status == 'planned').length;
    final completedCount = allRoutes
        .where((r) => r.status == 'completed')
        .length;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacings.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText("My Routes", variant: AppTextVariant.heading),
                  const SizedBox(height: AppSpacings.md),
                  AppText(
                    "Your travel adventures",
                    variant: AppTextVariant.body,
                    colorOverride: AppColor.textMuted,
                  ),
                  const SizedBox(height: AppSpacings.xl),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColor.backgroundDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(AppSpacings.md),
                    child: Row(
                      children: [
                        _TabButton(
                          label: "Active",
                          count: activeCount,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        _TabButton(
                          label: "Saved",
                          count: savedCount,
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                        _TabButton(
                          label: "Completed",
                          count: completedCount,
                          isSelected: _selectedTab == 2,
                          onTap: () => setState(() => _selectedTab = 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: userRoutesAsync.when(
                data: (routes) {
                  final activeRoutes = routes
                      .where((r) => r.status == 'active')
                      .toList();
                  final savedRoutes = routes
                      .where((r) => r.status == 'planned')
                      .toList();
                  final completedRoutes = routes
                      .where((r) => r.status == 'completed')
                      .toList();

                  // Update tab counts (this is a bit hacky inside build, but works for now)
                  // Ideally we'd compute these before building the tabs, but the tabs are above.
                  // Since we are inside the data callback, we can't easily update the parent widgets without a rebuild.
                  // However, we can just use these lists to determine what to show.
                  // To update the counts in the tabs, we need to move the filtering up or access it differently.
                  // For now, let's just use the filtered lists for display and we will fix the tab counts in a second pass or by restructuring.

                  // Actually, let's restructure slightly to get the counts for the tabs.
                  // We can't easily do that because the tabs are outside the AsyncValue.when.
                  // So we should wrap the whole Column content in the AsyncValue.when or handle it differently.
                  // But the user wants the tabs to show counts.
                  // Let's wrap the whole Scaffold body content (except header) or just the tabs+list in the AsyncValue.

                  List<RouteModel> currentRoutes;
                  if (_selectedTab == 0) {
                    currentRoutes = activeRoutes;
                  } else if (_selectedTab == 1) {
                    currentRoutes = savedRoutes;
                  } else {
                    currentRoutes = completedRoutes;
                  }

                  if (currentRoutes.isEmpty) {
                    String message;
                    if (_selectedTab == 0) {
                      message = "No active routes";
                    } else if (_selectedTab == 1)
                      message = "No saved routes yet";
                    else
                      message = "No completed routes";

                    return Center(
                      child: AppText(
                        message,
                        variant: AppTextVariant.body,
                        colorOverride: AppColor.textMuted,
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacings.lg,
                      vertical: AppSpacings.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacings.lg,
                      children: [
                        for (int i = 0; i < currentRoutes.length; i += 2)
                          if (i + 1 < currentRoutes.length)
                            Row(
                              spacing: AppSpacings.lg,
                              children: [
                                Expanded(
                                  child: SavedRouteCard(
                                    route: currentRoutes[i],
                                  ),
                                ),
                                Expanded(
                                  child: SavedRouteCard(
                                    route: currentRoutes[i + 1],
                                  ),
                                ),
                              ],
                            )
                          else
                            SavedRouteCard(route: currentRoutes[i]),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                label,
                variant: AppTextVariant.label,
                colorOverride: isSelected
                    ? AppColor.textPrimary
                    : AppColor.textMuted,
                weightOverride: FontWeight.w500,
              ),
              if (count > 0) ...[
                const SizedBox(width: AppSpacings.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacings.md),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColor.primary : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: AppText(
                    count.toString(),
                    variant: AppTextVariant.small,
                    colorOverride: Colors.white,
                    textAlign: TextAlign.center,
                    weightOverride: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
