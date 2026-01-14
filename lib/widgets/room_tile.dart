import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RoomTile extends StatelessWidget {
  final String roomName;
  final String hostName;
  final int playerCount;
  final int maxPlayers;
  final bool isInProgress;
  final bool isPrivate; // Show lock icon for private rooms
  final VoidCallback? onJoin;

  const RoomTile({
    super.key,
    required this.roomName,
    required this.hostName,
    required this.playerCount,
    this.maxPlayers = 10,
    this.isInProgress = false,
    this.isPrivate = false,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = playerCount >= maxPlayers;
    final canJoin = !isFull && !isInProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isInProgress
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isInProgress
                      ? Icons.play_circle_outline
                      : Icons.wifi_tethering,
                  color: isInProgress ? AppColors.warning : AppColors.primary,
                  size: 26,
                ),
              ),
              // Lock indicator for private rooms
              if (isPrivate)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.warning,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 10,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
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
                        roomName.toUpperCase(),
                        style: AppTextStyles.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrivate) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.lock,
                        size: 14,
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hostName,
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isFull
                      ? AppColors.error.withOpacity(0.1)
                      : isInProgress
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups,
                      size: 14,
                      color: isFull
                          ? AppColors.error
                          : isInProgress
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$playerCount/$maxPlayers',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isFull
                            ? AppColors.error
                            : isInProgress
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (isInProgress)
                Text(
                  'IN PROGRESS',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.warning),
                )
              else if (isFull)
                Text(
                  'FULL',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                )
              else
                GestureDetector(
                  onTap: canJoin ? onJoin : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'JOIN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
