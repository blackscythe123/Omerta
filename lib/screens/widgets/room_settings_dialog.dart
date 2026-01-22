import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Room settings dialog for hosts
/// Allows configuring max players, privacy, PIN, chat, and moderator mode
class RoomSettingsDialog extends StatefulWidget {
  final int currentMaxPlayers;
  final bool currentIsPrivate;
  final String? currentPin;
  final bool currentChatEnabled;
  final bool currentModeratorMode;
  final bool currentBotEnabled;
  final int currentBotCount;
  final Function({
    int? maxPlayers,
    bool? isPrivate,
    String? newPin,
    bool? chatEnabled,
    bool? moderatorMode,
    bool? botsEnabled,
    int? botCount,
  }) onSave;

  const RoomSettingsDialog({
    super.key,
    required this.currentMaxPlayers,
    required this.currentIsPrivate,
    this.currentPin,
    required this.currentChatEnabled,
    required this.currentModeratorMode,
    this.currentBotEnabled = false,
    this.currentBotCount = 0,
    required this.onSave,
  });

  @override
  State<RoomSettingsDialog> createState() => _RoomSettingsDialogState();
}

class _RoomSettingsDialogState extends State<RoomSettingsDialog> {
  late int _maxPlayers;
  late bool _isPrivate;
  late String _pin;
  late bool _chatEnabled;
  late bool _moderatorMode;
  late bool _botsEnabled;
  late int _botCount;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _maxPlayers = widget.currentMaxPlayers;
    _isPrivate = widget.currentIsPrivate;
    _pin = widget.currentPin ?? '';
    _chatEnabled = widget.currentChatEnabled;
    _moderatorMode = widget.currentModeratorMode;
    _botsEnabled = widget.currentBotEnabled;
    _botCount = widget.currentBotCount;
    _pinController.text = _pin;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Room Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Max Players Slider
            const Text(
              'Max Players',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxPlayers.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 15,
                    label: _maxPlayers.toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxPlayers = value.toInt();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _maxPlayers.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Private Room Toggle
            SwitchListTile(
              title: const Text('Private Room'),
              subtitle: const Text('Require PIN to join'),
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // PIN Input (only if private)
            if (_isPrivate) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'Room PIN',
                  hintText: '4-digit PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                maxLength: 4,
                onChanged: (value) {
                  _pin = value;
                },
              ),
            ],
            const SizedBox(height: 8),

            // Chat Enabled Toggle
            SwitchListTile(
              title: const Text('Enable Lobby Chat'),
              subtitle: const Text('Allow players to chat before game starts'),
              value: _chatEnabled,
              onChanged: (value) {
                setState(() {
                  _chatEnabled = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),

            // Bots Toggle
            SwitchListTile(
              title: const Text('Enable Bots'),
              subtitle: const Text(
                  'Allow host-added bots to fill the lobby (local only)'),
              value: _botsEnabled,
              onChanged: (value) {
                setState(() {
                  _botsEnabled = value;
                  if (!value) _botCount = 0;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Bot count slider (only if bots enabled)
            if (_botsEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Bot Count',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _botCount.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: _botCount.toString(),
                      onChanged: (value) {
                        setState(() {
                          _botCount = value.toInt();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      _botCount.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Moderator Mode Toggle
            SwitchListTile(
              title: const Text('Moderator Mode'),
              subtitle: const Text('Coming Soon - UI only'),
              value: _moderatorMode,
              onChanged: (value) {
                setState(() {
                  _moderatorMode = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),

            // Characters Section (Coming Soon)
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Characters'),
              subtitle: const Text('Coming Soon'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: null, // Disabled
              enabled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate PIN if private
            if (_isPrivate && _pin.length != 4) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN must be 4 digits'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            widget.onSave(
              maxPlayers:
                  _maxPlayers != widget.currentMaxPlayers ? _maxPlayers : null,
              isPrivate:
                  _isPrivate != widget.currentIsPrivate ? _isPrivate : null,
              newPin: _isPrivate && _pin != widget.currentPin ? _pin : null,
              chatEnabled: _chatEnabled != widget.currentChatEnabled
                  ? _chatEnabled
                  : null,
              moderatorMode: _moderatorMode != widget.currentModeratorMode
                  ? _moderatorMode
                  : null,
              botsEnabled: _botsEnabled != widget.currentBotEnabled
                  ? _botsEnabled
                  : null,
              botCount: _botCount != widget.currentBotCount ? _botCount : null,
            );

            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
