// BotController: automates bot actions in night and voting phases

import 'dart:math';

import '../models/player.dart';
import '../models/game_state.dart';
import 'game_manager.dart';
import 'game_rules.dart';

class BotController {
  final GameManager manager;
  final Random _rng = Random();

  BotController(this.manager);

  // Trigger night actions after a delay (slightly longer to allow humans to act first)
  void onNightPhase() async {
    await Future.delayed(
        Duration(seconds: _rng.nextInt(6) + 3)); // 3-8 second delay
    _performNightActions();
  }

  // Trigger voting actions after a delay
  void onVotingPhase() async {
    await Future.delayed(
        Duration(seconds: _rng.nextInt(4) + 3)); // 3-6 second delay
    _performVoting();
  }

  // Trigger chat messages during discussion
  void onDiscussionPhase() async {
    final bots = manager.players.where((p) => p.isAlive && p.isBot).toList();
    if (bots.isEmpty) return;

    // Shuffle bots to randomize who speaks
    final speakingBots = List<Player>.from(bots)..shuffle(_rng);

    // Each discussion phase, a few bots will say something
    int numMessages = _rng.nextInt(3) + 2;

    for (int i = 0; i < numMessages; i++) {
      // Wait between messages
      await Future.delayed(Duration(seconds: _rng.nextInt(3) + 2));
      if (manager.phase != GamePhase.discussion) break;

      final bot = speakingBots[i % speakingBots.length];
      final text = _generateChatMessage(bot);
      manager.sendChatMessage(bot.id, text);
    }
  }

  /// Send a short greeting/message in the lobby when a bot is added
  void sendLobbyGreeting(Player bot) async {
    if (!bot.isBot) return;
    final messages = [
      "Hello! Ready to play.",
      "Hi everyone, I'm here.",
      "Looking forward to the game!",
      "Good luck, everyone.",
    ];

    await Future.delayed(Duration(seconds: _rng.nextInt(3) + 1));
    // Use manager method that broadcasts lobby chat from bot
    manager.sendLobbyChatMessageFromBot(
        bot.id, messages[_rng.nextInt(messages.length)]);
  }

  String _generateChatMessage(Player bot) {
    final phrases = [
      "I think I saw something suspicious last night...",
      "Who do we think is the Mafia?",
      "I'm just a simple civilian, I swear!",
      "Does anyone have any leads?",
      "That last elimination was a mistake.",
      "I'm keeping my eye on everyone.",
      "The silence is suspicious...",
      "We need to find them before it's too late.",
      "I don't trust anyone right now.",
      "What if the Mafia is hiding among us?",
    ];

    if (bot.personality == BotPersonality.aggressive) {
      phrases.addAll([
        "I'm pretty sure it's one of you!",
        "Stop acting so innocent.",
        "We need to execute a mission against the Mafia NOW.",
        "You're awfully quiet... suspicious.",
      ]);
    }

    return phrases[_rng.nextInt(phrases.length)];
  }

  void _performNightActions() {
    // 1. Mafia / Godfather voting
    final mafiaBots = manager.players
        .where((p) =>
            p.isAlive &&
            p.isBot &&
            (p.role == Role.mafia || p.role == Role.godfather))
        .toList();
    final potentialTargets = manager.aliveNonMafia();

    if (mafiaBots.isNotEmpty && potentialTargets.isNotEmpty) {
      String? coordinatedTarget;
      for (final mafia in mafiaBots) {
        if (coordinatedTarget != null && _rng.nextDouble() < 0.7) {
          manager.submitMafiaVote(mafia.id, coordinatedTarget);
        } else {
          final target =
              potentialTargets[_rng.nextInt(potentialTargets.length)];
          manager.submitMafiaVote(mafia.id, target.id);
          coordinatedTarget ??= target.id;
        }
      }
    }

    // 2. Doctor save
    final doctorBots = manager.players
        .where((p) => p.isAlive && p.isBot && p.role == Role.doctor)
        .toList();
    final alivePlayers = manager.alivePlayers;
    if (doctorBots.isNotEmpty && alivePlayers.length > 1) {
      final actingDoctor = doctorBots.first;
      final saveTargets =
          alivePlayers.where((p) => p.id != actingDoctor.id).toList();
      if (saveTargets.isNotEmpty) {
        final target = saveTargets[_rng.nextInt(saveTargets.length)];
        manager.handleNightAction(actingDoctor.id, target.id);
      }
    }

    // 3. Detective inspect
    final detectiveBots = manager.players
        .where((p) => p.isAlive && p.isBot && p.role == Role.detective)
        .toList();
    if (detectiveBots.isNotEmpty && alivePlayers.length > 1) {
      final actingDetective = detectiveBots.first;
      final inspectTargets =
          alivePlayers.where((p) => p.id != actingDetective.id).toList();
      if (inspectTargets.isNotEmpty) {
        final target = inspectTargets[_rng.nextInt(inspectTargets.length)];
        manager.handleNightAction(actingDetective.id, target.id);
      }
    }

    // 4. Vigilante shoot (limited ammo)
    final vigBots = manager.players
        .where((p) => p.isAlive && p.isBot && p.role == Role.vigilante)
        .toList();
    for (final vig in vigBots) {
      if (vig.bullets > 0 && _rng.nextDouble() < 0.4) {
        // Only shoot if they feel bold (40% chance)
        final targets = alivePlayers.where((p) => p.id != vig.id).toList();
        if (targets.isNotEmpty) {
          final target = targets[_rng.nextInt(targets.length)];
          manager.handleNightAction(vig.id, target.id);
        }
      } else {
        // Still need to "complete" night action even if not shooting
        manager.handleNightAction(vig.id, ''); // Empty target = no action
      }
    }

    // 5. Serial Killer kill
    final skBots = manager.players
        .where((p) => p.isAlive && p.isBot && p.role == Role.serialKiller)
        .toList();
    for (final sk in skBots) {
      final targets = alivePlayers.where((p) => p.id != sk.id).toList();
      if (targets.isNotEmpty) {
        final target = targets[_rng.nextInt(targets.length)];
        manager.handleNightAction(sk.id, target.id);
      }
    }

    // 6. Escort block
    final escortBots = manager.players
        .where((p) => p.isAlive && p.isBot && p.role == Role.escort)
        .toList();
    for (final escort in escortBots) {
      final targets = alivePlayers.where((p) => p.id != escort.id).toList();
      if (targets.isNotEmpty) {
        final target = targets[_rng.nextInt(targets.length)];
        manager.handleNightAction(escort.id, target.id);
      }
    }
  }

  void _performVoting() {
    final bots = manager.players.where((p) => p.isAlive && p.isBot).toList();
    for (final bot in bots) {
      final choice = _chooseVote(bot);
      if (choice != null) {
        manager.castVote(bot.id, choice.id);
      }
    }
  }

  Player? _chooseVote(Player bot) {
    final alive = manager.alivePlayers.where((p) => p.id != bot.id).toList();
    if (alive.isEmpty) return null;

    // Self-preservation: if bot is receiving votes, it might panic
    final votesAgainstBot = manager.getVoteCount(bot.id);
    if (votesAgainstBot > 0 && _rng.nextDouble() < 0.5) {
      // Panic and vote with the majority to deflect suspicion
      final majorityTarget = GameRules.majorityTarget(manager.votes);
      if (majorityTarget != null && majorityTarget != bot.id) {
        return manager.players.firstWhere((p) => p.id == majorityTarget);
      }
    }

    switch (bot.personality) {
      case BotPersonality.aggressive:
        // Target players who have voted for this bot in the past (grudge)
        for (final pastVotes in manager.voteHistory.reversed) {
          // This is a simplified grudge check. A real implementation might
          // need to check who voted *for the bot*. This checks who the bot voted for.
          // For a true grudge, you'd need to invert the vote map.
          final voter = pastVotes.entries
              .firstWhere((entry) => entry.value == bot.id,
                  orElse: () => const MapEntry('', ''))
              .key;
          if (voter.isNotEmpty) {
            final target = alive.firstWhere((p) => p.id == voter,
                orElse: () => alive.first);
            if (target.isAlive) return target;
          }
        }
        // Fallback: target someone who voted last round
        final lastVoters = manager.lastRoundVoters();
        final candidates =
            alive.where((p) => lastVoters.contains(p.id)).toList();
        return candidates.isNotEmpty
            ? candidates[_rng.nextInt(candidates.length)]
            : alive[_rng.nextInt(alive.length)];

      case BotPersonality.quiet:
        // Wait and copy the majority vote, with a chance of error
        if (manager.votes.isNotEmpty && _rng.nextDouble() < 0.8) {
          final majorityTargetId = GameRules.majorityTarget(manager.votes);
          if (majorityTargetId != null) {
            return manager.players.firstWhere((p) => p.id == majorityTargetId);
          }
        }
        // Fallback: random vote
        return alive[_rng.nextInt(alive.length)];

      case BotPersonality.random:
      default:
        // Fully random vote
        return alive[_rng.nextInt(alive.length)];
    }
  }
}
