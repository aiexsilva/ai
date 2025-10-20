import 'package:flutter/material.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/models.dart';

class RoutesListMapViewPage extends StatefulWidget {
  final List<RouteModel> routes;
  const RoutesListMapViewPage({super.key, required this.routes});

  @override
  State<RoutesListMapViewPage> createState() => _RoutesListMapViewPageState();
}

class _RoutesListMapViewPageState extends State<RoutesListMapViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: AppSpacings.lg),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.popAnimated(),
                    child: Container(
                      width: 54,
                      height: 54,
                      color: Colors.transparent,
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  AppText('Map View', variant: AppTextVariant.heading),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacings.lg),
              child: Divider(height: 1, color: Colors.grey[100]),
            ),
            Expanded(child: TripMapCard(route: widget.routes)),
          ],
        ),
      ),
    );
  }
}
