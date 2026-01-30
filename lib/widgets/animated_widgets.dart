import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

/// Bouton animé avec effet de rebond
class AnimatedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const AnimatedActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElasticIn(
      duration: const Duration(milliseconds: 600),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Carte de projet avec animation d'entrée
class AnimatedProjectCard extends StatelessWidget {
  final Widget child;
  final int index;

  const AnimatedProjectCard({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: 100 * index),
      child: child,
    );
  }
}

/// Bouton avec animation au tap
class AnimatedTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedTapButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<AnimatedTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// État vide avec animation
class AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Bounce(
            infinite: true,
            duration: const Duration(seconds: 2),
            child: Icon(icon, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          FadeInDown(
            delay: const Duration(milliseconds: 400),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de statut animé
class AnimatedStatusBadge extends StatelessWidget {
  final String status;
  final IconData icon;
  final Color color;

  const AnimatedStatusBadge({
    super.key,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Pulse(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progression animée
class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;

  const AnimatedProgressBar({super.key, required this.progress, this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      tween: Tween<double>(begin: 0, end: progress),
      builder: (context, value, _) => LinearProgressIndicator(
        value: value,
        minHeight: 6,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Notification toast animée
class AnimatedToast {
  static void show(
    BuildContext context, {
    required String message,
    required IconData icon,
    Color? backgroundColor,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: SlideInDown(
          duration: const Duration(milliseconds: 400),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor ?? Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }
}
