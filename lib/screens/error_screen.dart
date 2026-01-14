import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

enum ErrorType { disconnected, connectionFailed, roomClosed, kicked, unknown }

class ErrorScreen extends StatelessWidget {
  final ErrorType errorType;
  final String? customMessage;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    this.errorType = ErrorType.unknown,
    this.customMessage,
    this.onRetry,
  });

  IconData get _icon {
    switch (errorType) {
      case ErrorType.disconnected:
        return Icons.wifi_off;
      case ErrorType.connectionFailed:
        return Icons.signal_wifi_bad;
      case ErrorType.roomClosed:
        return Icons.meeting_room;
      case ErrorType.kicked:
        return Icons.person_remove;
      case ErrorType.unknown:
      default:
        return Icons.error_outline;
    }
  }

  String get _title {
    switch (errorType) {
      case ErrorType.disconnected:
        return 'DISCONNECTED';
      case ErrorType.connectionFailed:
        return 'CONNECTION FAILED';
      case ErrorType.roomClosed:
        return 'ROOM CLOSED';
      case ErrorType.kicked:
        return 'REMOVED';
      case ErrorType.unknown:
      default:
        return 'ERROR';
    }
  }

  String get _message {
    if (customMessage != null) return customMessage!;
    switch (errorType) {
      case ErrorType.disconnected:
        return 'You have been disconnected from the game. Please check your network connection and try again.';
      case ErrorType.connectionFailed:
        return 'Could not connect to the game room. Make sure you\'re on the same network as the host.';
      case ErrorType.roomClosed:
        return 'The host has closed the room. You can create a new room or join another game.';
      case ErrorType.kicked:
        return 'You have been removed from the game by the host.';
      case ErrorType.unknown:
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppColors.error.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _icon,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _title,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _message,
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                if (onRetry != null)
                  PrimaryButtonLarge(
                    label: 'TRY AGAIN',
                    icon: Icons.refresh,
                    onPressed: onRetry,
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('BACK TO HOME'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
