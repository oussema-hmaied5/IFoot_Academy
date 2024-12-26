import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final List<String> players;

  Group({
    required this.id,
    this.name = '',
    required this.players,
  });

  // Use Firestore DocumentSnapshot to extract the id and other fields
  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id, // Ensure the document ID is used
      name: data['name'] ?? '',
      players: List<String>.from(data['players'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'players': players,
    };
  }
}
