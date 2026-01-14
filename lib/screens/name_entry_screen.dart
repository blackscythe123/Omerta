import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../game/game_manager.dart';
// import '../network/lan_communication.dart';

class NameEntryScreen extends StatefulWidget {
  final bool isHost;

  const NameEntryScreen({super.key, this.isHost = false});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isValid = false;
  bool _isLoading = false;
  bool _isPrivate = false; // Toggle for private room

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateInput);
    _roomController.addListener(_validateInput);
    _pinController.addListener(_validateInput);
    // Set default room name
    if (widget.isHost) {
      _roomController.text = 'Mafia Room';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      final nameValid = _nameController.text.trim().length >= 2;
      final roomValid =
          !widget.isHost || _roomController.text.trim().isNotEmpty;
      // PIN must be exactly 4 digits if private room
      final pinValid = !_isPrivate ||
          (_pinController.text.length == 4 &&
              RegExp(r'^\d{4}$').hasMatch(_pinController.text));
      _isValid = nameValid && roomValid && pinValid;
    });
  }

  Future<void> _continue() async {
    if (!_isValid || _isLoading) return;

    // Check platform support for LAN
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'LAN multiplayer is not supported on web. Please use the Android or Windows app.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final manager = context.read<GameManager>();

    if (widget.isHost) {
      final roomName = _roomController.text.trim();
      final pin = _isPrivate ? _pinController.text.trim() : null;

      setState(() => _isLoading = true);

      final success = await manager.createLANRoom(
        name,
        roomName,
        isPrivate: _isPrivate,
        pin: pin,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushNamed(context, '/lobby', arguments: {
          'name': name,
          'isHost': true,
          'roomName': roomName,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to create room. Check your network connection.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      Navigator.pushNamed(context, '/room-discovery',
          arguments: {'name': name});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'CREATE ROOM' : 'JOIN GAME'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'ENTER YOUR NAME',
                    style: AppTextStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is how other players will see you',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge,
                    decoration: const InputDecoration(
                      hintText: 'Your name',
                      counterText: '',
                    ),
                    maxLength: 16,
                    onSubmitted: (_) => _continue(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Min 2 characters, max 16',
                    style: AppTextStyles.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.isHost) ...[
                    const SizedBox(height: 32),
                    Text(
                      'ROOM NAME',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _roomController,
                      textCapitalization: TextCapitalization.words,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium,
                      decoration: const InputDecoration(
                        hintText: 'Room name',
                        counterText: '',
                      ),
                      maxLength: 24,
                    ),
                    const SizedBox(height: 24),
                    // Public/Private toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isPrivate ? Icons.lock : Icons.lock_open,
                                    color: _isPrivate
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isPrivate ? 'PRIVATE ROOM' : 'PUBLIC ROOM',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: _isPrivate
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isPrivate,
                                onChanged: (value) {
                                  setState(() {
                                    _isPrivate = value;
                                    if (!value) {
                                      _pinController.clear();
                                    }
                                    _validateInput();
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                          if (_isPrivate) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Enter a 4-digit PIN for players to join',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headlineLarge.copyWith(
                                letterSpacing: 12,
                              ),
                              decoration: InputDecoration(
                                hintText: '• • • •',
                                hintStyle: AppTextStyles.headlineLarge.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 8,
                                ),
                                counterText: '',
                              ),
                              maxLength: 4,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                  PrimaryButtonLarge(
                    label: widget.isHost ? 'CREATE ROOM' : 'CONTINUE',
                    icon: Icons.arrow_forward,
                    onPressed: _isValid && !_isLoading ? _continue : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
