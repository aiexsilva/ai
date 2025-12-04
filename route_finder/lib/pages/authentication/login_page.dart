import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/pages/dashboard/dashboard_page.dart';
import 'package:toastification/toastification.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeAreaPadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.popAnimated(),
              child: Container(
                color: Colors.transparent,
                width: 44,
                height: 44,
                child: Icon(LucideIcons.arrowLeft300, size: 24),
              ),
            ),
            SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShadowedLottie(name: "logo"),
                    SizedBox(height: AppSpacings.xl),
                    AppText(
                      'Welcome back!',
                      variant: AppTextVariant.heading,
                      weightOverride: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacings.md),
                    AppText(
                      'Choose how you want to log into your account.',
                      variant: AppTextVariant.body,
                      textAlign: TextAlign.center,
                      colorOverride: Colors.grey,
                    ),
                    SizedBox(height: AppSpacings.lg),
                    AppButton(
                      label: 'Sign in with Email',
                      onTap: () => context.pushAnimated(LoginFieldsPage()),
                    ),
                    // SizedBox(height: AppSpacings.md),
                    // AppButton(
                    //   label: 'Sign in with Apple',
                    //   onTap: () {},
                    //   variant: AppButtonVariant.ghost,
                    // ),
                    SizedBox(height: AppSpacings.md),
                    AppButton(
                      label: 'Sign in with Google',
                      onTap: () async {
                        final result =
                            await FirebaseHelper.signInWithGoogleAndFinalize(
                              context,
                            );

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

                        context.pushAnimated(const DashboardPage());
                      },
                      variant: AppButtonVariant.outline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginFieldsPage extends StatefulWidget {
  const LoginFieldsPage({super.key});

  @override
  State<LoginFieldsPage> createState() => _LoginFieldsPageState();
}

class _LoginFieldsPageState extends State<LoginFieldsPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  bool isLoading = false, enabled = true;

  @override
  void initState() {
    super.initState();

    emailController.addListener(() {
      if (emailError != null) {
        setState(() {
          emailError = null;
        });
      }
    });

    passwordController.addListener(() {
      if (passwordError != null) {
        setState(() {
          passwordError = null;
        });
      }
    });
  }

  Future<void> _setup() async {
    setState(() {
      isLoading = true;
      enabled = false;
      emailError = null;
      passwordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!isValidEmail(email)) {
      setState(() {
        emailError = 'Please enter a valid email address.';
        isLoading = false;
        enabled = true;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        passwordError = 'Password must be at least 6 characters long.';
        isLoading = false;
        enabled = true;
      });
      return;
    }

    try {
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

      setState(() {
        isLoading = false;
        enabled = true;
      });

      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;

      context.pushAnimated(DashboardPage());
    } catch (e) {
      if (!mounted) return;

      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: AppText(
          'Login failed!',
          variant: AppTextVariant.title,
          weightOverride: FontWeight.w600,
        ),
        description: AppText(
          'The credentials don\'t match.',
          variant: AppTextVariant.label,
          weightOverride: FontWeight.w600,
          colorOverride: Colors.grey,
        ),
        autoCloseDuration: const Duration(seconds: 4),
        dragToClose: true,
      );

      setState(() {
        isLoading = false;
        enabled = true;
      });

      debugPrint('Registration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeAreaPadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.popAnimated(),
              child: Container(
                color: Colors.transparent,
                width: 44,
                height: 44,
                child: Icon(LucideIcons.arrowLeft300, size: 24),
              ),
            ),
            SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShadowedLottie(name: "logo"),
                    SizedBox(height: AppSpacings.xl),
                    AppText(
                      'Sign into your account',
                      variant: AppTextVariant.heading,
                      weightOverride: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacings.md),
                    AppText(
                      'Use your email to continue.',
                      variant: AppTextVariant.body,
                      textAlign: TextAlign.center,
                      colorOverride: Colors.grey,
                    ),
                    SizedBox(height: AppSpacings.xl),
                    AppTextInput(
                      label: "Email",
                      placeholder: "your@gmail.com",
                      controller: emailController,
                      error: emailError,
                      leadingIcon: LucideIcons.mail300,
                    ),
                    SizedBox(height: AppSpacings.lg),
                    AppTextInput(
                      label: "Password",
                      placeholder: "********",
                      controller: passwordController,
                      error: passwordError,
                      leadingIcon: LucideIcons.lock300,
                      obscureText: true,
                    ),
                    SizedBox(height: AppSpacings.xl),
                    AppButton(
                      label: 'Login',
                      onTap: _setup,
                      isLoading: isLoading,
                      enabled: enabled,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
