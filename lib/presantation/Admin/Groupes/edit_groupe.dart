import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/models/group.dart';

class EditGroupPage extends StatefulWidget {
  final Group group;

  const EditGroupPage({Key? key, required this.group}) : super(key: key);

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _groupNameController;
  String? _selectedCoach;
  List<String> _coaches = [];
  bool _showAssignmentSection = false;

  // Variables for player assignment and training schedule
  final List<String> _selectedPlayers = [];
  final List<String> _allPlayers = [];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.group.name);
    _selectedCoach = widget.group.coach;
    _fetchCoaches();
    _fetchPlayers(); // Fetch all players
  }

  void _fetchCoaches() async {
    final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'coach').get();
    final coaches = snapshot.docs.map((doc) => doc.data()['name'] as String).toSet().toList();
    setState(() {
      _coaches = coaches;
    });
  }

  void _fetchPlayers() async {
    final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'joueur').get();
    final players = snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    setState(() {
      _allPlayers.addAll(players); // Add all players to the list
    });
  }

  // Method to save the group with the updated information
  void _saveGroup() async {
    try {
      // Ensure group name and coach are not empty
      if (_groupNameController.text.isEmpty || _selectedCoach == null) {
        print('Error: Group name or coach is not set');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please enter a group name and select a coach'),
        ));
        return;
      }

      // Update the group with new data in Firestore
      await _firestore.collection('groups').doc(widget.group.id).update({
        'name': _groupNameController.text,   // Ensure the correct name is saved
        'coach': _selectedCoach!,            // Ensure the correct coach is saved
        'players': _selectedPlayers,         // Save players
        'trainingSchedule': {
          'date': _selectedDate?.toIso8601String(),  // Cast date directly to ISO8601
          'time': _selectedTime?.format(context),    // Cast time to formatted string
        },
      });

      // Navigate back to the ManageGroupsPage and indicate that changes were made
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error saving group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group'),
        // Save button added in AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGroup, // Save button calls the _saveGroup method
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Select Coach'),
              DropdownButton<String>(
                hint: const Text('Select Coach'),
                value: _selectedCoach != null && _coaches.contains(_selectedCoach) ? _selectedCoach : null,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCoach = newValue;
                  });
                },
                items: _coaches.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Row containing two buttons: one for assigning players, and one for date & time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Show player selection list
                      setState(() {
                        _showAssignmentSection = !_showAssignmentSection;
                      });
                    },
                    child: const Text('Assign Players'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Show date picker
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2021),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }

                      // Show time picker
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _selectedTime = pickedTime;
                        });
                      }
                    },
                    child: const Text('Assign Date & Time'),
                  ),
                ],
              ),

              // Show the player selection and training schedule if toggled
              Visibility(
                visible: _showAssignmentSection,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text('Assign Players'),
                    // Make sure the ListView has a constrained height
                    Container(
                      height: 200,  // Set a fixed height for the player list
                      child: ListView.builder(
                        itemCount: _allPlayers.length,
                        itemBuilder: (context, index) {
                          return CheckboxListTile(
                            title: Text(_allPlayers[index]),
                            value: _selectedPlayers.contains(_allPlayers[index]),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPlayers.add(_allPlayers[index]);
                                } else {
                                  _selectedPlayers.remove(_allPlayers[index]);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              if (_selectedDate != null) Text('Selected Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
              if (_selectedTime != null) Text('Selected Time: ${_selectedTime!.format(context)}'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
