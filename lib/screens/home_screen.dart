import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreenNew extends StatelessWidget {
  const HomeScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Center(
  child: Image.asset(
    'assets/images/icon.png',
    width: 100,
    height: 100,
    fit: BoxFit.contain,
  ),
),

                const SizedBox(height: 5),
                Text(
                  'Omertà',
                  style: AppTextStyles.displayLarge.copyWith(
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CITY OF DECEPTION',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                ),
                const Spacer(flex: 2),
                _MenuButton(
                  icon: Icons.wifi_tethering,
                  label: 'CREATE ROOM',
                  sublabel: 'Host a game on your network',
                  onTap: () => Navigator.pushNamed(context, '/name-entry',
                      arguments: {'isHost': true}),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.search,
                  label: 'FIND ROOM',
                  sublabel: 'Join a nearby game',
                  onTap: () => Navigator.pushNamed(context, '/name-entry',
                      arguments: {'isHost': false}),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.menu_book,
                  label: 'HOW TO PLAY',
                  sublabel: 'Rules and roles',
                  isSecondary: true,
                  onTap: () => Navigator.pushNamed(context, '/how-to-play'),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings,
                          color: AppColors.textMuted),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isSecondary;
  final VoidCallback? onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    this.isSecondary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.transparent : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSecondary
                ? AppColors.cardBorder
                : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSecondary
                    ? AppColors.surface
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color:
                    isSecondary ? AppColors.textSecondary : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    sublabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isSecondary ? AppColors.textMuted : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
