
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getNextTrainingSession(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final assignedGroups = List<String>.from(userData['assignedGroups'] ?? []);


      if (assignedGroups.isEmpty) {
        return null;
      }

      QuerySnapshot sessionsSnapshot = await _firestore
          .collection('training_sessions')
          .where('groupId', whereIn: assignedGroups)
          .orderBy('startTime')
          .startAfter([Timestamp.now()])
          .limit(1)
          .get();

      if (sessionsSnapshot.docs.isNotEmpty) {
        return sessionsSnapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getEventsAndNews() async {
    try {
      QuerySnapshot eventsSnapshot =
          await _firestore.collection('events').orderBy('date').get();
      return eventsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getTeamAndPlayers(String userId) async {
  try {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {'groupName': null, 'players': []};
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final assignedGroup = userData['assignedGroups']?[0]; // Assuming a single group is assigned.

    if (assignedGroup == null) {
      return {'groupName': null, 'players': []};
    }

    DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(assignedGroup).get();
    if (!groupDoc.exists) {
      return {'groupName': null, 'players': []};
    }

    final groupData = groupDoc.data() as Map<String, dynamic>;
    final playerIds = groupData['players'] as List<dynamic>? ?? [];
    final groupName = groupData['groupName'] ?? 'Nom du groupe inconnu';

    List<Map<String, dynamic>> players = [];
    for (String playerId in playerIds) {
      DocumentSnapshot playerDoc = await _firestore.collection('users').doc(playerId).get();
      if (playerDoc.exists) {
        players.add(playerDoc.data() as Map<String, dynamic>);
      }
    }

    return {'groupName': groupName, 'players': players};
  } catch (e) {
    return {'groupName': null, 'players': []};
  }
}

}
