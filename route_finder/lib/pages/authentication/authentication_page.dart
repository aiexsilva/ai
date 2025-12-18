import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/pages/navigation/main_scaffold.dart';
import 'package:toastification/toastification.dart';

class AuthenticationPage extends StatefulWidget {
  final bool? showLoginFirst;
  const AuthenticationPage({super.key, this.showLoginFirst = false});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  bool showingLogin = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isFormValid = false;
  bool isEmailLoading = false;
  bool isGoogleLoading = false;

  @override
  void initState() {
    showingLogin = widget.showLoginFirst ?? false;
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    nameController.addListener(_validateForm);
    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    bool isValid = true;

    // Email validation
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      isValid = false;
    }

    // Password validation
    final password = passwordController.text;
    if (password.length < 6) {
      isValid = false;
    }

    // Name validation (only for Sign Up)
    if (!showingLogin) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        isValid = false;
      }
    }

    if (isFormValid != isValid) {
      setState(() {
        isFormValid = isValid;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      isEmailLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    try {
      if (showingLogin) {
        // Login Logic
        await FirebaseHelper.signInWithEmailAndPassword(email, password);
        if (!mounted) return;

        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: AppText(
            'Login successful!',
            variant: AppTextVariant.title,
            weightOverride: FontWeight.w600,
          ),
          description: AppText(
            'You\'ll be redirected shortly.',
            variant: AppTextVariant.label,
            weightOverride: FontWeight.w600,
            colorOverride: Colors.grey,
          ),
          autoCloseDuration: const Duration(seconds: 4),
          dragToClose: true,
        );
      } else {
        // Register Logic
        await FirebaseHelper.registerWithEmailAndPassword(email, password);

        // Update Display Name
        if (name.isNotEmpty) {
          await FirebaseHelper.auth.currentUser?.updateDisplayName(name);
        }

        if (!mounted) return;

        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: AppText(
            'Registration successful!',
            variant: AppTextVariant.title,
            weightOverride: FontWeight.w600,
          ),
          description: AppText(
            'You\'ll be redirected shortly.',
            variant: AppTextVariant.label,
            weightOverride: FontWeight.w600,
            colorOverride: Colors.grey,
          ),
          autoCloseDuration: const Duration(seconds: 4),
          dragToClose: true,
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.pushAnimated(const MainScaffold());
    } catch (e) {
      if (!mounted) return;

      String errorMessage = showingLogin
          ? 'The credentials don\'t match.'
          : 'This email is already in use.';

      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: AppText(
          showingLogin ? 'Login failed!' : 'Registration failed!',
          variant: AppTextVariant.title,
          weightOverride: FontWeight.w600,
        ),
        description: AppText(
          errorMessage,
          variant: AppTextVariant.label,
          weightOverride: FontWeight.w600,
          colorOverride: Colors.grey,
        ),
        autoCloseDuration: const Duration(seconds: 4),
        dragToClose: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isEmailLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final result = await FirebaseHelper.signInWithGoogleAndFinalize(context);

      if (!mounted) return;

      if (!result["success"]) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: AppText(
            'Login failed!',
            variant: AppTextVariant.title,
            weightOverride: FontWeight.w600,
          ),
          description: AppText(
            'An unknown error occurred.',
            variant: AppTextVariant.label,
            weightOverride: FontWeight.w600,
            colorOverride: Colors.grey,
          ),
          autoCloseDuration: const Duration(seconds: 2),
          dragToClose: true,
        );
        return;
      }

      context.pushAnimated(const MainScaffold());
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacings.lg),
                child: Column(
                  children: [
                    SizedBox(height: AppSpacings.xxl),
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _logoAnimation.value),
                          child: child,
                        );
                      },
                      child: Image.asset("assets/images/logo.png", height: 100),
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
                      showingLogin
                          ? "Welcome back, explorer"
                          : "Start your adventure today",
                      variant: AppTextVariant.title,
                      colorOverride: AppColor.textMuted,
                      weightOverride: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacings.xxl)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(60)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(AppSpacings.xxl),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColor.backgroundDark,
                        ),
                        padding: EdgeInsets.all(AppSpacings.sm),
                        child: Row(
                          spacing: AppSpacings.sm,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showingLogin = true;
                                    _validateForm();
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacings.lg),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: showingLogin
                                        ? Colors.white
                                        : AppColor.backgroundDark,
                                  ),
                                  child: Center(
                                    child: AppText(
                                      "Sign In",
                                      colorOverride: showingLogin
                                          ? AppColor.textPrimary
                                          : AppColor.textMuted,
                                      weightOverride: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showingLogin = false;
                                    _validateForm();
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacings.lg),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: showingLogin
                                        ? AppColor.backgroundDark
                                        : Colors.white,
                                  ),
                                  child: Center(
                                    child: AppText(
                                      "Sign Up",
                                      colorOverride: showingLogin
                                          ? AppColor.textMuted
                                          : AppColor.textPrimary,
                                      weightOverride: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacings.xl),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: !showingLogin
                            ? Column(
                                children: [
                                  AppTextInput(
                                    label: "",
                                    placeholder: "Name",
                                    controller: nameController,
                                    leadingIcon: LucideIcons.user300,
                                  ),
                                  SizedBox(height: AppSpacings.lg),
                                ],
                              )
                            : SizedBox.shrink(),
                      ),
                      AppTextInput(
                        label: "",
                        placeholder: "Email address",
                        controller: emailController,
                        leadingIcon: LucideIcons.mail300,
                      ),
                      SizedBox(height: AppSpacings.lg),
                      AppTextInput(
                        label: "",
                        placeholder: "Password",
                        controller: passwordController,
                        leadingIcon: LucideIcons.lock300,
                        obscureText: true,
                      ),

                      SizedBox(height: AppSpacings.xl),

                      AppButton(
                        label: "Sign ${showingLogin ? "In" : "Up"}",
                        onTap: _submit,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        enabled: isFormValid && !isGoogleLoading,
                        isLoading: isEmailLoading,
                        trailing: Icon(
                          LucideIcons.arrowRight300,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: AppSpacings.xl),

                      Row(
                        spacing: AppSpacings.lg,
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColor.outline,
                            ),
                          ),
                          AppText(
                            "or continue with",
                            colorOverride: AppColor.textMuted,
                            variant: AppTextVariant.caption,
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColor.outline,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSpacings.xl),

                      AppButton(
                        label: " Continue with Google",
                        variant: AppButtonVariant.outline,
                        onTap: _handleGoogleSignIn,
                        isLoading: isGoogleLoading,
                        enabled: !isEmailLoading,
                        leading: SvgPicture.asset(
                          "assets/images/google_logo.svg",
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
