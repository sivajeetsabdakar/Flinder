import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'web_google_sign_in_button_stub.dart'
    if (dart.library.html) 'web_google_sign_in_button_web.dart';

class WebGoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function(GoogleSignInAccount account) onAuthenticated;

  const WebGoogleSignInButton({
    Key? key,
    required this.isLoading,
    required this.onAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildWebGoogleSignInButton(
      isLoading: isLoading,
      onAuthenticated: onAuthenticated,
    );
  }
}
