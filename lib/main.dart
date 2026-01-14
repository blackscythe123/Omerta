import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'game/game_manager.dart';
import 'screens/home_screen.dart';
import 'screens/name_entry_screen.dart';
import 'screens/room_discovery_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/role_reveal_screen.dart';
import 'screens/game_screen.dart';
import 'screens/waiting_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/error_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MafiaApp());
}

class MafiaApp extends StatelessWidget {
  const MafiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameManager(),
      child: MaterialApp(
        title: 'Mafia',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/splash',
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return _buildRoute(const SplashScreen(), settings);

        // return _buildRoute(const HomeScreenNew(), settings);

      case '/name-entry':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          NameEntryScreen(isHost: args?['isHost'] ?? false),
          settings,
        );

      case '/room-discovery':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          RoomDiscoveryScreen(playerName: args?['name'] ?? 'Player'),
          settings,
        );

      case '/lobby':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          LobbyScreenNew(
            playerName: args?['name'] ?? 'Player',
            isHost: args?['isHost'] ?? false,
            roomName: args?['roomName'],
          ),
          settings,
        );

      case '/role-reveal':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          RoleRevealScreen(
            role: args?['role'] ?? GameRole.villager,
            teammates: args?['teammates'],
          ),
          settings,
        );

      case '/game':
        return _buildRoute(const GameScreenNew(), settings);

      case '/waiting':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          WaitingScreen(
            reason: args?['reason'] ?? WaitingReason.otherPlayers,
            message: args?['message'],
          ),
          settings,
        );

      case '/game-over':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          GameOverScreen(
            winner: args?['winner'] ?? WinningTeam.town,
            playerRole: args?['playerRole'],
            didWin: args?['didWin'] ?? true,
          ),
          settings,
        );

      case '/how-to-play':
        return _buildRoute(const HowToPlayScreenNew(), settings);

      case '/error':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ErrorScreen(
            errorType: args?['errorType'] ?? ErrorType.unknown,
            customMessage: args?['message'],
            onRetry: args?['onRetry'],
          ),
          settings,
        );

      case '/settings':
        return _buildRoute(const SettingsScreen(), settings);

      default:
        return _buildRoute(const HomeScreenNew(), settings);
    }
  }

  PageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
