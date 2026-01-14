import 'package:flutter/material.dart';
import '../../models/game_state.dart';

class DayNightTransition extends StatefulWidget {
  final GamePhase phase;
  final int day;
  final VoidCallback onFinish;

  const DayNightTransition({
    super.key,
    required this.phase,
    required this.day,
    required this.onFinish,
  });

  @override
  State<DayNightTransition> createState() => _DayNightTransitionState();
}

class _DayNightTransitionState extends State<DayNightTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _iconPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _iconPosition = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward().then((_) => widget.onFinish());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDay = widget.phase == GamePhase.discussion;
    final color = isDay ? Colors.orange : Colors.indigo;
    final icon = isDay ? Icons.wb_sunny : Icons.nightlight_round;
    final title = isDay ? 'Day ${widget.day}' : 'Night ${widget.day}';
    final subtitle = isDay ? 'The sun rises...' : 'The sun sets...';

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        color: color.withOpacity(0.98),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _iconPosition,
                child: Icon(icon,
                    size: 100,
                    color: isDay ? Colors.yellow : Colors.blueAccent),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
