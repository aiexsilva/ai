import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/pages/authentication/login_page.dart';
import 'package:route_finder/pages/authentication/register_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // // ShadowedLottie(name: "logo", height: 120,),
            // // SizedBox(height: AppSpacings.xxl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacings.lg),
                child: ShadowedLottie(name: "landing", width: 250),
              ),
            ),
            SizedBox(height: AppSpacings.xl),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(AppSpacings.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppText(
                    "Discover Unique Routes",
                    variant: AppTextVariant.display,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacings.xl),
                  AppText(
                    "Pick your themes and go for a walk. Generate scenic routes in seconds.",
                    variant: AppTextVariant.body,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    colorOverride: Colors.grey,
                  ),
                  SizedBox(height: AppSpacings.xxl),
                  AppButton(
                    label: "Get Started",
                    onTap: () => context.pushAnimated(RegisterPage()),
                    leading: Icon(
                      LucideIcons.sparkles,
                      size: 24,
                      color: Colors.white,
                    ),
                    size: AppButtonSize.large,
                  ),
                  SizedBox(height: AppSpacings.md),
                  AppButton(
                    label: "I have an account",
                    onTap: () => context.pushAnimated(LoginPage()),
                    variant: AppButtonVariant.ghost,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
