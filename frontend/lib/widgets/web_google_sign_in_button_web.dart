import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

import '../services/auth_service.dart';

Widget buildWebGoogleSignInButton({
  required bool isLoading,
  required Future<void> Function() onAuthenticated,
}) {
  return _GoogleIdentityButton(
    isLoading: isLoading,
    onAuthenticated: onAuthenticated,
  );
}

class _GoogleIdentityButton extends StatefulWidget {
  final bool isLoading;
  final Future<void> Function() onAuthenticated;

  const _GoogleIdentityButton({
    required this.isLoading,
    required this.onAuthenticated,
  });

  @override
  State<_GoogleIdentityButton> createState() => _GoogleIdentityButtonState();
}

class _GoogleIdentityButtonState extends State<_GoogleIdentityButton> {
  StreamSubscription? _subscription;
  bool _handlingAccount = false;

  @override
  void initState() {
    super.initState();
    _subscription = AuthService.googleSignIn.onCurrentUserChanged.listen((
      account,
    ) async {
      if (account == null || _handlingAccount) return;
      _handlingAccount = true;
      try {
        await widget.onAuthenticated();
      } finally {
        _handlingAccount = false;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: google_web.renderButton(),
    );
  }
}
