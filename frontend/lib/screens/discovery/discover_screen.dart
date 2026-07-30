import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'flats_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: FlatsScreen(),
    );
  }
}
