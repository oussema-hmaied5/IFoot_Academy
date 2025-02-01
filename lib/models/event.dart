import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final double tariff;
  final String? imageUrl; // Optional photo URL

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.tariff,
    this.imageUrl,
  });

  // Factory constructor to create an Event object from Firestore data
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      tariff: (data['tariff'] as num).toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  // Convert Event object to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'tariff': tariff,
      'imageUrl': imageUrl,
    };
  }
}
