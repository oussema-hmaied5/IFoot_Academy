import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChampionshipForm extends StatefulWidget {
  final DocumentSnapshot<Object?>? championship;
  final List<String> groups;

  const ChampionshipForm({Key? key, this.championship, required this.groups})
      : super(key: key);
  @override
  _ChampionshipFormState createState() => _ChampionshipFormState();
}

class _ChampionshipFormState extends State<ChampionshipForm> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _feeController = TextEditingController();
  final _documentsController = TextEditingController();
  final _criteriaController = TextEditingController();
  File? _tournamentImage;
  String? _locationType;
  List<String> _selectedGroups = [];
  List<String> _selectedChildren = [];
  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];
  Map<String, List<String>> _childrenByGroup = {};
  List<Map<String, dynamic>> _matchDays = [];
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.championship != null) {
      _loadChampionshipData(widget.championship!);
    }
    _fetchGroupsAndChildren();
  }

  Future<void> _fetchGroupsAndChildren() async {
    final groupsSnapshot = await _firestore.collection('groups').get();
    final childrenSnapshot = await _firestore.collection('children').get();

    setState(() {
      _childrenByGroup = {
        for (var groupDoc in groupsSnapshot.docs)
          groupDoc['name']: childrenSnapshot.docs
              .where((childDoc) =>
                  (childDoc['assignedGroups'] as List).contains(groupDoc.id))
              .map((childDoc) => childDoc['name'] as String)
              .toList(),
      };
    });
  }

 Future<void> _pickImage() async {
  try {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tournamentImage = File(pickedFile.path);
      });
    }
  } catch (e) {
    print("Error picking image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error picking image: $e')),
    );
  }
}


  Future<void> _selectItinerary() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final mapsUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      if (await canLaunch(mapsUrl)) {
        await launch(mapsUrl);
        _itineraryController.text =
            '${position.latitude}, ${position.longitude}';
      } else {
        throw 'Could not open the map.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la localisation : $e')),
      );
    }
  }

  void _loadChampionshipData(DocumentSnapshot<Object?> championship) {
    final data = championship.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _locationType = data['locationType'];
    _addressController.text = data['address'] ?? '';
    _itineraryController.text = data['itinerary'] ?? '';
    _feeController.text = data['fee'] ?? '';
    _documentsController.text = data['documents'] ?? '';
    _criteriaController.text = data['criteria'] ?? '';
    _selectedGroups = List<String>.from(data['selectedGroups'] ?? []);
    _selectedChildren = List<String>.from(data['selectedChildren'] ?? []);
    _matchDays = List<Map<String, dynamic>>.from(data['matchDays'] ?? []);
  }

  Future<void> _addMatchDay() async {
    setState(() {
      int matchDayNumber = _matchDays.length + 1;
      _matchDays.add({
        'date': DateTime.now(),
        'location': '',
        'time': '',
        'transportMode': 'Bus', // Default to Bus
        'tenue': '',
        'photo': null,
        'teams': [],
        'name': 'Journée N$matchDayNumber',
      });
    });
  }

  void _deleteMatchDay(int index) {
    setState(() {
      _matchDays.removeAt(index);
      for (int i = 0; i < _matchDays.length; i++) {
        _matchDays[i]['name'] = 'Journée N${i + 1}';
      }
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
  try {
    final storageRef = FirebaseStorage.instance.ref();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final imageRef = storageRef.child("championship_images/$fileName.jpg");

    final uploadTask = imageRef.putFile(imageFile);

    await uploadTask.whenComplete(() async {
      final imageUrl = await imageRef.getDownloadURL();
      print("Image uploaded: $imageUrl"); // Debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image uploaded successfully!")),
      );
      return imageUrl;
    });
  } catch (e) {
    print("Error uploading image: $e"); // Debugging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error uploading image: $e")),
    );
    return null;
  }
  return null;
}


  Future<void> _saveChampionship() async {
    if (_nameController.text.isEmpty || _selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
        ),
      );
      return;
    }

    // Upload de l'image si elle existe
    String? imageUrl;
    if (_tournamentImage != null) {
      imageUrl = await _uploadImage(_tournamentImage!);
    }

    // Préparer les données
    final championshipData = {
      'name': _nameController.text.trim(),
      'locationType': _locationType,
      'address': _addressController.text.trim(),
      'itinerary': _itineraryController.text.trim(),
      'fee': _feeController.text.trim(),
      'documents': _documentsController.text.trim(),
      'criteria': _criteriaController.text.trim(),
      'selectedGroups': _selectedGroups,
      'selectedChildren': _selectedChildren,
      'matchDays': _matchDays.map((day) {
        // Upload des images pour chaque journée de match
        if (day['photo'] is File) {
          // Remplacer le fichier par l'URL uploadée
          return _uploadImage(day['photo']).then((url) {
            day['photo'] = url;
            return day;
          });
        }
        return day;
      }).toList(),
      'imageUrl': imageUrl, // Sauvegarder l'URL de l'image principale
    };

    try {
      if (widget.championship == null) {
        await _firestore.collection('championships').add(championshipData);
      } else {
        await _firestore
            .collection('championships')
            .doc(widget.championship!.id)
            .update(championshipData);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Championnat enregistré avec succès!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.championship == null
            ? 'Ajouter un Championnat'
            : 'Modifier un Championnat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSectionDivider('Informations Principales'),
                  _buildMainSection(),
                  const SizedBox(height: 16),
                  _buildSectionDivider('Journées de Match'),
                  _buildMatchDaysSection(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _saveChampionship,
              child: Text(widget.championship == null
                  ? 'Enregistrer'
                  : 'Mettre à jour'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Column(
      children: [
        Divider(color: Colors.grey, thickness: 1),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Divider(color: Colors.grey, thickness: 1),
      ],
    );
  }

  Widget _buildMainSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du Championnat',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _locationType,
          items: _locationTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) => setState(() => _locationType = value),
          decoration: const InputDecoration(
            labelText: 'Lieu',
            border: OutlineInputBorder(),
          ),
        ),
        if (_locationType == 'Extérieur')
          Column(
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itineraryController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Itinéraire',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: _selectItinerary,
                    child: const Text('Choisir sur la carte'),
                  ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 16),
        _buildMultiSelect('Groupes Participants',
            _childrenByGroup.keys.toList(), _selectedGroups),
        const SizedBox(height: 16),
        TextField(
          controller: _documentsController,
          decoration: const InputDecoration(
            labelText: 'Documents Requis',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _criteriaController,
          decoration: const InputDecoration(
            labelText: 'Critères d\'entrée',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _pickImage,
              child: const Text('Télécharger une photo'),
            ),
            const SizedBox(width: 8),
            if (_tournamentImage != null)
              Image.file(
                _tournamentImage!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: _addMatchDay,
          child: const Text('Ajouter une Journée'),
        ),
        ..._matchDays.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> matchDay = entry.value;
          return GestureDetector(
            onTap: () => _editMatchDay(matchDay),
            child: Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            ' ${matchDay['name'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16, // Optional font size adjustment
                            ),
                          ),
                        ),
                        Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(matchDay['date'])}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Lieu: ${matchDay['location']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Heure: ${matchDay['time']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (matchDay['photo'] != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        matchDay['photo'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMatchDay(index),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _editMatchDay(Map<String, dynamic> matchDay) {
    TextEditingController timeController = TextEditingController(
      text: matchDay['time'] ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text:
                              DateFormat('dd/MM/yyyy').format(matchDay['date']),
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: matchDay['date'],
                            firstDate:
                                DateTime.now().subtract(Duration(days: 365)),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() => matchDay['date'] = pickedDate);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Lieu',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setState(() => matchDay['location'] = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: timeController,
                        decoration: const InputDecoration(
                          labelText: 'Heure du Rendez-vous',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            matchDay['time'] = pickedTime.format(context);
                            timeController.text = pickedTime.format(context);
                          });
                        }
                      },
                      child: const Text('Choisir Heure'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: matchDay['transportMode'] ?? 'Bus',
                  items: ['Bus', 'Covoiturage', 'Individuel'].map((mode) {
                    return DropdownMenuItem(value: mode, child: Text(mode));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => matchDay['transportMode'] = value),
                  decoration: const InputDecoration(
                    labelText: 'Mode de Déplacement',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tenue',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setState(() => matchDay['tenue'] = value),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final pickedFile = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() => matchDay['photo'] = File(pickedFile.path));
                    }
                  },
                  child: const Text('Télécharger une photo'),
                ),
                if (matchDay['photo'] != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(
                      matchDay['photo'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Enregistrer la Journée'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelect(
      String label, List<String> items, List<String> selectedItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedItems.add(item);
                    // Add associated children to selected children
                    _selectedChildren.addAll(_childrenByGroup[item] ?? []);
                  } else {
                    selectedItems.remove(item);
                    // Remove associated children from selected children
                    _selectedChildren.removeWhere((child) =>
                        (_childrenByGroup[item] ?? []).contains(child));
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Joueurs sélectionnés (${_selectedChildren.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: _selectedChildren.map((child) {
            return Chip(
              label: Text(child),
              onDeleted: () {
                setState(() {
                  _selectedChildren.remove(child);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
