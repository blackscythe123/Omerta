# Mafia Game (Flutter)

:crossed_swords: **Mafia — Offline LAN (UDP/TCP) multiplayer + Solo bots**

This repository contains a Flutter game that supports local offline multiplayer over LAN (UDP-based room discovery + TCP for reliable game sync) and a solo mode with AI bots.

---

## 🔑 Key Features

- Fully offline LAN multiplayer
  - UDP broadcast discovery (port 41234)
  - TCP server/client communication (port 41235)
  - Host-authoritative: host keeps canonical game state and broadcasts state updates
- Solo mode with AI-controlled bots (no networking required)
- QR / IP-based join fallback (scan QR or enter host IP to connect directly)
- Animated in-app splash + native splash (Android/iOS)
- Cross-platform: Android, Windows (desktop), Web (UI only — LAN not supported in browser)

---

## 📁 Project structure (important files)

- lib/
  - game/
    - game_manager.dart — central game state and logic (ChangeNotifier)
    - bot_controller.dart — bot behavior
    - game_rules.dart — role setup & win conditions
  - network/
    - lan_communication.dart — UDP discovery + TCP client/server implementation
    - game_communication.dart — interface for communication layer
  - screens/
    - home_screen.dart, name_entry_screen.dart, room_discovery_screen.dart, lobby_screen.dart
    - splash_screen.dart — animated Flutter splash (runs after native splash)
  - models/
    - player.dart, game_state.dart
  - widgets/
    - room_tile.dart, player_card.dart, etc.

- assets/
  - images/icon.png — app icon (used for launcher & splash)
  - images/background.png

---

## 🛠 Development setup

Requirements:
- Flutter 3.x/4.x SDK
- Android SDK (for building APK)
- Windows tooling (if targeting desktop)

Commands:

- Install dependencies

  ```bash
  flutter pub get
  ```

- Static analysis

  ```bash
  flutter analyze
  ```

- Run (Windows desktop)

  ```bash
  flutter run -d windows
  ```

- Run (Android emulator or device)

  ```bash
  flutter run -d <device-id>
  ```

- Build release APK (split per ABI)

  ```bash
  flutter build apk --release --split-per-abi
  ```

- Build Windows executable

  ```bash
  flutter build windows --release
  ```

---

## 🧭 Networking details (LAN)

- UDP discovery
  - Host broadcasts a JSON message containing RoomInfo every 2 seconds to UDP port **41234**.
  - Clients listen on UDP port **41234** and parse broadcasts to show available rooms.
- TCP communication
  - Host opens a TCP server on port **41235** and accepts client sockets.
  - All game actions and state sync use JSON over TCP with line-delimited messages.
- Fall-back when discovery fails
  - Manual "Join by IP" dialog
  - QR Code contains host IP (and optional port) so players can scan and connect
- Important: Devices must be on the same network (same WiFi/subnet). Firewalls on host machines may block UDP/TCP — temporarily disable or allow the app during testing.

---

## 📱 QR & IP Join

- Host: in the **Lobby** the host's local IP is shown (tap to copy). Tap QR icon to show a QR code containing the IP (e.g., `192.168.1.100` or `192.168.1.100:41235`).
- Client: in **Find Room** screen, choose "JOIN BY IP ADDRESS" or "SCAN QR". Scanning the QR attempts a direct TCP connect.

---

## 🎨 Icon & Splash

- App icon is `assets/images/icon.png` and launcher icons were generated via `flutter_launcher_icons`.
- Native splash screens were generated with `flutter_native_splash` (color set to #0A0A0A and using the same icon).
- The Flutter animated splash (`lib/screens/splash_screen.dart`) plays right after native splash and then navigates to the Home screen.

---

## ⚙️ Android / iOS permissions

- Android: CAMERA (for QR scan) is declared in AndroidManifest; INTERNET is also required.
- iOS: NSCameraUsageDescription added to Info.plist.

---

## ✅ Testing checklist

- [ ] Verify `flutter analyze` shows no errors (only warnings/info about deprecations).
- [ ] Host on Windows and confirm UDP broadcasts appear (logs show "Hosting started: ... at IP:41235").
- [ ] On Android device (same WiFi), open Find Room and verify host appears. If not, use "Join by IP" with the host IP.
- [ ] Test QR scan to confirm it reads IP and connects.
- [ ] Test solo mode (bots) with different player counts.

---

## 🐞 Troubleshooting

- No discovery results:
  - Ensure both devices are on the same WiFi and same subnet (e.g., both 192.168.1.x).
  - Check host firewall (Windows Defender) settings — allow the app or temporarily disable firewall.
  - Try the **Join by IP** fallback using the host IP displayed in the lobby.
- QR scan fails to connect:
  - Check format `ip` or `ip:port` encoded in QR.
  - Use manual IP entry as backup.

---

## 🧩 Contributing

1. Fork the repo
2. Create a feature branch
3. Add tests where appropriate and ensure `flutter analyze` passes
4. Open a PR with clear description and testing steps

---



