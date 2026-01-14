import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/game_manager.dart';
import '../../models/player.dart';
import '../../models/game_state.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onVote;
  final VoidCallback? onNightAction;

  const PlayerTile({
    super.key,
    required this.player,
    this.isSelectable = false,
    this.isSelected = false,
    this.onVote,
    this.onNightAction,
  });

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();
    final voteCount = manager.getVoteCount(player.id);
    final isDead = !player.isAlive;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDead ? 0.5 : 1.0,
      child: Card(
        color: isSelected ? Colors.deepPurple.shade700 : Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Colors.deepPurple.shade300, width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(
            isDead ? Icons.heart_broken : Icons.person,
            color: isDead ? Colors.grey : Colors.white,
          ),
          title: Text(
            player.name,
            style: TextStyle(
              decoration: isDead ? TextDecoration.lineThrough : TextDecoration.none,
              color: isDead ? Colors.grey : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: _buildTrailing(context, manager, voteCount, isDead),
          onTap: isDead ? null : (onVote ?? onNightAction),
        ),
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, GameManager manager, int voteCount, bool isDead) {
    if (manager.phase == GamePhase.voting) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (voteCount > 0)
            Text(
              '$voteCount',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
          const SizedBox(width: 8),
          if (!isDead)
            ElevatedButton(
              onPressed: onVote,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: isSelected ? Colors.purple : Colors.deepPurple,
              ),
              child: const Text('Vote'),
            ),
        ],
      );
    }
    if (manager.phase == GamePhase.night && isSelectable && !isDead) {
      return ElevatedButton(
        onPressed: onNightAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.teal : Colors.blueGrey,
        ),
        child: const Text('Select'),
      );
    }
    return null;
  }
}
