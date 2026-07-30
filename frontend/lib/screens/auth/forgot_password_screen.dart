import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flinder_logo.dart';
import '../../widgets/gradient_background.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      useAppBar: true,
      showBackButton: true,
      title: 'Account Access',
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
                  size: 110,
                  showTagline: true,
                ),
                const SizedBox(height: 28),
                Text(
                  'Use Google to sign in',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Flinder v1 uses Google accounts only, so there is no separate password to reset.',
                  style: TextStyle(color: AppTheme.lightGrey, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => AppRouter.navigateToLogin(context),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
