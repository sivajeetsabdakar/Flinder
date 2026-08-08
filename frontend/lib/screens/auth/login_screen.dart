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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final Animation<double> _floatingOffset;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _floatingOffset = Tween<double>(begin: -4, end: 5).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

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
              child: AnimatedBuilder(
                animation: _floatingOffset,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingOffset.value),
                    child: child,
                  );
                },
                child: _RecruiterDeveloperCta(
                  onPressed:
                      () => AppRouter.navigateToDeveloperArchitecture(context),
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

class _RecruiterDeveloperCta extends StatefulWidget {
  final VoidCallback onPressed;

  const _RecruiterDeveloperCta({required this.onPressed});

  @override
  State<_RecruiterDeveloperCta> createState() => _RecruiterDeveloperCtaState();
}

class _RecruiterDeveloperCtaState extends State<_RecruiterDeveloperCta> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'If you want to explore how it works, Click here',
      waitDuration: const Duration(milliseconds: 200),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  _hovering
                      ? const [Color(0xFF9D4EDD), Color(0xFFFF4D8D)]
                      : [
                        Colors.white.withOpacity(0.10),
                        AppTheme.primaryPurple.withOpacity(0.18),
                      ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  _hovering
                      ? Colors.white.withOpacity(0.65)
                      : AppTheme.lightPurple.withOpacity(0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(
                  _hovering ? 0.42 : 0.22,
                ),
                blurRadius: _hovering ? 26 : 18,
                spreadRadius: _hovering ? 2 : 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.terminal_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'For Recruiters and Developers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _hovering ? 0.02 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
