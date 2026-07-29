import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SocialButtonType { google, apple, facebook }

class SocialButton extends StatelessWidget {
  final SocialButtonType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialButton({
    Key? key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String text;
    IconData? icon;
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case SocialButtonType.google:
        text = "Continue with Google";
        icon = Icons.g_mobiledata;
        backgroundColor = Colors.white;
        textColor = Colors.black;
        break;
      case SocialButtonType.apple:
        text = "Continue with Apple";
        icon = Icons.apple;
        backgroundColor = Colors.black;
        textColor = Colors.white;
        break;
      case SocialButtonType.facebook:
        text = "Continue with Facebook";
        icon = Icons.facebook;
        backgroundColor = const Color(0xFF1877F2);
        textColor = Colors.white;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppTheme.mediumGrey.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: textColor,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: textColor),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
