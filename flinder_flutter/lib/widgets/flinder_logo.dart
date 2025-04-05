import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FlinderLogo extends StatelessWidget {
  final bool isCircular;
  final double size;
  final bool showTagline;

  const FlinderLogo({
    Key? key,
    this.isCircular = true,
    this.size = 80,
    this.showTagline = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircular ? null : BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                isCircular
                    ? BorderRadius.circular(size / 2)
                    : BorderRadius.circular(16),
            child: Image.asset(
              isCircular
                  ? 'assets/logos/Circle_Logo.png'
                  : 'assets/logos/Square_Logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Flinder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                    color: AppTheme.primaryPurple,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find your perfect flatmate',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: size * 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
