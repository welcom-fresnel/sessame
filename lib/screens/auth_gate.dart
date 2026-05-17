import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  StreamSubscription? _sub;
  bool _ready = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _signedIn = _authService.currentUser != null;
    _ready = true;
    _sub = _authService.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _signedIn = user != null;
        _ready = true;
      });
    });
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
    return _signedIn ? const HomeScreen() : const AuthScreen();
  }
}

