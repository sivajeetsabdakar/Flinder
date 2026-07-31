import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Widget buildWebGoogleSignInButton({
  required bool isLoading,
  required Future<void> Function(GoogleSignInAccount account) onAuthenticated,
}) {
  return const SizedBox.shrink();
}
