// Player model and role/bot enums

enum Role {
  mafia,
  villager,
  doctor,
  detective,
  godfather,
  vigilante,
  serialKiller,
  escort,
  moderator,
}

enum BotPersonality {
  aggressive,
  quiet,
  random,
}

class Player {
  final String id;
  final String name;
  final Role role;
  bool isAlive;
  final bool isBot;
  final BotPersonality? personality;
  int bullets; // Specifically for the Vigilante role
  bool isReady; // Ready state for lobby (true = ready to start)

  Player({
    required this.id,
    required this.name,
    required this.role,
    this.isAlive = true,
    required this.isBot,
    this.personality,
    this.bullets = 0,
    this.isReady = false,
  });

  Player copyWith({
    String? id,
    String? name,
    Role? role,
    bool? isAlive,
    bool? isBot,
    BotPersonality? personality,
    int? bullets,
    bool? isReady,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      isBot: isBot ?? this.isBot,
      personality: personality ?? this.personality,
      bullets: bullets ?? this.bullets,
      isReady: isReady ?? this.isReady,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      role: Role.values.firstWhere((r) => r.name == json['role'] as String),
      isAlive: json['isAlive'] as bool? ?? true,
      isBot: json['isBot'] as bool? ?? false,
      personality: json['personality'] == null
          ? null
          : BotPersonality.values
              .firstWhere((p) => p.name == (json['personality'] as String)),
      bullets: json['bullets'] as int? ?? 0,
      isReady: json['isReady'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'isAlive': isAlive,
      'isBot': isBot,
      'personality': personality?.name,
      'bullets': bullets,
      'isReady': isReady,
    };
  }
}
