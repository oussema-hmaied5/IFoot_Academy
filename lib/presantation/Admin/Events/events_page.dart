// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageEventsPage extends StatefulWidget {
  const ManageEventsPage({Key? key}) : super(key: key);

  @override
  _ManageEventsPageState createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends State<ManageEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
    setState(() {});
  }

  void _editEvent(String eventId, String newEvent) async {
    await _firestore.collection('events').doc(eventId).update({
      'event': newEvent,
    });
    setState(() {});
  }

  void _addEvent(String event) async {
    await _firestore.collection('events').add({
      'event': event,
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            children: [
              _buildSectionTitle('Events'),
              _buildEventsList(),
              _buildSectionTitle('Add Event'),
              _buildAddEventButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('events').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<DocumentSnapshot> documents = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (BuildContext context, int index) {
            final Map<String, dynamic> event = documents[index].data()! as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: ListTile(
                title: Text(event['event']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final String? newEvent = await _showEditEventDialog(event['event']);
                        if (newEvent != null) {
                          _editEvent(documents[index].id, newEvent);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteEvent(documents[index].id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddEventButton() {
    return ElevatedButton(
      onPressed: () async {
        final String? event = await _showAddEventDialog();
        if (event != null) {
          _addEvent(event);
        }
      },
      child: const Text('Add Event'),
    );
  }

  Future<String?> _showEditEventDialog(String currentEvent) async {
    final TextEditingController controller = TextEditingController(text: currentEvent);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Event'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new event'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showAddEventDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter event'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
