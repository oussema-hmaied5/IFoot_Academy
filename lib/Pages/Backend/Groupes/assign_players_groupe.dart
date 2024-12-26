import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignPlayersPage extends StatefulWidget {
  final String groupId;

  const AssignPlayersPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _AssignPlayersPageState createState() => _AssignPlayersPageState();
}

class _AssignPlayersPageState extends State<AssignPlayersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _selectedPlayers = [];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _alreadyAssignedPlayers = [];
  List<DocumentSnapshot> _availablePlayers = [];
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _fetchAssignedPlayers();
    _fetchAvailablePlayers();
  }

  // Fetch the already assigned players for all groups
  void _fetchAssignedPlayers() async {
    final QuerySnapshot groupSnapshot = await _firestore.collection('groups').get();
    final List<String> assignedPlayers = [];

    for (var groupDoc in groupSnapshot.docs) {
      assignedPlayers.addAll(List<String>.from(groupDoc['players'] ?? []));
    }

    setState(() {
      _alreadyAssignedPlayers = assignedPlayers;
    });
  }

  // Fetch available players, filtering by date of birth and excluding assigned players
  void _fetchAvailablePlayers() async {
    QuerySnapshot playersSnapshot = await _firestore.collection('players').get();

    setState(() {
      _availablePlayers = playersSnapshot.docs.where((playerDoc) {
        DateTime dob = DateTime.parse(playerDoc['date_of_birth']);
        String playerId = playerDoc.id;
        
        // Exclude players already assigned to any group
        if (_alreadyAssignedPlayers.contains(playerId)) {
          return false;
        }

        // Apply date of birth filter if provided
        if (_filterDate != null) {
          return dob.isBefore(_filterDate!);
        }
        
        return true;
      }).toList();
    });
  }

  // Save the assignment to Firestore
  void _saveAssignment() async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'players': _selectedPlayers,
        'trainingSchedule': {
          'date': _selectedDate?.toIso8601String(),
          'time': _selectedTime?.format(context),
        }
      });
      Navigator.of(context).pop();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Players and Training Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAssignment,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Filter Players by Date of Birth'),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _filterDate = picked;
                    _fetchAvailablePlayers();
                  });
                }
              },
              child: const Text('Select Date to Filter'),
            ),
            const SizedBox(height: 20),
            const Text('Assign Players'),
            Expanded(
              child: ListView.builder(
                itemCount: _availablePlayers.length,
                itemBuilder: (context, index) {
                  final playerDoc = _availablePlayers[index];
                  final playerId = playerDoc.id;
                  final playerName = playerDoc['name'];
                  
                  return CheckboxListTile(
                    title: Text(playerName),
                    value: _selectedPlayers.contains(playerId),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedPlayers.add(playerId);
                        } else {
                          _selectedPlayers.remove(playerId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('Assign Training Schedule'),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2021),
                  lastDate: DateTime(2030),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: const Text('Select Training Date'),
            ),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null && picked != _selectedTime) {
                  setState(() {
                    _selectedTime = picked;
                  });
                }
              },
              child: const Text('Select Training Time'),
            ),
            // Display selected date and time
            if (_selectedDate != null) Text('Date: ${_selectedDate!.toLocal()}'),
            if (_selectedTime != null) Text('Time: ${_selectedTime!.format(context)}'),
          ],
        ),
      ),
    );
  }
}
