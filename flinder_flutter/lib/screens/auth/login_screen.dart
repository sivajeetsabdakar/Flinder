import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/flinder_logo.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/social_button.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (response.success) {
          // Navigate to home screen
          AppRouter.navigateToMain(context);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleGoogleLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google login not implemented yet'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleAppleLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple login not implemented yet'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return GradientBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FlinderLogo(isCircular: false, size: 120, showTagline: true),
            const SizedBox(height: 32),
            Text(
              "Welcome Back",
              style: AppTheme.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Sign in to continue",
              style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    hintText: "Email",
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomPasswordField(
                    hintText: "Password",
                    prefixIcon: Icons.lock_outline,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        fillColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.primaryPurple;
                          }
                          return AppTheme.darkGrey;
                        }),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Remember me",
                      style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    AppRouter.navigateToForgotPassword(context);
                  },
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: AppTheme.primaryPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: "Log In",
              onPressed: _handleLogin,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppTheme.mediumGrey.withOpacity(0.5),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Or login with",
                    style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppTheme.mediumGrey.withOpacity(0.5),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SocialButton(
              type: SocialButtonType.google,
              onPressed: _handleGoogleLogin,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),
            SocialButton(
              type: SocialButtonType.apple,
              onPressed: _handleAppleLogin,
              isLoading: isLoading,
            ),
            const SizedBox(height: 32),
            RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
                children: [
                  TextSpan(
                    text: "Sign up",
                    style: TextStyle(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer:
                        TapGestureRecognizer()
                          ..onTap = () {
                            AppRouter.navigateToSignup(context);
                          },
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
