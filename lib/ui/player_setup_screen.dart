import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_manager.dart';
import '../models/game_state.dart';
import 'lobby_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  int _selectedPlayerCount = 7;

  @override
  Widget build(BuildContext context) {
    final config = GameConfig.forPlayerCount(_selectedPlayerCount);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('OPERATION SETUP',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.red.withOpacity(0.05),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.settings_suggest,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'MISSION PARAMETERS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Player count selector
                        _buildPlayerCountSelector(),

                        const SizedBox(height: 24),

                        // Role distribution card
                        _buildRoleDistributionCard(config),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Continue button
                ElevatedButton(
                  onPressed: () {
                    final manager = context.read<GameManager>();
                    manager.setPlayerCount(_selectedPlayerCount);
                    manager.initializeSoloGame(
                        playerCount: _selectedPlayerCount);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LobbyScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 10,
                    shadowColor: Colors.redAccent.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'INITIALIZE MISSION',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_ios,
                          size: 20, fontWeight: FontWeight.bold),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCountSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'FIELD AGENTS REQUIRED',
            style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            '$_selectedPlayerCount',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: GameConfig.playerCountOptions.map((count) {
              final isSelected = count == _selectedPlayerCount;
              return GestureDetector(
                onTap: () => setState(() => _selectedPlayerCount = count),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? Colors.redAccent
                            : Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistributionCard(GameConfig config) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PERSONNEL ALLOCATION:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRoleRow(Icons.person_off, 'MAFIA AGENTS', config.mafiaCount,
              Colors.redAccent),
          if (config.godfatherCount > 0) ...[
            const SizedBox(height: 12),
            _buildRoleRow(Icons.security, 'THE GODFATHER',
                config.godfatherCount, Colors.red.shade300),
          ],
          const SizedBox(height: 12),
          _buildRoleRow(Icons.medical_services, 'ON-FIELD DOCTOR',
              config.doctorCount, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildRoleRow(Icons.search, 'INTEL DETECTIVE', config.detectiveCount,
              Colors.blueAccent),
          if (config.vigilanteCount > 0) ...[
            const SizedBox(height: 12),
            _buildRoleRow(Icons.gps_fixed, 'VIGILANTE', config.vigilanteCount,
                Colors.orangeAccent),
          ],
          if (config.serialKillerCount > 0) ...[
            const SizedBox(height: 12),
            _buildRoleRow(Icons.warning_amber, 'SERIAL KILLER',
                config.serialKillerCount, Colors.purpleAccent),
          ],
          if (config.escortCount > 0) ...[
            const SizedBox(height: 12),
            _buildRoleRow(
                Icons.block, 'ESCORT', config.escortCount, Colors.pinkAccent),
          ],
          const SizedBox(height: 12),
          _buildRoleRow(Icons.person, 'CIVILIAN COHORTS', config.villagerCount,
              Colors.grey),
        ],
      ),
    );
  }

  Widget _buildRoleRow(IconData icon, String role, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            role,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
