import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool useAppBar;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const GradientBackground({
    Key? key,
    required this.child,
    this.useAppBar = false,
    this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar:
          useAppBar
              ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title:
                    title != null
                        ? Text(title!, style: AppTheme.subheadingStyle)
                        : null,
                centerTitle: true,
                actions: actions,
                leading:
                    leading ??
                    (showBackButton
                        ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                        : null),
              )
              : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground,
              AppTheme.darkerPurple.withOpacity(0.8),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
