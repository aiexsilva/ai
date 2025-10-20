import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:route_finder/components/components.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/pages/authentication/login_page.dart';
import 'package:route_finder/pages/dashboard/dashboard_page.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:toastification/toastification.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
                      'Welcome to Route Finder!',
                      variant: AppTextVariant.heading,
                      weightOverride: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacings.md),
                    AppText(
                      'Choose how you want to create your account.',
                      variant: AppTextVariant.body,
                      textAlign: TextAlign.center,
                      colorOverride: Colors.grey,
                    ),
                    SizedBox(height: AppSpacings.lg),
                    AppButton(
                      label: 'Sign up with Email',
                      onTap: () =>
                          context.pushAnimated(const RegisterFieldsPage()),
                    ),
                    // SizedBox(height: AppSpacings.md),
                    // AppButton(
                    //   label: 'Sign up with Apple',
                    //   onTap: () async {
                    //     final available = await SignInWithApple.isAvailable();
                    //     print('apple sign in available: $available');

                    //     final result = await FirebaseHelper.signInWithApple();

                    //     if (!mounted) return;

                    //     if (!result["success"]) {
                    //       toastification.show(
                    //         context: context,
                    //         type: ToastificationType.error,
                    //         title: AppText(
                    //           'Registration failed!',
                    //           variant: AppTextVariant.title,
                    //           weightOverride: FontWeight.w600,
                    //         ),
                    //         description: AppText(
                    //           'An unknown error occurred.',
                    //           variant: AppTextVariant.label,
                    //           weightOverride: FontWeight.w600,
                    //           colorOverride: Colors.grey,
                    //         ),
                    //         autoCloseDuration: const Duration(seconds: 4),
                    //         dragToClose: true,
                    //       );
                    //       return;
                    //     }

                    //     toastification.show(
                    //       context: context,
                    //       type: ToastificationType.success,
                    //       title: AppText(
                    //         'Sign up successful!',
                    //         variant: AppTextVariant.title,
                    //         weightOverride: FontWeight.w600,
                    //       ),
                    //       description: AppText(
                    //         'You\'ll be redirected shortly.',
                    //         variant: AppTextVariant.label,
                    //         weightOverride: FontWeight.w600,
                    //         colorOverride: Colors.grey,
                    //       ),
                    //       autoCloseDuration: const Duration(seconds: 4),
                    //       dragToClose: true,
                    //     );

                    //     await Future.delayed(const Duration(seconds: 4));

                    //     context.pushAnimated(const DashboardPage());
                    //   },
                    //   variant: AppButtonVariant.ghost,
                    // ),
                    SizedBox(height: AppSpacings.md),
                    AppButton(
                      label: 'Sign up with Google',
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
                              'Registration failed!',
                              variant: AppTextVariant.title,
                              weightOverride: FontWeight.w600,
                            ),
                            description: AppText(
                              'An unknown error occurred.',
                              variant: AppTextVariant.label,
                              weightOverride: FontWeight.w600,
                              colorOverride: Colors.grey,
                            ),
                            autoCloseDuration: const Duration(seconds: 4),
                            dragToClose: true,
                          );
                          return;
                        }

                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          title: AppText(
                            'Sign up successful!',
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

                        await Future.delayed(const Duration(seconds: 4));

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

class RegisterFieldsPage extends StatefulWidget {
  const RegisterFieldsPage({super.key});

  @override
  State<RegisterFieldsPage> createState() => _RegisterFieldsPageState();
}

class _RegisterFieldsPageState extends State<RegisterFieldsPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

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

    confirmPasswordController.addListener(() {
      if (confirmPasswordError != null) {
        setState(() {
          confirmPasswordError = null;
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
      confirmPasswordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

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
    if (password != confirmPassword) {
      setState(() {
        confirmPasswordError = 'Passwords do not match.';
        isLoading = false;
        enabled = true;
      });
      return;
    }

    try {
      await FirebaseHelper.registerWithEmailAndPassword(email, password);

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

      setState(() {
        isLoading = false;
        enabled = true;
      });

      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;

      context.pushAnimated(LoginFieldsPage());
    } catch (e) {
      if (!mounted) return;

      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: AppText(
          'Registration failed!',
          variant: AppTextVariant.title,
          weightOverride: FontWeight.w600,
        ),
        description: AppText(
          'This email is already in use.',
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
                      'Create your account',
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
                    SizedBox(height: AppSpacings.lg),
                    AppTextInput(
                      label: "Confirm Password",
                      placeholder: "********",
                      controller: confirmPasswordController,
                      error: confirmPasswordError,
                      leadingIcon: LucideIcons.lock300,
                      obscureText: true,
                    ),
                    SizedBox(height: AppSpacings.xl),
                    AppButton(
                      label: 'Register',
                      onTap: _setup,
                      enabled: enabled,
                      isLoading: isLoading,
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
