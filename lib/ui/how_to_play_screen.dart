import 'package:flutter/material.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeRoleIndex = 0;

  final List<Map<String, dynamic>> _roles = [
    {
      'role': 'MAFIA AGENT',
      'icon': Icons.person_off,
      'color': Colors.redAccent,
      'description':
          'The predators. Each night, they wake up and coordinate to choose a victim.',
      'ability': 'SECRET KILL (CONSENSUS)',
      'lore': 'Infiltrators in the town, working to eliminate all witnesses.'
    },
    {
      'role': 'THE GODFATHER',
      'icon': Icons.security,
      'color': Colors.red,
      'description':
          'The leader of the Mafia. Appears innocent to the Detective\'s investigation.',
      'ability': 'IMMUNITY TO INVESTIGATION',
      'lore': 'The mastermind who stays clean even when the heat is on.'
    },
    {
      'role': 'INTEL DETECTIVE',
      'icon': Icons.search,
      'color': Colors.blueAccent,
      'description':
          'The investigator. Can check one player each night to see if they are Mafia.',
      'ability': 'INVESTIGATE A PLAYER',
      'lore':
          'Every shadow has a face. Finding them is the only way to save the town.'
    },
    {
      'role': 'ON-FIELD DOCTOR',
      'icon': Icons.local_hospital,
      'color': Colors.greenAccent,
      'description':
          'The protector. Can save one person each night from being killed.',
      'ability': 'PROTECT ONE PLAYER',
      'lore':
          'In the dead of night, they are the thin line between life and death.'
    },
    {
      'role': 'VIGILANTE',
      'icon': Icons.gps_fixed,
      'color': Colors.orangeAccent,
      'description':
          'The town executioner. Has limited bullets to eliminate those they suspect.',
      'ability': 'ELIMINATE SUSPECT (LIMITED)',
      'lore': 'Taking the law into their own hands, for better or worse.'
    },
    {
      'role': 'ESCORT',
      'icon': Icons.block,
      'color': Colors.pinkAccent,
      'description':
          'The distractor. Can block a player from performing their night action.',
      'ability': 'BLOCK NIGHT ACTION',
      'lore':
          'A charming distraction that keeps even the deadliest agents at bay.'
    },
    {
      'role': 'SERIAL KILLER',
      'icon': Icons.warning_amber,
      'color': Colors.purpleAccent,
      'description':
          'The wild card. Wins by being the last one standing. Kills anyone, every night.',
      'ability': 'NIGHTLY KILLING SPREE',
      'lore': 'No side. No friends. Only the thrill of the hunt.'
    },
    {
      'role': 'MISSION MODERATOR',
      'icon': Icons.gavel,
      'color': Colors.amberAccent,
      'description':
          'The narrator. Controls game phases and sees all player roles in Offline mode.',
      'ability': 'MANUAL PHASE ADVANCE',
      'lore': 'The invisible hand that guides the syndicate mission.'
    },
    {
      'role': 'CIVILIAN COHORT',
      'icon': Icons.person_outline,
      'color': Colors.grey,
      'description':
          'The common folk. They have no special powers but must use logic to find the Mafia.',
      'ability': 'VOTE DURING THE DAY',
      'lore': 'Strength in numbers. Their only weapon is their voice.'
    },
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
      backgroundColor: const Color(0xFF0F0F15),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SYNDICATE MANUAL',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 18,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(width: 4.0, color: Colors.redAccent),
            insets: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1),
          ),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          unselectedLabelColor: Colors.white24,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'INTEL'),
            Tab(text: 'AGENTS'),
            Tab(text: 'MISSION'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.5,
            colors: [
              Colors.red.withOpacity(0.12),
              const Color(0xFF0F0F15),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildConceptTab(),
            _buildRolesTab(),
            _buildProcessTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 120, left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(
            'THE WAR OF SHADOWS',
            'Mafia is a social deduction thriller. Two groups struggle in the dark: The uninformed majority (Town) and the informed, lethal minority (Mafia).',
            Icons.gavel,
          ),
          const SizedBox(height: 32),
          const Text(
            'CORE DIRECTIVES:',
            style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            'THE OBJECTIVE',
            '• TOWN: Identify and eliminate every single Mafia member.\n• MAFIA: Eliminate Townies until you control the board.',
            Icons.flag,
            Colors.amber,
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            'COMMUNICATION',
            'In SOLO MODE, you interact with advanced AI bots via chat. In OFFLINE MODE, the game acts as a technical moderator for your real-life social circle.',
            Icons.record_voice_over,
            Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    return Column(
      children: [
        const SizedBox(height: 120),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AGENT PROFILES',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
              Text(
                '${_activeRoleIndex + 1}/${_roles.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: PageView.builder(
            itemCount: _roles.length,
            onPageChanged: (idx) => setState(() => _activeRoleIndex = idx),
            controller: PageController(viewportFraction: 0.85),
            itemBuilder: (context, index) {
              final role = _roles[index];
              final bool active = index == _activeRoleIndex;
              final Color color = role['color'];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                margin: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  bottom: 40,
                  top: active ? 0 : 40,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: active
                          ? color.withOpacity(0.5)
                          : Colors.white.withOpacity(0.05),
                      width: 2),
                  boxShadow: [
                    if (active)
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: -10,
                      )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Icon(role['icon'],
                            size: 200, color: color.withOpacity(0.05)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(role['icon'], color: color, size: 32),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              role['role'],
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              role['lore'],
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 16),
                            Text(
                              role['description'],
                              style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.5,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PRIMARY ABILITY',
                                    style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role['ability'],
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProcessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 120, left: 24, right: 24, bottom: 24),
      child: Column(
        children: [
          _buildStep(
              1,
              'THE NIGHT FALLS',
              'The city sleeps, but the syndicate awakens. Mafia chooses a target, Doctor heals, and specialists perform their secret maneuvers.',
              Icons.nightlight_round,
              Colors.indigoAccent),
          _buildStep(
              2,
              'THE MORNING AFTER',
              'Sunrise reveals the casualties. The town discovers who was eliminated during the cold hours of the night.',
              Icons.wb_sunny,
              Colors.orangeAccent),
          _buildStep(
              3,
              'SYNDICATE DEBATE',
              'Suspicion spreads. Use the chat to bluff, investigate, or defend yourself. Logic is your only shield.',
              Icons.forum,
              Colors.deepOrangeAccent),
          _buildStep(
              4,
              'THE VERDICT',
              'The majority rules. Cast your vote to eliminate the most suspicious individual. One player is exiled every day.',
              Icons.how_to_vote,
              Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child:
                  Icon(icon, size: 200, color: Colors.white.withOpacity(0.02)),
            ),
            // Header Accents
            Positioned(
              top: 0,
              left: 40,
              child: Container(
                width: 2,
                height: 40,
                color: Colors.redAccent.withOpacity(0.3),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CLASSIFIED DOCUMENT // PROJECT SYNDICATE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(text,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white54, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
      int num, String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('PHASE $num',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1)),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text(desc,
              style: const TextStyle(
                  color: Colors.white54, height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}
