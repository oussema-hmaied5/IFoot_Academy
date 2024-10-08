import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/models/group.dart';

import 'group_details_page.dart';

class ManageGroupsPage extends StatefulWidget {
  const ManageGroupsPage({Key? key}) : super(key: key);

  @override
  _ManageGroupsPageState createState() => _ManageGroupsPageState();
}

class _ManageGroupsPageState extends State<ManageGroupsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addGroup() async {
    final groupDoc = _firestore.collection('groups').doc();
    final group = Group(
      id: groupDoc.id,
      name: '',
      coach: '',
      players: [],
      trainingSchedule: {},
    );

    await groupDoc.set(group.toJson());

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupDetailsPage(group: group),
      ),
    );
  }

  Future<void> _deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Groups'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(_width * 0.05),
          child: Column(
            children: [
              _buildSectionTitleWithAddButton(),
              _buildGroupsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitleWithAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Groups',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _addGroup,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 81, 179, 196), // Customize the color as needed
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').snapshots(),
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
            final group = Group.fromJson(
                documents[index].data()! as Map<String, dynamic>);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: ListTile(
                title: Text(group.name),
                subtitle: Text(
                    'Coach: ${group.coach}\nNumber of Players: ${group.players.length}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Call the delete function
                        await _deleteGroup(group.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.info),
                      onPressed: () async {
                        // Navigate to the GroupDetailsPage
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GroupDetailsPage(group: group),
                          ),
                        );
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
}
