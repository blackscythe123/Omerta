import 'package:flutter/material.dart';

/// Countdown overlay widget that displays a countdown animation
/// Shows numbers 5-4-3-2-1 with fade and scale animations
class CountdownOverlay extends StatefulWidget {
  final int countdownValue;
  final VoidCallback? onComplete;

  const CountdownOverlay({
    super.key,
    required this.countdownValue,
    this.onComplete,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    if (widget.countdownValue > 0) {
      _lastValue = widget.countdownValue;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CountdownOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countdownValue != oldWidget.countdownValue &&
        widget.countdownValue > 0) {
      _lastValue = widget.countdownValue;
      _controller.reset();
      _controller.forward();
    } else if (widget.countdownValue == 0 && oldWidget.countdownValue != 0) {
      // Countdown complete
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.countdownValue <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  _lastValue?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 20.0,
                        color: Theme.of(context).primaryColor,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
