// lib/presentation/Admin/Players/assign_players_groupe.dart

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

  void _saveAssignment() async {
    try {
      print('Group ID: ${widget.groupId}'); // Debug print statement
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
            Text('Assign Players'),
            // Your player selection logic here
            // Example: ListView of players with checkboxes
            const SizedBox(height: 20),
            Text('Assign Training Schedule'),
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
