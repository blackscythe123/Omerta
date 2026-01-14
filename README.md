# Mafia Game (Flutter)

🎭 **Mafia — Offline LAN Multiplayer + Solo Bots with Advanced Features**

A fully-featured Flutter-based Mafia game supporting local offline multiplayer over LAN (UDP/TCP) and solo mode with AI bots. Features include room management, lobby chat, countdown system, and comprehensive host controls.

---

## 🔑 Key Features

### **Core Gameplay**
- **Fully offline LAN multiplayer** — No internet connection required
- **Solo mode** with AI-controlled bots (no networking required)
- **Classic Mafia roles** — Villager, Mafia, Doctor, Detective, and more
- **Phase-based gameplay** — Night phase, Discussion, Voting, and Results
- **Cross-platform support** — Android, Windows, iOS, macOS, Linux (LAN not supported in Web)

### **Advanced Networking**
- **UDP broadcast discovery** (port 41234) — Automatic room discovery on local network
- **TCP server/client communication** — Dynamic OS-assigned ports for reliable game sync
- **Host-authoritative architecture** — Host maintains canonical game state
- **QR code + IP fallback** — Scan QR or enter IP:PORT to connect directly
- **Private rooms with PIN** — 4-digit PIN protection for private games
- **Dynamic port system** — Automatic port assignment and discovery

### **Lobby Management**
- **Ready/Wait system** — Players must ready up before host can start
- **Lobby chat** — In-room text messaging before game starts
- **Host powers** — Kick players, change settings, control game start
- **Room settings panel** — Configure max players, privacy, chat, and more
- **Player status indicators** — Visual ready/waiting states for all players
- **Moderator mode** — UI badge and toggle (coming soon for gameplay logic)

### **Game Start System**
- **Synchronized countdown** — 5-4-3-2-1 countdown on all devices
- **Countdown overlay** — Full-screen animated countdown with fade effects
- **Safety rules** — Prevents game start without all players ready
- **Disconnect protection** — Countdown cancels if host disconnects mid-countdown
- **Join blocking** — No new players can join during countdown

### **Host Disconnect Handling**
- **In Lobby** — Clients automatically notified with reason dialog
- **During Game** — Game immediately ends, all players returned to home
- **Countdown cancellation** — Countdown stops if host disconnects
- **Automatic navigation** — Back to home screen with error message

---

## 🆕 Latest Feature Set

### **Part 1 — Host Room Settings Panel**
Hosts can now configure their room with a comprehensive settings dialog:
- **Max Players Slider** — Set room capacity from 5 to 20 players
- **Public/Private Toggle** — Make room private with PIN requirement
- **PIN Management** — Change 4-digit PIN for private rooms
- **Chat Toggle** — Enable/disable lobby chat
- **Moderator Mode** — Toggle moderator mode (UI only, gameplay coming soon)
- **Characters Section** — Placeholder for future character customization

Access via **Settings icon** (⚙️) in lobby app bar (host only).

### **Part 2 — Moderator Mode (UI)**
Visual indicators for moderator mode:
- **Toggle in Settings** — Enable/disable in room settings
- **Lobby Badge** — "MODERATOR" badge displayed next to player list
- **Coming Soon** — Full moderator gameplay logic to be implemented

### **Part 3 — Game Start Countdown**
Synchronized countdown system before game starts:
- **5-4-3-2-1 countdown** — Large animated numbers on all devices
- **Full-screen overlay** — Semi-transparent dark background
- **Smooth animations** — Fade and scale effects for each number
- **Synchronized timing** — All clients show same countdown value
- **Automatic start** — Game begins automatically after countdown completes

### **Part 4 — Safety Rules**
Comprehensive safety checks to ensure fair gameplay:
1. **Ready Check** — Host cannot start game unless ALL players are ready
2. **Countdown Cancellation** — If host disconnects during countdown, countdown stops on all clients
3. **Join Blocking** — New players cannot join room during countdown or after game starts
4. **Player Leave Handling** — If any player leaves during countdown, countdown is cancelled

### **Part 5 — README Documentation**
This comprehensive README now includes:
- Full feature list with descriptions
- Detailed networking architecture
- Usage instructions for all features
- Development setup guide
- Project structure overview

---

## 📋 Detailed Feature Documentation

### **Networking & Discovery**

#### UDP Broadcast Discovery (Port 41234)
- Host broadcasts room info every 2 seconds
- Clients listen for broadcasts and display available rooms
- Room data includes: host name, room name, player count, max players, privacy status
- Automatic cleanup of stale rooms (6-second timeout)

#### TCP Communication (Dynamic Ports)
- TCP server binds to OS-assigned dynamic port (not hardcoded)
- Port number included in UDP broadcasts and QR codes
- Format: `IP:PORT` (e.g., `192.168.1.100:54321`)
- Reliable message delivery with newline-delimited JSON
- Message buffering for partial packet handling

#### Message Protocol
The game uses JSON messages over TCP with the following types:
- **join_request** — Client requests to join room (includes PIN if private)
- **join_accepted** / **join_rejected** — Host response to join request
- **state_update** — Host broadcasts game state to all clients
- **set_ready** — Client notifies host of ready state change
- **player_ready** — Host broadcasts ready state to all clients
- **chat** / **chat_broadcast** — Lobby chat messages
- **room_settings_update** — Host broadcasts room setting changes
- **start_countdown** — Host initiates countdown with value (5-1)
- **start_game** — Host signals game start after countdown
- **kicked** — Host notifies player of kick
- **room_closed** — Host notifies all clients of room closure

### **Room Settings**

#### Max Players (5-20)
- Configurable via slider in room settings
- Default: 10 players
- Applies immediately to room
- Displayed in lobby as "X/Y" (current/max)
- Join requests rejected if room is full

#### Public vs Private Rooms
- **Public** — Anyone on LAN can join
- **Private** — Requires 4-digit PIN to join
- PIN never broadcast over network (stored only on host)
- QR codes encode PIN for private rooms: `IP:PORT|PIN`
- Join rejection with "Invalid PIN" message

#### Chat Enable/Disable
- Hosts can enable or disable lobby chat
- Controlled via toggle in room settings
- Applies immediately to all players
- Chat FAB hidden when disabled

#### Moderator Mode (UI)
- Visual indicator only (gameplay logic coming soon)
- Toggle in room settings
- Badge displayed next to "PLAYERS" header
- Yellow/warning color scheme

### **Ready System**

#### For Clients (Non-Host Players)
- Start in "NOT READY" state
- Tap large button to toggle: **"TAP WHEN READY"** ↔ **"READY - TAP TO UNREADY"**
- Button icon changes: ⏳ → ✅
- Ready state visible to all players
- Cannot start game until ready

#### For Host
- Always ready by default
- Cannot unready (host ready state locked)
- Can only start game when:
  - Minimum 5 players in room
  - ALL players (including host) are ready
- Button shows status: "START GAME", "NEED X MORE", or "WAITING FOR READY"

#### Visual Indicators
- Player cards show "READY" or "NOT READY" subtitle
- Status badge: green checkmark (ready) or hourglass (waiting)
- Ready count displayed: "X/Y READY" (green when all ready, yellow otherwise)

### **Lobby Chat**

#### Chat Interface
- **Floating Action Button (FAB)** — Blue chat icon in bottom-right
- **Green dot indicator** — Shows when new messages arrive
- **Modal bottom sheet** — Slides up from bottom when opened
- **Message list** — Scrollable with auto-scroll to latest
- **Text input** — Bottom input field with send button

#### Message Display
- **Your messages** — Right-aligned, blue background
- **Other messages** — Left-aligned, grey background
- **Sender name** — Displayed above each message
- **Timestamp** — Shown for each message
- **Auto-formatting** — Long messages wrap properly

#### Chat Features
- Real-time message sync across all clients
- Messages cleared when leaving room
- Chat persists during lobby phase only
- No message history after game starts

### **Host Powers**

#### Kick Players
1. Host taps on any non-host player card in lobby
2. Confirmation dialog appears with player name
3. "KICK" button removes player from room
4. Kicked player receives "kicked" message and returns to home
5. Other clients notified of player departure

#### Start Game Control
- Only host has "START GAME" button
- Button disabled until conditions met:
  - Minimum 5 players
  - All players ready
- Tapping starts countdown sequence

#### Room Settings Management
- Host-only access via settings icon (⚙️)
- Changes apply immediately
- All clients notified of setting changes via **room_settings_update** message

### **Countdown System**

#### Countdown Flow
1. Host taps "START GAME" when all players ready
2. Countdown overlay appears on all devices
3. Numbers display in sequence: 5 → 4 → 3 → 2 → 1
4. Each number shown for 1 second
5. After 1, game starts automatically
6. All players navigate to role reveal screen

#### Countdown Visual Design
- **Full-screen overlay** — Dark semi-transparent background (70% opacity)
- **Large numbers** — 120pt font size, white color
- **Glow effect** — Shadow with primary color accent
- **Animations** — Fade in + scale up for each number
- **Centered** — Numbers displayed in exact center of screen

#### Safety Features
- **No joins** — Room marked as "counting down", join requests rejected
- **Cancel on disconnect** — If host disconnects, countdown stops immediately
- **Cancel on leave** — If any player leaves, countdown stops
- **Can't restart** — Host can't trigger multiple countdowns simultaneously

### **QR Code & Direct Join**

#### QR Code Generation
- Host can display QR code via QR icon (📱) in lobby
- QR encodes: `IP:PORT` for public rooms, `IP:PORT|PIN` for private rooms
- QR dialog shows:
  - "PRIVATE ROOM" label (if private)
  - Scannable QR code (200x200)
  - IP:PORT text below QR
  - PIN badge (if private)
  - Share button to export QR as image

#### Direct IP Join
- Fallback method when UDP discovery fails
- Format: `IP:PORT` (e.g., `192.168.1.100:54321`)
- Optional PIN for private rooms
- Validation: 4-digit PIN required for private rooms

#### Share Functionality
- QR code exportable as PNG image
- Share text includes IP, port, and PIN (if private)
- Uses system share sheet for cross-app sharing

---

## 📁 Project Structure

```
lib/
├── game/
│   ├── game_manager.dart          # Central game state (ChangeNotifier)
│   ├── bot_controller.dart        # AI bot behavior
│   └── game_rules.dart            # Role setup & win conditions
├── network/
│   ├── lan_communication.dart     # UDP discovery + TCP client/server
│   └── game_communication.dart    # Interface for communication layer
├── screens/
│   ├── home_screen.dart           # Main menu
│   ├── player_setup_screen.dart   # Name entry & mode selection
│   ├── lobby_screen.dart          # Pre-game lobby with chat/ready/settings
│   ├── game_screen.dart           # Main gameplay screen
│   ├── role_reveal_screen.dart    # Role assignment reveal
│   ├── how_to_play_screen.dart    # Rules and role descriptions
│   └── widgets/
│       ├── countdown_overlay.dart  # Countdown animation widget
│       └── room_settings_dialog.dart  # Host room settings dialog
├── models/
│   ├── player.dart                # Player model with id, name, role, isReady
│   └── game_state.dart            # GamePhase, GameMode, GameConfig enums
├── theme/
│   └── app_theme.dart             # Colors, text styles, themes
└── main.dart                      # App entry point
```

---

## 🛠 Development Setup

### **Requirements**
- Flutter 3.x/4.x SDK
- Dart SDK (included with Flutter)
- Android SDK (for building APK)
- Xcode (for iOS, macOS builds)
- Windows tooling (for Windows desktop)

### **Installation**

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd mafia
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on device**
   ```bash
   # Android
   flutter run -d android
   
   # iOS
   flutter run -d ios
   
   # Windows
   flutter run -d windows
   
   # Web (UI only, no LAN)
   flutter run -d chrome
   ```

### **Build Release**

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release
```

---

## 🎮 How to Play

### **Solo Mode (with Bots)**
1. Launch app and tap "SOLO WITH BOTS"
2. Enter your name
3. Select number of players (5-12)
4. Tap "START GAME"
5. View your assigned role
6. Play through night and day phases
7. Vote to eliminate suspects
8. Win as villagers or mafia!

### **LAN Multiplayer Mode**

#### **As Host:**
1. Launch app and tap "HOST LAN ROOM"
2. Enter your name and room name
3. Optional: Enable private room and set 4-digit PIN
4. Tap "CREATE ROOM"
5. Share IP:PORT or QR code with other players
6. (Optional) Open room settings (⚙️) to configure:
   - Max players (5-20)
   - Privacy and PIN
   - Chat enable/disable
   - Moderator mode
7. Wait for players to join
8. (Optional) Kick unwanted players by tapping their card
9. Wait for all players to ready up
10. Tap "START GAME" to begin countdown
11. Game starts automatically after 5-second countdown

#### **As Client:**
1. Launch app and tap "JOIN LAN ROOM"
2. Enter your name
3. Choose connection method:
   - **Auto-discover**: Select room from list
   - **Scan QR**: Scan host's QR code
   - **Enter IP**: Type IP:PORT manually
4. Enter PIN if room is private
5. Tap "JOIN"
6. Wait in lobby and chat with other players
7. Tap "READY" when you're ready to play
8. Wait for host to start game
9. Watch countdown (5-4-3-2-1)
10. View your assigned role and play!

---

## 🔧 Troubleshooting

### **Can't discover rooms**
- Ensure all devices are on same WiFi network
- Check that UDP port 41234 is not blocked by firewall
- Try direct IP join as fallback

### **Connection refused**
- Verify host is still running the room
- Check that IP address is correct
- Ensure TCP port is not blocked

### **Host disconnected**
- This is normal if host closes app or loses connection
- All clients will be notified and returned to home
- Host must recreate room for new game

### **Countdown won't start**
- Ensure all players are ready
- Check that minimum 5 players are in room
- Host must tap "START GAME" button

---

## 📝 License

This project is open source. See LICENSE file for details.

---

## 🙏 Credits

Built with Flutter and Dart.

**Network Libraries:**
- UDP broadcast discovery
- TCP socket communication
- QR code generation (barcode_widget)
- Share functionality (share_plus)

**UI/UX:**
- Custom theme with dark mode support
- Smooth animations and transitions
- Material Design components

---

## 🚀 Future Roadmap

### **Coming Soon:**
- [ ] Moderator mode gameplay logic
- [ ] Character customization
- [ ] Advanced role abilities
- [ ] Game history and statistics
- [ ] Sound effects and music
- [ ] More AI bot personalities
- [ ] Custom game rules
- [ ] Spectator mode

### **Under Consideration:**
- [ ] Internet multiplayer (dedicated server)
- [ ] Cross-platform party codes
- [ ] Voice chat integration
- [ ] Replay system
- [ ] Tournament mode

---

**Enjoy the game! Report bugs or suggest features via GitHub Issues.**

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

### UDP Discovery
- Host broadcasts a JSON message containing RoomInfo every 2 seconds to UDP port **41234**
- Broadcast includes: room name, host name, player count, max players, **TCP port**, privacy flag
- Clients listen on UDP port **41234** and parse broadcasts to show available rooms

### TCP Communication
- Host opens a TCP server on a **dynamic port** (OS-assigned) and accepts client sockets
- All game actions and state sync use JSON over TCP with line-delimited messages
- Message types include:
  - `join_request` / `join_accepted` / `join_rejected` — player connection
  - `state_update` — full game state sync
  - `set_ready` / `player_ready` — ready state changes
  - `chat` / `chat_broadcast` — lobby chat messages
  - `room_closed` — host disconnect notification

### Fallback when discovery fails
- Manual "Join by IP:Port" dialog
- QR Code contains host IP and port (e.g., `192.168.1.100:54321`) for direct connection

### Important Notes
- Devices must be on the same network (same WiFi/subnet)
- Firewalls on host machines may block UDP/TCP — temporarily disable or allow the app during testing

---

## 📱 QR & IP Join

- **Host**: In the **Lobby** the host's local IP:Port is shown (tap to copy). Tap QR icon to show a QR code containing the connection info.
- **Client**: In **Find Room** screen, choose "JOIN BY IP ADDRESS" or "SCAN QR". Scanning the QR attempts a direct TCP connect.

---

## 🎮 Lobby Features

### Player List
- Shows all connected players with ready status indicator (green dot = ready)
- Host badge and "YOU" badge for identification
- Moderator assignment option for host
- **Kick button** (host only) - Remove players before game starts

### Ready System
- **Clients**: Tap "TAP WHEN READY" button to toggle ready state
- **Host**: Start button disabled until all players are ready
- Button shows "NEED X MORE AGENTS" or "WAITING FOR ALL TO BE READY"

### Lobby Chat
- Tap floating chat button (bottom right) to open chat panel
- Type messages to communicate with other players
- Messages persist during lobby session

### Host Controls
- **Kick Players**: Tap person_remove icon on any player card (except yourself)
- **Assign Moderator**: Tap gavel icon to toggle moderator role
- **Start Game**: Only enabled when 5+ players and all ready

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

- [ ] Verify `flutter analyze` shows no errors
- [ ] Host on Windows and confirm UDP broadcasts appear (logs show "Hosting started: ... at IP:PORT")
- [ ] On Android device (same WiFi), open Find Room and verify host appears
- [ ] If no discovery results, use "Join by IP" with the host IP:Port displayed in the lobby
- [ ] Test QR scan to confirm it reads IP:Port and connects
- [ ] Test ready system: client toggles ready, host sees ready count update
- [ ] Test lobby chat: send messages between host and client
- [ ] Test kick functionality: host kicks a player and verify they're disconnected
- [ ] Test host disconnect in lobby: close host app and verify client gets notification
- [ ] Test host disconnect during game: close host app during gameplay and verify all clients exit to home
- [ ] Test late join rejection: try to join a room after game has started
- [ ] Test solo mode (bots) with different player counts

---

## 🐞 Troubleshooting

- **No discovery results:**
  - Ensure both devices are on the same WiFi and same subnet (e.g., both 192.168.1.x)
  - Check host firewall (Windows Defender) settings — allow the app or temporarily disable firewall
  - Try the **Join by IP** fallback using the host IP:Port displayed in the lobby

- **QR scan fails to connect:**
  - Check format `ip:port` encoded in QR
  - Use manual IP:Port entry as backup

- **"Room is full" or "Game in progress" errors:**
  - Room has reached max players or game already started
  - Ask host to create a new room

- **Client stuck after host leaves:**
  - This should now show a disconnect dialog automatically
  - If stuck, force close and rejoin

---

## 🧩 Contributing

1. Fork the repo
2. Create a feature branch
3. Add tests where appropriate and ensure `flutter analyze` passes
4. Open a PR with clear description and testing steps

---



