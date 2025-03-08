import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CoachService {
  final FirebaseFirestore _firestore;
  
  CoachService({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Récupère tous les coachs avec leurs limites de sessions
  Future<List<Map<String, dynamic>>> fetchAllCoaches() async {
    try {
      final snapshot = await _firestore.collection('coaches').get();
      
      final allCoaches = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'],
        'maxSessionsPerDay': doc.data().containsKey('maxSessionsPerDay') 
            ? doc.data()['maxSessionsPerDay'] 
            : 2,
        'maxSessionsPerWeek': doc.data().containsKey('maxSessionsPerWeek') 
            ? doc.data()['maxSessionsPerWeek'] 
            : 10,
        'dailySessions': 0,
        'weeklySessions': 0,
      }).toList();
      
      return allCoaches;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des coachs: $e');
      return [];
    }
  }
  
  /// Calcule les sessions pour une date donnée pour chaque coach
  Future<Map<String, Map<String, int>>> calculateSessionCounts(DateTime selectedDate) async {
    // Déterminer la semaine (du lundi au dimanche)
    DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    Map<String, int> dailySessions = {};
    Map<String, int> weeklySessions = {};

    // Liste des collections à vérifier
    List<String> collections = ['trainings', 'championships', 'friendlyMatches', 'tournaments'];

    for (String collection in collections) {
      final snapshot = await _firestore.collection(collection).get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('coaches')) continue;

        List<dynamic> assignedCoaches = data['coaches'];

        // Déterminer la/les date(s) de la session
        List<DateTime> sessionDates = [];

        if (data.containsKey('dates') && data['dates'] is List) {
          // Pour les événements avec plusieurs dates
          for (var dateItem in data['dates']) {
            if (dateItem is Timestamp) {
              sessionDates.add(dateItem.toDate());
            } else if (dateItem is String) {
              try {
                sessionDates.add(DateTime.parse(dateItem));
              } catch (e) {
                // Ignorer les dates mal formatées
              }
            }
          }
        } else if (data.containsKey('date')) {
          // Pour les événements avec une seule date
          if (data['date'] is Timestamp) {
            sessionDates.add((data['date'] as Timestamp).toDate());
          } else if (data['date'] is String) {
            try {
              sessionDates.add(DateTime.parse(data['date']));
            } catch (e) {
              // Ignorer les dates mal formatées
            }
          }
        } else if (collection == "championships" && data.containsKey('matchDays')) {
          // Pour les championnats avec plusieurs journées
          for (var matchDay in data['matchDays']) {
            if (matchDay is Map<String, dynamic> && matchDay.containsKey('date')) {
              try {
                if (matchDay['date'] is String) {
                  sessionDates.add(DateTime.parse(matchDay['date']));
                } else if (matchDay['date'] is Timestamp) {
                  sessionDates.add((matchDay['date'] as Timestamp).toDate());
                }
              } catch (e) {
                // Ignorer les dates mal formatées
              }
            }
          }
        }

        // Vérifier chaque date de session
        for (var sessionDate in sessionDates) {
          // Vérifications précises pour la date et la semaine
          bool isToday = sessionDate.year == selectedDate.year && 
                          sessionDate.month == selectedDate.month &&
                          sessionDate.day == selectedDate.day;
                          
          bool isThisWeek = sessionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
                            sessionDate.isBefore(endOfWeek.add(const Duration(days: 1)));

          for (var coachId in assignedCoaches) {
            if (coachId == null) continue;

            // Comptabiliser les sessions du jour
            if (isToday) {
              dailySessions[coachId] = (dailySessions[coachId] ?? 0) + 1;
            }

            // Comptabiliser les sessions de la semaine
            if (isThisWeek) {
              weeklySessions[coachId] = (weeklySessions[coachId] ?? 0) + 1;
            }
          }
        }
      }
    }

    return {
      'dailySessions': dailySessions,
      'weeklySessions': weeklySessions,
    };
  }
  
  /// Récupère les coachs avec leurs compteurs de sessions pour une date donnée
  Future<List<Map<String, dynamic>>> getCoachesWithSessionCounts(DateTime selectedDate) async {
    // Récupérer tous les coachs
    List<Map<String, dynamic>> coaches = await fetchAllCoaches();
    
    // Calculer les compteurs de sessions
    Map<String, Map<String, int>> sessionCounts = await calculateSessionCounts(selectedDate);
    
    // Mettre à jour les compteurs pour chaque coach
    for (var coach in coaches) {
      String coachId = coach['id'];
      coach['dailySessions'] = sessionCounts['dailySessions']?[coachId] ?? 0;
      coach['weeklySessions'] = sessionCounts['weeklySessions']?[coachId] ?? 0;
    }
    
    return coaches;
  }
  
  /// Vérifie si un coach est disponible pour une date donnée
  Future<bool> isCoachAvailable(String coachId, DateTime date) async {
    var coaches = await getCoachesWithSessionCounts(date);
    
    // Trouver le coach par son ID
    var coach = coaches.firstWhere(
      (c) => c['id'] == coachId, 
      orElse: () => {'maxSessionsPerDay': 2, 'maxSessionsPerWeek': 10, 'dailySessions': 0, 'weeklySessions': 0}
    );
    
    // Vérifier la disponibilité
    bool availableForDay = coach['dailySessions'] < coach['maxSessionsPerDay'];
    bool availableForWeek = coach['weeklySessions'] < coach['maxSessionsPerWeek'];
    
    return availableForDay && availableForWeek;
  }
  
  /// Widget de sélection des coachs
  Widget buildCoachSelectionWidget(
    List<Map<String, dynamic>> coaches, 
    List<String> selectedCoachIds, 
    Function(List<String>) onSelectionChanged
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Coachs disponibles :",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: coaches.map((coach) {
            final isSelected = selectedCoachIds.contains(coach['id']);
            final maxPerDay = coach['maxSessionsPerDay'];
            final maxPerWeek = coach['maxSessionsPerWeek'];
            final dailySessions = coach['dailySessions'];
            final weeklySessions = coach['weeklySessions'];
            final remainingDaily = maxPerDay - dailySessions;
            final remainingWeekly = maxPerWeek - weeklySessions;

            return ChoiceChip(
              label: Text("${coach['name']} 📅$remainingDaily/$maxPerDay 🗓️$remainingWeekly/$maxPerWeek"),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.grey[200],
              onSelected: (bool selected) {
                List<String> updatedSelection = List.from(selectedCoachIds);
                if (selected) {
                  if (!updatedSelection.contains(coach['id'])) {
                    updatedSelection.add(coach['id']);
                  }
                } else {
                  updatedSelection.remove(coach['id']);
                }
                onSelectionChanged(updatedSelection);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Future<void> updateCoachSessionsForDateChange({
  required List<String> coachIds,
  required DateTime oldDate,
  required DateTime newDate,
}) async {
  try {
    // Décrémenter les sessions pour l'ancienne date
    final oldSessionCounts = await calculateSessionCounts(oldDate);
    for (var coachId in coachIds) {
      if (oldSessionCounts['dailySessions']?[coachId] != null) {
        await _firestore.collection('coaches').doc(coachId).update({
          'dailySessions': FieldValue.increment(-1),
          'weeklySessions': FieldValue.increment(-1),
        });
      }
    }

    // Incrémenter les sessions pour la nouvelle date
    final newSessionCounts = await calculateSessionCounts(newDate);
    for (var coachId in coachIds) {
      if (newSessionCounts['dailySessions']?[coachId] != null) {
        await _firestore.collection('coaches').doc(coachId).update({
          'dailySessions': FieldValue.increment(1),
          'weeklySessions': FieldValue.increment(1),
        });
      }
    }
  } catch (e) {
    debugPrint('Erreur lors de la mise à jour des sessions des coachs: $e');
  }
}

Future<bool> validateCoachSelection(List<String> coachIds, DateTime date, BuildContext context) async {

  for (String coachId in coachIds) {
    bool isAvailable = await isCoachAvailable(coachId, date);
    if (!isAvailable) {
      // Récupérer les informations du coach
      var coaches = await getCoachesWithSessionCounts(date);
      var coach = coaches.firstWhere(
        (c) => c['id'] == coachId,
        orElse: () => {
          'name': coachId,
          'dailySessions': 0,
          'maxSessionsPerDay': 2,
          'weeklySessions': 0,
          'maxSessionsPerWeek': 10,
        },
      );

      // Afficher une alerte pour ce coach
      // ignore: use_build_context_synchronously
      bool proceed = await _showCoachLimitExceededDialog(context, coach);
      if (!proceed) {
        return false; // L'utilisateur a annulé
      }
    }
  }

  return true; // Tous les coachs sont valides
}

/// Affiche une alerte pour un coach qui dépasse ses limites de sessions
Future<bool> _showCoachLimitExceededDialog(BuildContext context, Map<String, dynamic> coach) async {
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Attention: Limite de séances dépassée', style: TextStyle(color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${coach["name"]} a déjà atteint sa limite de séances.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Sessions quotidiennes: ${coach["dailySessions"]}/${coach["maxSessionsPerDay"]}',
          ),
          Text(
            'Sessions hebdomadaires: ${coach["weeklySessions"]}/${coach["maxSessionsPerWeek"]}',
          ),
          const SizedBox(height: 16),
          const Text('Voulez-vous quand même lui assigner cette session ?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Non', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Oui, continuer', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  ) ?? false; // Retourne false si l'utilisateur ferme la boîte de dialogue
}
}