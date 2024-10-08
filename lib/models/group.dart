class Group {
  final String id;
  final String name;
  final String coach;
  final List<String> players;
  final Map<String, dynamic> trainingSchedule;

  Group({
    required this.id,
    this.name = '', // Default value to avoid null
    this.coach = '', // Default value to avoid null
    required this.players,
    required this.trainingSchedule,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '', // Ensure id is not null
      name: json['name'] ?? '', // Default empty string if null
      coach: json['coach'] ?? '', // Default empty string if null
      players: List<String>.from(json['players'] ?? []), // Handle null case for players
      trainingSchedule: json['trainingSchedule'] ?? {}, // Default to empty map if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coach': coach,
      'players': players,
      'trainingSchedule': trainingSchedule,
    };
  }
}
