import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

enum GameRole {
  mafia,
  godfather,
  doctor,
  detective,
  villager,
  vigilante,
  escort,
  serialKiller,
}

class RoleRevealScreen extends StatefulWidget {
  final GameRole role;
  final List<String>? teammates;

  const RoleRevealScreen({
    super.key,
    this.role = GameRole.villager,
    this.teammates,
  });

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reveal() {
    setState(() => _revealed = true);
    _controller.forward();
  }

  void _continue() {
    Navigator.pushReplacementNamed(context, '/game');
  }

  Color _getRoleColor(GameRole role) {
    switch (role) {
      case GameRole.mafia:
      case GameRole.godfather:
        return AppColors.mafia;
      case GameRole.doctor:
        return Colors.green;
      case GameRole.detective:
        return Colors.blue;
      case GameRole.vigilante:
        return Colors.orange;
      case GameRole.escort:
        return Colors.pink;
      case GameRole.serialKiller:
        return Colors.purple;
      case GameRole.villager:
      default:
        return AppColors.town;
    }
  }

  IconData _getRoleIcon(GameRole role) {
    switch (role) {
      case GameRole.mafia:
        return Icons.person_off;
      case GameRole.godfather:
        return Icons.security;
      case GameRole.doctor:
        return Icons.medical_services;
      case GameRole.detective:
        return Icons.search;
      case GameRole.vigilante:
        return Icons.gps_fixed;
      case GameRole.escort:
        return Icons.block;
      case GameRole.serialKiller:
        return Icons.warning_amber;
      case GameRole.villager:
      default:
        return Icons.person;
    }
  }

  String _getRoleName(GameRole role) {
    switch (role) {
      case GameRole.mafia:
        return 'MAFIA';
      case GameRole.godfather:
        return 'GODFATHER';
      case GameRole.doctor:
        return 'DOCTOR';
      case GameRole.detective:
        return 'DETECTIVE';
      case GameRole.vigilante:
        return 'VIGILANTE';
      case GameRole.escort:
        return 'ESCORT';
      case GameRole.serialKiller:
        return 'SERIAL KILLER';
      case GameRole.villager:
      default:
        return 'VILLAGER';
    }
  }

  String _getRoleDescription(GameRole role) {
    switch (role) {
      case GameRole.mafia:
        return 'Each night, vote with your team to eliminate a player.';
      case GameRole.godfather:
        return 'Lead the Mafia. You appear innocent to investigators.';
      case GameRole.doctor:
        return 'Each night, choose one player to protect from death.';
      case GameRole.detective:
        return 'Each night, investigate one player to learn their alignment.';
      case GameRole.vigilante:
        return 'You have limited bullets to eliminate suspects at night.';
      case GameRole.escort:
        return 'Each night, block one player from using their ability.';
      case GameRole.serialKiller:
        return 'Kill every night. Win by being the last one standing.';
      case GameRole.villager:
      default:
        return 'Find and eliminate the Mafia through discussion and voting.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(widget.role);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              _revealed ? roleColor.withOpacity(0.15) : Colors.transparent,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                if (!_revealed) ...[
                  Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.help_outline,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'YOUR ROLE AWAITS',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap below to reveal your identity',
                    style: AppTextStyles.bodyMedium,
                  ),
                ] else ...[
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: roleColor, width: 3),
                            ),
                            child: Icon(
                              _getRoleIcon(widget.role),
                              size: 56,
                              color: roleColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'YOU ARE',
                            style: AppTextStyles.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getRoleName(widget.role),
                            style: AppTextStyles.displayMedium.copyWith(
                              color: roleColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              _getRoleDescription(widget.role),
                              style: AppTextStyles.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (widget.teammates != null &&
                              widget.teammates!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: roleColor.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'YOUR TEAM',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: roleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: widget.teammates!
                                        .map((name) => Chip(
                                              label: Text(name),
                                              backgroundColor:
                                                  roleColor.withOpacity(0.2),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (!_revealed)
                  PrimaryButtonLarge(
                    label: 'REVEAL ROLE',
                    icon: Icons.visibility,
                    onPressed: _reveal,
                  )
                else
                  PrimaryButtonLarge(
                    label: 'START GAME',
                    icon: Icons.arrow_forward,
                    onPressed: _continue,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
