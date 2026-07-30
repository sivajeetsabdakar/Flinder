import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flinder_logo.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/social_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  Future<void> _handleGoogleSignup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (response.success) {
      final shouldShowQuestionnaire =
          await UserProfileService.shouldShowProfileQuestionnaire();
      if (!mounted) return;
      if (shouldShowQuestionnaire) {
        AppRouter.navigateToProfileCreation(context);
      } else {
        AppRouter.navigateToMain(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return GradientBackground(
      useAppBar: true,
      showBackButton: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const FlinderLogo(
                  isCircular: false,
                  size: 120,
                  showTagline: true,
                ),
                const SizedBox(height: 32),
                Text(
                  'Create your Flinder account',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Google sign-in keeps v1 simple and secure. We will ask roommate preferences next.',
                  style: TextStyle(color: AppTheme.lightGrey, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SocialButton(
                  type: SocialButtonType.google,
                  onPressed: _handleGoogleSignup,
                  isLoading: authProvider.isLoading,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => AppRouter.navigateToLogin(context),
                  child: const Text('I already have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
