import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Your Matches'),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 72,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  'No matches yet',
                  style: AppTheme.headingStyle.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Keep swiping in Find. When someone likes you back, the conversation will appear in Chat.',
                  style: TextStyle(color: AppTheme.lightGrey, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.pushReplacementNamed(
                        context,
                        AppRouter.homeRoute,
                        arguments: AppRouter.findTab,
                      ),
                  icon: const Icon(Icons.people_alt),
                  label: const Text('Go to Find'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
