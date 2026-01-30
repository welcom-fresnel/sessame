import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Durée de l'animation
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fond noir comme Netflix
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation du Logo principal
            ZoomIn(
              duration: const Duration(milliseconds: 1500),
              child: FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 180,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.auto_awesome,
                      size: 100,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Texte qui apparaît avec un effet de balayage
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              duration: const Duration(milliseconds: 1000),
              child: Text(
                'SESSAME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      color: Colors.deepPurple.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
