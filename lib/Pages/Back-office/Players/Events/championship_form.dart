import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ChampionshipForm extends StatefulWidget {
  final DocumentSnapshot<Object?>? championship;
  final List<String> groups;

  const ChampionshipForm({Key? key, this.championship, required this.groups})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ChampionshipFormState createState() => _ChampionshipFormState();
}

class _ChampionshipFormState extends State<ChampionshipForm> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _feeController = TextEditingController();
  final _documentsController = TextEditingController();
  final _criteriaController = TextEditingController();
  Uint8List? _tournamentImageBytes;
  String? _tournamentImageUrl;
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

  void _loadChampionshipData(DocumentSnapshot<Object?> championship) {
    final data = championship.data() as Map<String, dynamic>;
    setState(() {
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
    });
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
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        Uint8List imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _tournamentImageBytes = imageBytes;
        });
        print("📷 Image selected successfully.");
      } else {
        print("⚠ No image selected.");
      }
    } catch (e) {
      print("❌ Error selecting image: $e");
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes) async {
    int retries = 3;
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final storageRef = FirebaseStorage.instance.ref();
        final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final imageRef = storageRef.child("championship_images/$fileName");

        print("📤 Attempt $attempt: Uploading to Firebase Storage...");
        UploadTask uploadTask = imageRef.putData(imageBytes);
        TaskSnapshot snapshot = await uploadTask;

        String imageUrl = await snapshot.ref.getDownloadURL();
        print("✅ Upload successful: $imageUrl");
        return imageUrl;
      } catch (e) {
        print("❌ Upload failed (Attempt $attempt): $e");
        if (attempt == retries) return null;
        await Future.delayed(Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<void> _saveChampionship() async {
    if (_nameController.text.isEmpty || _selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
      return;
    }

    try {
      if (_tournamentImageBytes != null) {
        _tournamentImageUrl = await _uploadImage(_tournamentImageBytes!);
        if (_tournamentImageUrl == null) throw Exception("Image upload failed");
      }

      List<Future<Map<String, dynamic>>> futures = _matchDays.map((day) async {
        if (day['photo'] is Uint8List) {
          final url = await _uploadImage(day['photo']);
          day['photo'] = url;
        }
        return day;
      }).toList();
      List<Map<String, dynamic>> updatedMatchDays = await Future.wait(futures);

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
        'matchDays': updatedMatchDays,
        'imageUrl': _tournamentImageUrl,
      };

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
    return TemplatePageBack(
        title: (widget.championship == null
            ? 'Ajouter un Championnat'
            : 'Modifier un Championnat'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMainSection(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0))),
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
            if (_tournamentImageBytes != null)
              Image.memory(_tournamentImageBytes!,
                  width: 100, height: 100, fit: BoxFit.cover),
          ],
        ),
      ],
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
                    _selectedChildren.addAll(_childrenByGroup[item] ?? []);
                  } else {
                    selectedItems.remove(item);
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
}
