import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:route_finder/components/components.dart';

import 'package:route_finder/logic/providers.dart';

class ExplorerPage extends ConsumerWidget {
  const ExplorerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityRoutesAsync = ref.watch(communityRoutesProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacings.lg),
            child: Divider(height: 1, color: Colors.grey[100]),
          ),
          Expanded(
            child: communityRoutesAsync.when(
              data: (routes) {
                return TripMapCard(
                  route: routes,
                  onSave: (route) async {
                    try {
                      AppToast.show(context, "Saving route...");

                      final result =
                          await FirebaseFunctions.instanceFor(
                            region: 'europe-southwest1',
                          ).httpsCallable('saveCommunityRoute').call({
                            'publicRouteId': route.id,
                          });

                      if (result.data['success'] == true) {
                        AppToast.show(context, "Route saved successfully!");
                        ref.invalidate(userRoutesProvider);
                      } else {
                        AppToast.show(context, "Failed to save route.");
                      }
                    } catch (e) {
                      AppToast.show(context, "Error saving route: $e");
                    }
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              ),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
