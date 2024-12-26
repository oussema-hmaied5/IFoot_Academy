// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageRegulationsPage extends StatefulWidget {
  const ManageRegulationsPage({Key? key}) : super(key: key);

  @override
  _ManageRegulationsPageState createState() => _ManageRegulationsPageState();
}

class _ManageRegulationsPageState extends State<ManageRegulationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteRegulation(String regulationId) async {
    await _firestore.collection('regulations').doc(regulationId).delete();
    setState(() {});
  }

  void _editRegulation(String regulationId, String newRegulation) async {
    await _firestore.collection('regulations').doc(regulationId).update({
      'regulation': newRegulation,
    });
    setState(() {});
  }

  void _addRegulation(String regulation) async {
    await _firestore.collection('regulations').add({
      'regulation': regulation,
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Regulations'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            children: [
              _buildSectionTitle('Regulations'),
              _buildRegulationsList(),
              _buildSectionTitle('Add Regulation'),
              _buildAddRegulationButton(),
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

  Widget _buildRegulationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('regulations').snapshots(),
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
            final Map<String, dynamic> regulation = documents[index].data()! as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: ListTile(
                title: Text(regulation['regulation']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final String? newRegulation = await _showEditRegulationDialog(regulation['regulation']);
                        if (newRegulation != null) {
                          _editRegulation(documents[index].id, newRegulation);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteRegulation(documents[index].id);
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

  Widget _buildAddRegulationButton() {
    return ElevatedButton(
      onPressed: () async {
        final String? regulation = await _showAddRegulationDialog();
        if (regulation != null) {
          _addRegulation(regulation);
        }
      },
      child: const Text('Add Regulation'),
    );
  }

  Future<String?> _showEditRegulationDialog(String currentRegulation) async {
    final TextEditingController controller = TextEditingController(text: currentRegulation);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Regulation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new regulation'),
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

  Future<String?> _showAddRegulationDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Regulation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter regulation'),
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
