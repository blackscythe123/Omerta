import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HowToPlayScreenNew extends StatefulWidget {
  const HowToPlayScreenNew({super.key});

  @override
  State<HowToPlayScreenNew> createState() => _HowToPlayScreenNewState();
}

class _HowToPlayScreenNewState extends State<HowToPlayScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_RoleInfo> _roles = [
    _RoleInfo('VILLAGER', Icons.person, AppColors.town,
        'Use logic and discussion to find the Mafia. Vote to eliminate suspects.'),
    _RoleInfo('MAFIA', Icons.person_off, AppColors.mafia,
        'Each night, vote with your team to eliminate a player. Blend in during the day.'),
    _RoleInfo('GODFATHER', Icons.security, AppColors.mafia,
        'Lead the Mafia. You appear innocent to the Detective.'),
    _RoleInfo('DOCTOR', Icons.medical_services, Colors.green,
        'Each night, protect one player from being killed.'),
    _RoleInfo('DETECTIVE', Icons.search, Colors.blue,
        'Each night, investigate one player to learn their alignment.'),
    _RoleInfo('VIGILANTE', Icons.gps_fixed, Colors.orange,
        'You have limited bullets to eliminate suspects at night.'),
    _RoleInfo('ESCORT', Icons.block, Colors.pink,
        'Each night, block one player from using their ability.'),
    _RoleInfo('SERIAL KILLER', Icons.warning_amber, Colors.purple,
        'Kill every night. Win by being the last one standing.'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOW TO PLAY'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'BASICS'),
            Tab(text: 'ROLES'),
            Tab(text: 'PHASES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicsTab(),
          _buildRolesTab(),
          _buildPhasesTab(),
        ],
      ),
    );
  }

  Widget _buildBasicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            icon: Icons.groups,
            title: 'THE GAME',
            content:
                'Mafia is a social deduction game. Players are secretly assigned roles: Town (good) or Mafia (evil). The Town must identify and eliminate all Mafia members, while the Mafia tries to outnumber the Town.',
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.flag,
            title: 'OBJECTIVES',
            content:
                '• Town: Eliminate all Mafia members\n• Mafia: Equal or outnumber the Town\n• Serial Killer: Be the last one standing',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.wifi_tethering,
            title: 'LAN PLAY',
            content:
                'This game is designed for local network play. One player hosts the game, and others join using the same Wi-Fi or hotspot. No internet required!',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final role = _roles[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: role.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(role.icon, color: role.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: role.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.description,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhasesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPhaseCard(
            number: '1',
            title: 'NIGHT',
            description:
                'The city sleeps. Mafia chooses a victim, special roles perform their actions.',
            icon: Icons.nightlight_round,
            color: Colors.indigo,
          ),
          _buildPhaseConnector(),
          _buildPhaseCard(
            number: '2',
            title: 'MORNING',
            description:
                'The night\'s results are revealed. Discover who was eliminated.',
            icon: Icons.wb_sunny,
            color: Colors.orange,
          ),
          _buildPhaseConnector(),
          _buildPhaseCard(
            number: '3',
            title: 'DISCUSSION',
            description:
                'Players discuss, share suspicions, and defend themselves.',
            icon: Icons.forum,
            color: AppColors.primary,
          ),
          _buildPhaseConnector(),
          _buildPhaseCard(
            number: '4',
            title: 'VOTING',
            description:
                'Players vote to eliminate one person. Majority rules.',
            icon: Icons.how_to_vote,
            color: AppColors.error,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.loop, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Phases repeat until one team wins',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(title, style: AppTextStyles.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseConnector() {
    return Container(
      width: 2,
      height: 24,
      margin: const EdgeInsets.only(left: 39),
      color: AppColors.cardBorder,
    );
  }
}

class _RoleInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  _RoleInfo(this.name, this.icon, this.color, this.description);
}
