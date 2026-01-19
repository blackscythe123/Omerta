import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../game/game_manager.dart';
import '../models/game_state.dart';

enum WaitingReason { nightAction, voting, otherPlayers }

class WaitingScreen extends StatefulWidget {
  final WaitingReason reason;
  final String? message;

  const WaitingScreen({
    super.key,
    this.reason = WaitingReason.otherPlayers,
    this.message,
  });

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.reason) {
      case WaitingReason.nightAction:
        return Icons.nightlight_round;
      case WaitingReason.voting:
        return Icons.how_to_vote;
      case WaitingReason.otherPlayers:
      default:
        return Icons.hourglass_empty;
    }
  }

  Color get _iconColor {
    switch (widget.reason) {
      case WaitingReason.nightAction:
        return Colors.indigo;
      case WaitingReason.voting:
        return AppColors.primary;
      case WaitingReason.otherPlayers:
      default:
        return AppColors.secondary;
    }
  }

  String get _title {
    switch (widget.reason) {
      case WaitingReason.nightAction:
        return 'NIGHT IN PROGRESS';
      case WaitingReason.voting:
        return 'VOTES BEING COUNTED';
      case WaitingReason.otherPlayers:
      default:
        return 'WAITING';
    }
  }

  String get _subtitle {
    if (widget.message != null) return widget.message!;
    switch (widget.reason) {
      case WaitingReason.nightAction:
        return 'Special roles are performing their actions...';
      case WaitingReason.voting:
        return 'The votes are being tallied...';
      case WaitingReason.otherPlayers:
      default:
        return 'Waiting for other players...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();

    // Auto-close when the relevant phase completes
    if (widget.reason == WaitingReason.voting &&
        manager.phase != GamePhase.voting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    if (widget.reason == WaitingReason.nightAction &&
        manager.phase != GamePhase.night) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              _iconColor.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _iconColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _icon,
                      size: 56,
                      color: _iconColor,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  _title,
                  style: AppTextStyles.headlineLarge,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    _subtitle,
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 80),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.visibility_off,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Keep your role secret',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
