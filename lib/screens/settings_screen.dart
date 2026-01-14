import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _nightModeAnimation = true;
  double _discussionTime = 90;
  double _votingTime = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GENERAL', style: AppTextStyles.labelSmall),
            const SizedBox(height: 16),
            _buildSwitchTile(
              icon: Icons.volume_up,
              title: 'Sound Effects',
              subtitle: 'Play sounds for game events',
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              icon: Icons.vibration,
              title: 'Vibration',
              subtitle: 'Haptic feedback for actions',
              value: _vibrationEnabled,
              onChanged: (v) => setState(() => _vibrationEnabled = v),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              icon: Icons.animation,
              title: 'Day/Night Animations',
              subtitle: 'Show phase transition effects',
              value: _nightModeAnimation,
              onChanged: (v) => setState(() => _nightModeAnimation = v),
            ),
            const SizedBox(height: 32),
            Text('GAME TIMERS', style: AppTextStyles.labelSmall),
            const SizedBox(height: 16),
            _buildSliderTile(
              icon: Icons.forum,
              title: 'Discussion Time',
              value: _discussionTime,
              min: 30,
              max: 180,
              divisions: 5,
              suffix: 's',
              onChanged: (v) => setState(() => _discussionTime = v),
            ),
            const SizedBox(height: 16),
            _buildSliderTile(
              icon: Icons.how_to_vote,
              title: 'Voting Time',
              value: _votingTime,
              min: 15,
              max: 60,
              divisions: 3,
              suffix: 's',
              onChanged: (v) => setState(() => _votingTime = v),
            ),
            const SizedBox(height: 32),
            Text('ABOUT', style: AppTextStyles.labelSmall),
            const SizedBox(height: 16),
            _buildInfoTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: '1.0.0',
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              icon: Icons.code,
              title: 'Built with',
              subtitle: 'Flutter',
            ),
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Reset All Settings'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: AppTextStyles.titleMedium),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toInt()}$suffix',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: AppTextStyles.titleMedium),
          ),
          Text(
            subtitle,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
