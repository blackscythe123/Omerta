import 'package:flutter/material.dart';
import '../game/game_manager.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class MafiaVotePanel extends StatelessWidget {
  final GameManager manager;
  final Player local;
  final void Function(String targetId) onVote;
  final void Function(String msg) onSendMessage;

  const MafiaVotePanel({
    super.key,
    required this.manager,
    required this.local,
    required this.onVote,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final targets = manager.players
        .where((p) =>
            p.isAlive && p.role != Role.mafia && p.role != Role.godfather)
        .toList();

    final teamMsgs = manager.teamChatMessages['mafia'] ?? [];
    final myVote = manager.getMafiaVote(local.id);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mafia Vote', style: AppTextStyles.headlineMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (targets.isEmpty)
            Text('No valid targets', style: AppTextStyles.bodyLarge)
          else
            ...targets.map((t) => ListTile(
                  title: Text(t.name),
                  trailing: Text('${manager.getMafiaVoteCount(t.id)}'),
                  selected: myVote == t.id,
                  onTap: () => onVote(t.id),
                )),
          const SizedBox(height: 8),
          const Divider(),
          SizedBox(
            height: 120,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: teamMsgs
                        .map((m) => ListTile(
                              dense: true,
                              title: Text(m.senderName),
                              subtitle: Text(m.text),
                            ))
                        .toList(),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('mafia_chat_input'),
                        decoration:
                            const InputDecoration(hintText: 'Mafia chat'),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) onSendMessage(v.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
