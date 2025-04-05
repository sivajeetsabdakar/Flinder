import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/flinder_logo.dart';
import '../../widgets/gradient_background.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.resetPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        if (response.success) {
          setState(() {
            _emailSent = true;
          });
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

  Widget _buildResetForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FlinderLogo(isCircular: false, size: 120, showTagline: true),
        const SizedBox(height: 32),
        Text(
          "Forgot Password?",
          style: AppTheme.headingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Enter your email address and we'll send you a link to reset your password",
          style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
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
              const SizedBox(height: 32),
              CustomButton(
                text: "Send Reset Link",
                onPressed: _handleResetPassword,
                isLoading: isLoading,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  AppRouter.navigateToLogin(context);
                },
                child: Text(
                  "Back to Login",
                  style: TextStyle(
                    color: AppTheme.primaryPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppTheme.primaryPurple,
        ),
        const SizedBox(height: 32),
        Text(
          "Email Sent!",
          style: AppTheme.headingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "We've sent a password reset link to ${_emailController.text}",
          style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Check your email and follow the instructions to reset your password",
          style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: "Back to Login",
          onPressed: () {
            AppRouter.navigateToLogin(context);
          },
          type: ButtonType.secondary,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: Text(
            "Try another email",
            style: TextStyle(
              color: AppTheme.primaryPurple,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return GradientBackground(
      useAppBar: true,
      showBackButton: true,
      title: "Forgot Password",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: _emailSent ? _buildSuccessView() : _buildResetForm(isLoading),
      ),
    );
  }
}
