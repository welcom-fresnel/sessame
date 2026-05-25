import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import '../services/user_profile_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  final _profileService = UserProfileService();
  StreamSubscription? _sub;
  bool _ready = false;
  bool _signedIn = false;
  bool _profileReady = false;
  bool _checkingProfile = false;

  @override
  void initState() {
    super.initState();
    _signedIn = _authService.currentUser != null;
    _ready = true;
    _sub = _authService.authStateChanges().listen((user) {
      if (!mounted) return;
      _handleUser(user);
    });

    _handleUser(_authService.currentUser);
  }

  Future<void> _handleUser(dynamic user) async {
    final isSignedIn = user != null;
    if (!mounted) return;
    setState(() {
      _signedIn = isSignedIn;
      _ready = true;
      _profileReady = !isSignedIn ? false : false;
      _checkingProfile = isSignedIn;
    });

    if (!isSignedIn) return;

    try {
      final uid = _authService.currentUser!.uid;
      final profile = await _profileService.getProfile(uid);
      final hasBasics =
          (profile?['firstName'] ?? '').toString().trim().isNotEmpty &&
          (profile?['lastName'] ?? '').toString().trim().isNotEmpty &&
          (profile?['birthYear'] is num) &&
          (profile?['phoneNumber'] ?? '').toString().trim().isNotEmpty;
      if (!mounted) return;
      setState(() {
        _profileReady = hasBasics;
        _checkingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // If profile check fails, allow the user into the app rather than bouncing.
        _profileReady = true;
        _checkingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_signedIn) return const AuthScreen();
    if (_checkingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_profileReady) return const AuthScreen();
    return const HomeScreen();
  }
}

