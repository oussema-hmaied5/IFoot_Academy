import 'package:flutter/material.dart';
import 'package:ifoot_academy/models/group.dart';

import 'edit_groupe.dart'; // Import the EditGroupPage

class GroupDetailsPage extends StatelessWidget {
  final Group group;

  const GroupDetailsPage({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parsing the date and time from the training schedule
    String formattedDate = 'No Date Assigned';
    String formattedTime = 'No Time Assigned';

    if (group.trainingSchedule['date'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(group.trainingSchedule['date']);
        formattedDate = "${parsedDate.toLocal()}".split(' ')[0]; // Formatting to show only date
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    if (group.trainingSchedule['time'] != null) {
      formattedTime = group.trainingSchedule['time'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Group: ${group.name}'),
        // Adding the edit icon button here in the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the EditGroupPage to allow editing
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditGroupPage(group: group),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coach: ${group.coach}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Number of Players: ${group.players.length}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Players:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              // Listing players
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: group.players.map((player) {
                  return Text(player, style: const TextStyle(fontSize: 16));
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Training Schedule:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'Date: $formattedDate',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                'Time: $formattedTime',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
