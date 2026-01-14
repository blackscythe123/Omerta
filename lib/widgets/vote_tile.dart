import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VoteTile extends StatelessWidget {
  final String playerName;
  final int voteCount;
  final bool isSelected;
  final bool isEliminated;
  final bool canVote;
  final VoidCallback? onVote;

  const VoteTile({
    super.key,
    required this.playerName,
    this.voteCount = 0,
    this.isSelected = false,
    this.isEliminated = false,
    this.canVote = true,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canVote && !isEliminated ? onVote : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isEliminated
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isEliminated ? 0.4 : 1.0,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surface,
                child: Text(
                  playerName.substring(0, 1).toUpperCase(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isSelected
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
                    Text(
                      playerName.toUpperCase(),
                      style: AppTextStyles.titleMedium.copyWith(
                        decoration:
                            isEliminated ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isEliminated)
                      Text(
                        'ELIMINATED',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.error),
                      ),
                  ],
                ),
              ),
              if (voteCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: voteCount >= 3
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.how_to_vote,
                        size: 16,
                        color: voteCount >= 3
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$voteCount',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: voteCount >= 3
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (canVote && !isEliminated) ...[
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
