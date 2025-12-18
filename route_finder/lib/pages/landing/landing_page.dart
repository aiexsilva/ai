import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/pages/authentication/authentication_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _cloudController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _cloud1Animation;
  late Animation<Offset> _cloud2Animation;
  late Animation<Offset> _cloud3Animation;
  late Animation<Offset> _cloud4Animation;

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

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _cloud1Animation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(15, -5)).animate(
          CurvedAnimation(parent: _cloudController, curve: Curves.easeInOut),
        );
    _cloud2Animation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-20, 10)).animate(
          CurvedAnimation(parent: _cloudController, curve: Curves.easeInOut),
        );
    _cloud3Animation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(10, 15)).animate(
          CurvedAnimation(parent: _cloudController, curve: Curves.easeInOut),
        );
    _cloud4Animation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-15, -10)).animate(
          CurvedAnimation(parent: _cloudController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Stack(
        children: [
          Positioned(
            bottom: AppSpacings.xxl,
            left: AppSpacings.lg,
            child: AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _cloud1Animation.value,
                  child: child,
                );
              },
              child: Container(
                width: 225,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColor.backgroundSecondary,
                ),
              ),
            ),
          ),

          Positioned(
            top: AppSpacings.xxl * 8,
            right: AppSpacings.xl,
            child: AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _cloud2Animation.value,
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColor.backgroundSecondary,
                ),
              ),
            ),
          ),

          Positioned(
            top: AppSpacings.xxl * 2,
            left: AppSpacings.xl,
            child: AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _cloud3Animation.value,
                  child: child,
                );
              },
              child: Container(
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColor.backgroundSecondary,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: AppSpacings.xxl * 8,
            right: AppSpacings.xl,
            child: AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _cloud4Animation.value,
                  child: child,
                );
              },
              child: Container(
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColor.backgroundSecondary,
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacings.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _logoAnimation.value),
                        child: child,
                      );
                    },
                    child: Image.asset("assets/images/logo.png", height: 200),
                  ),

                  SizedBox(height: AppSpacings.xxl),

                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          "Route",
                          variant: AppTextVariant.display,
                          colorOverride: AppColor.secondary,
                        ),
                        AppText(
                          "Finder",
                          variant: AppTextVariant.display,
                          colorOverride: AppColor.primary,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacings.lg),

                  AppText(
                    "Discover the world, one swipe at a time",
                    variant: AppTextVariant.title,
                    colorOverride: AppColor.textMuted,
                    weightOverride: FontWeight.w400,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppSpacings.xxl),

                  AppButton(
                    label: "Start Exploring",
                    onTap: () {
                      context.pushAnimated(
                        AuthenticationPage(showLoginFirst: false),
                        animation: NavigationAnimation.fadeScale,
                      );
                    },
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    trailing: Icon(
                      LucideIcons.arrowRight300,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: AppSpacings.lg),

                  AppButton(
                    label: "Sign In",
                    onTap: () {
                      context.pushAnimated(
                        AuthenticationPage(showLoginFirst: true),
                        animation: NavigationAnimation.fadeScale,
                      );
                    },
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
