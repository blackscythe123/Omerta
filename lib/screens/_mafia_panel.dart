import 'package:flutter/material.dart';
import '../game/game_manager.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class MafiaVotePanel extends StatefulWidget {
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
  State<MafiaVotePanel> createState() => _MafiaVotePanelState();
}

class _MafiaVotePanelState extends State<MafiaVotePanel> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.manager;
    final local = widget.local;

    final targets = manager.players
        .where((p) =>
            p.isAlive && p.role != Role.mafia && p.role != Role.godfather)
        .toList();

    final teamMsgs = manager.teamChatMessages['mafia'] ?? [];
    final myVote = manager.getMafiaVote(local.id);
    final aliveMafiaCount = manager.aliveMafia().length;
    final votedCount = manager.mafiaNightVotes.length;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mafia Vote', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text('$votedCount / $aliveMafiaCount voted',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (targets.isEmpty)
            Container(
              height: 80,
              alignment: Alignment.center,
              child: Text('No valid targets', style: AppTextStyles.bodyLarge),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: targets.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, idx) {
                  final t = targets[idx];
                  final count = manager.getMafiaVoteCount(t.id);
                  final selected = myVote == t.id;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.card,
                      child: Text(t.name.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.labelSmall),
                    ),
                    title: Text(t.name, style: AppTextStyles.bodyLarge),
                    subtitle: Text('$count vote${count == 1 ? '' : 's'}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textMuted)),
                    trailing: selected
                        ? Chip(
                            backgroundColor: AppColors.primary,
                            label: Text('Your vote',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: Colors.white)),
                          )
                        : Chip(
                            backgroundColor: AppColors.card,
                            label:
                                Text('$count', style: AppTextStyles.labelSmall),
                          ),
                    selected: selected,
                    selectedTileColor: AppColors.primary.withOpacity(0.05),
                    onTap: () {
                      widget.onVote(t.id);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: teamMsgs.length,
                    itemBuilder: (context, idx) {
                      final m = teamMsgs[teamMsgs.length - 1 - idx];
                      final mine = m.senderId == local.id;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: mine ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.senderName,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(m.text,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: mine ? Colors.white : null)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        key: const Key('mafia_chat_input'),
                        decoration: InputDecoration(
                          hintText: 'Mafia chat',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (v) {
                          final text = v.trim();
                          if (text.isNotEmpty) {
                            widget.onSendMessage(text);
                            _msgController.clear();
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: () {
                        final text = _msgController.text.trim();
                        if (text.isNotEmpty) {
                          widget.onSendMessage(text);
                          _msgController.clear();
                          setState(() {});
                        }
                      },
                      child: const Icon(Icons.send),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
