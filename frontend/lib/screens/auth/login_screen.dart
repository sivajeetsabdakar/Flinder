import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flinder_logo.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/social_button.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../services/user_profile_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleGoogleLogin([GoogleSignInAccount? account]) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response =
        account == null
            ? await authProvider.signInWithGoogle()
            : await authProvider.authenticateGoogleAccount(account);

    if (!mounted) return;

    if (response.success) {
      await _navigateAfterAuth();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _navigateAfterAuth() async {
    final shouldShowQuestionnaire =
        await UserProfileService.shouldShowProfileQuestionnaire();
    if (!mounted) return;
    if (shouldShowQuestionnaire) {
      AppRouter.navigateToProfileCreation(context);
    } else {
      AppRouter.navigateToMain(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return GradientBackground(
      maxContentWidth: 1180,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'If you want to explore how it works, Click here',
                waitDuration: const Duration(milliseconds: 250),
                child: TextButton.icon(
                  onPressed:
                      () => AppRouter.navigateToDeveloperArchitecture(context),
                  icon: const Icon(Icons.code_rounded, size: 18),
                  label: const Text('For Recruiters and Developers'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: AppTheme.lightPurple.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FlinderLogo(
                        isCircular: false,
                        size: 120,
                        showTagline: true,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Welcome Back",
                        style: AppTheme.headingStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Continue with Google to find compatible flatmates",
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      SocialButton(
                        type: SocialButtonType.google,
                        onPressed: () => _handleGoogleLogin(),
                        onGoogleAccount: _handleGoogleLogin,
                        isLoading: isLoading,
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
