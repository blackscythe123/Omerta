import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PlayerStatus { waiting, ready, voting, voted, eliminated, disconnected }

class PlayerCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? avatarText;
  final IconData? avatarIcon;
  final PlayerStatus status;
  final bool isHost;
  final bool isYou;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PlayerCard({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarText,
    this.avatarIcon,
    this.status = PlayerStatus.waiting,
    this.isHost = false,
    this.isYou = false,
    this.onTap,
    this.trailing,
  });

  Color get _statusColor {
    switch (status) {
      case PlayerStatus.ready:
        return AppColors.success;
      case PlayerStatus.voting:
        return AppColors.warning;
      case PlayerStatus.voted:
        return AppColors.primary;
      case PlayerStatus.eliminated:
        return AppColors.error;
      case PlayerStatus.disconnected:
        return AppColors.textMuted;
      case PlayerStatus.waiting:
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusText {
    switch (status) {
      case PlayerStatus.ready:
        return 'READY';
      case PlayerStatus.voting:
        return 'VOTING';
      case PlayerStatus.voted:
        return 'VOTED';
      case PlayerStatus.eliminated:
        return 'ELIMINATED';
      case PlayerStatus.disconnected:
        return 'OFFLINE';
      case PlayerStatus.waiting:
      default:
        return 'WAITING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEliminated = status == PlayerStatus.eliminated;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isYou ? AppColors.primary.withOpacity(0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isYou
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.cardBorder,
            width: isYou ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isEliminated ? 0.5 : 1.0,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isYou
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surface,
                child: avatarIcon != null
                    ? Icon(avatarIcon,
                        color:
                            isYou ? AppColors.primary : AppColors.textSecondary,
                        size: 24)
                    : Text(
                        avatarText ?? name.substring(0, 1).toUpperCase(),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: isYou
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name.toUpperCase(),
                            style: AppTextStyles.titleMedium.copyWith(
                              decoration: isEliminated
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isYou) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                        if (isHost) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HOST',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ?? _statusText,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: _statusColor),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && status != PlayerStatus.eliminated)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
