// ignore_for_file: library_private_types_in_public_api, empty_catches, use_build_context_synchronously, unused_local_variable, deprecated_member_use

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'journee_details.dart';

class ChampionshipDetails extends StatefulWidget {
  final DocumentSnapshot? championship;
  final List<String> groups;

  const ChampionshipDetails({Key? key, required this.groups, this.championship})
      : super(key: key);

  @override
  _ChampionshipDetailsState createState() => _ChampionshipDetailsState();
}

class _ChampionshipDetailsState extends State<ChampionshipDetails> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationTypeController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _criteriaController = TextEditingController();
  String? _locationType;

  Map<String, List<String>> _childrenByGroup = {};
  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];

  final _feeController = TextEditingController();
  final _documentsController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isFree = false;

  List<String> _selectedGroups = [];
  Uint8List? _imageBytes;
  List<String> _selectedChildren = [];
  String? _imageUrl;
  List<dynamic> matchDays = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController =
      ScrollController(); // ✅ Scroll Controller

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchGroupsAndChildren();
    _buildMultiSelect('Groupes Participants', widget.groups, _selectedGroups);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ Nettoyage pour éviter les fuites mémoire
    super.dispose();
  }

  void _loadData() {
  if (widget.championship != null && widget.championship!.exists) {
    final data = widget.championship!.data() as Map<String, dynamic>? ?? {};

    _nameController.text = data['name'] ?? '';
    _addressController.text = data['address'] ?? '';
    _locationType = data['locationType'];
    _locationTypeController.text = data['locationType'] ?? '';
    _itineraryController.text = data['itinerary'] ?? '';
    _criteriaController.text = data['criteria'] ?? '';

    _isFree = data['fee'] == 'Gratuit';
    _feeController.text = !_isFree && data['fee'] != null ? data['fee'].toString() : ''; // ✅ Corrige le tarif
    
    _documentsController.text = data['documents'] ?? '';
    _selectedGroups = List<String>.from(data['selectedGroups'] ?? []);
    _imageUrl = data['imageUrl'];
    matchDays = data['matchDays'] ?? [];

    // ✅ Corrige la récupération des enfants sélectionnés
    if (data.containsKey('selectedChildren') && data['selectedChildren'] is List) {
      _selectedChildren = List<String>.from(data['selectedChildren']);
    }

    setState(() {}); // Met à jour l'affichage
  }
}


  Future<void> _pickImage() async {
 
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        Uint8List imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = imageBytes;
        });
      }
    
  }

  Future<String?> _uploadImage(Uint8List imageBytes) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final imageRef = storageRef.child("championship_images/$fileName");

      UploadTask uploadTask = imageRef.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec de l'upload de l'image : $e")),
      );
      return null;
    }
  }

  Future<void> _saveChampionshipDetails() async {
    try {
      // 🔹 Upload Image if a new one is selected
      if (_imageBytes != null) {
        _imageUrl = await _uploadImage(_imageBytes!);
      }

      // 🔹 Validate Required Fields
      if (_nameController.text.isEmpty || _selectedGroups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez remplir tous les champs obligatoires.')),
        );
        return;
      }

      // 🔹 Build the Championship Data
      final championshipData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'locationType': _locationType ?? _locationTypeController.text.trim(),
        'itinerary': _itineraryController.text.trim().isNotEmpty
            ? _itineraryController.text.trim()
            : null,
        'criteria': _criteriaController.text.trim().isNotEmpty
            ? _criteriaController.text.trim()
            : null,
              'fee': _isFree ? 'Gratuit' : _feeController.text.trim().isNotEmpty
            ? _criteriaController.text.trim()
            : null,
        'documents': _documentsController.text.trim().isNotEmpty
            ? _documentsController.text.trim()
            : null,
        'selectedGroups': _selectedGroups,
        'selectedChildren': _selectedChildren,
        'imageUrl': _imageUrl ,
        'matchDays': matchDays.isNotEmpty ? matchDays : [],
      };

      // 🔹 Save or Update in Firestore
      if (widget.championship == null) {
        // ➕ Create New Championship
        DocumentReference newChampionship = await FirebaseFirestore.instance
            .collection('championships')
            .add(championshipData);
      } else {
        // ✏️ Update Existing Championship
        await FirebaseFirestore.instance
            .collection('championships')
            .doc(widget.championship!.id)
            .update(championshipData);
      }

      // ✅ Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Championnat enregistré avec succès!')),
      );

      // 🔙 Go Back to Previous Page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: (widget.championship != null
          ? "Modifier Championnat"
          : "Créer Championnat"),
          isCoach: false,
          footerIndex: 3,
      actions: [
        IconButton(
            icon: const Icon(Icons.save), onPressed: _saveChampionshipDetails),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Informations Générales'),
            _buildSectionTitle('Nom du Championnat', Icons.emoji_events),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du Championnat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
              _buildSectionHeader('Photo du Championnat'),

            // 🔹 Zone de téléchargement avec aperçu de l’image
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔹 Affichage de l’image sélectionnée
                _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _imageBytes!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.grey.shade400, width: 2),
                          color: Colors.grey.shade200,
                        ),
                        child: const Icon(Icons.image,
                            size: 50, color: Colors.grey),
                      ),

                const SizedBox(width: 16),

                // 🔹 Boutons : Choisir une image & Supprimer
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text('Télécharger'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_imageBytes != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _imageBytes = null;
                            _imageUrl = null;
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Supprimer',
                            style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Lieu', Icons.place),
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
                  _buildSectionTitle('Adresse', Icons.location_on),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
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
            _buildSectionHeader('Participants'),
            _buildSectionTitle('Groupes Participants', Icons.groups),
            _buildMultiSelect('Groupes Participants',
                _childrenByGroup.keys.toList(), _selectedGroups),
            const SizedBox(height: 16),
            Text('Joueurs sélectionnés (${_selectedChildren.length})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 16),
            _buildSectionHeader('Documents et Critères'),
            _buildSectionTitle('Documents Requis', Icons.description),
            TextField(
              controller: _documentsController,
              decoration: const InputDecoration(
                labelText: 'Documents Requis',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Critères d\'entrée', Icons.rule),
            TextField(
              controller: _criteriaController,
              decoration: const InputDecoration(
                labelText: 'Critères d\'entrée',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(
                'Informations Financières', Icons.monetization_on),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feeController,
                    enabled: !_isFree,
                    decoration: const InputDecoration(
                      labelText: 'Tarif (en TND)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Checkbox(
                  value: _isFree,
                  onChanged: (value) {
                    setState(() {
                      _isFree = value!;
                      if (_isFree) {
                        _feeController.clear();
                      }
                    });
                  },
                ),
                const Text('Gratuit', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            _buildMatchDaysSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
                    // ✅ Ajouter groupe et ses joueurs
                    selectedItems.add(item);
                    _selectedChildren.addAll(_childrenByGroup[item] ?? []);
                  } else {
                    // ✅ Retirer groupe et ses joueurs
                    selectedItems.remove(item);
                    _selectedChildren.removeWhere((child) =>
                        (_childrenByGroup[item] ?? []).contains(child));
                  }
                });

                // ✅ Mise à jour automatique dans Firebase
                _updateChampionshipData();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _updateChampionshipData() async {
    if (widget.championship != null) {
      try {
        await _firestore
            .collection('championships')
            .doc(widget.championship!.id)
            .update({
          'selectedGroups': _selectedGroups,
          'selectedChildren': _selectedChildren,
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur mise à jour Firestore: $e")),
        );
      }
    }
  }

  Widget _buildMatchDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Journées du Championnat'),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  matchDays.add({
                    'date': '',
                    'time': '',
                    'transportMode': '',
                    'coaches': []
                  });
                });

                // ✅ Scroller vers la dernière journée après ajout
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                });
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Ajouter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ✅ Ajout de `SizedBox` pour définir une hauteur fixe
        SizedBox(
          height:
              300, // Hauteur fixe pour éviter l'erreur de contrainte infinie
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: true, // ✅ Permet au `ListView` de s'ajuster au contenu
            itemCount: matchDays.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> day = matchDays[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text("Journée N${index + 1}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteJournee(index),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    ],
                  ),
                  onTap: () => _navigateToJourneeDetails(index, day),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🛑 **Confirmation Popup Before Deleting**
  void _confirmDeleteJournee(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content:
              Text("Voulez-vous vraiment supprimer la Journée ${index + 1} ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  matchDays.removeAt(index);
                });

                // 🔹 Mettre à jour Firestore immédiatement
                await _firestore
                    .collection('championships')
                    .doc(widget.championship?.id)
                    .update({
                  'matchDays': matchDays,
                });

                Navigator.of(context).pop();
              },
              child:
                  const Text("Supprimer", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToJourneeDetails(int index, Map<String, dynamic> day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneeDetails(
          championshipId: widget.championship?.id ?? '',
          journeeIndex: index,
          journeeData: day,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent)),
    );
  }
}
