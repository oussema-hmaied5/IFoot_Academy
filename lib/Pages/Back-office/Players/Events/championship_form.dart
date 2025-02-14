import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChampionshipForm extends StatefulWidget {
  final DocumentSnapshot<Object?>? championship;
  final List<String> groups;
  final Map<String, dynamic>? eventData;

  const ChampionshipForm(
      {Key? key, this.championship, required this.groups, this.eventData})
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
  List<String> _coaches = [];
  bool _loadingCoaches = true;
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
    _fetchCoaches();

    if (widget.championship != null) {
      _loadChampionshipData(widget.championship!);
    }
    if (widget.eventData != null) {
      _preFillFormFields();
    }
    _fetchGroupsAndChildren();
  }

  void _preFillFormFields() {
    _nameController.text = widget.eventData!['name'] ?? '';
    _locationType = widget.eventData!['locationType'];
    _addressController.text = widget.eventData!['address'] ?? '';
    _itineraryController.text = widget.eventData!['itinerary'] ?? '';
    _feeController.text = widget.eventData!['fee'] ?? '';
    _documentsController.text = widget.eventData!['documents'] ?? '';
    _criteriaController.text = widget.eventData!['criteria'] ?? '';
    _selectedGroups =
        List<String>.from(widget.eventData!['selectedGroups'] ?? []);
    _selectedChildren =
        List<String>.from(widget.eventData!['selectedChildren'] ?? []);
    _matchDays =
        List<Map<String, dynamic>>.from(widget.eventData!['matchDays'] ?? []);
  }

  Future<void> _fetchCoaches() async {
    try {
      final coachesSnapshot = await _firestore.collection('coaches').get();
      setState(() {
        _coaches =
            coachesSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _loadingCoaches = false;
      });
    } catch (e) {
      debugPrint("Erreur lors de la récupération des coachs : $e");
      setState(() => _loadingCoaches = false);
    }
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
      _matchDays = (widget.eventData!['matchDays'] as List<dynamic>?)
              ?.map((day) => {
                    'day': day['day'],
                    'date': day['date'] is String
                        ? DateTime.tryParse(
                            day['date']) // ✅ Converts string to DateTime safely
                        : day['date'], // Keeps DateTime objects unchanged
                    'time': day['time'] != null
                        ? _convertToTimeOfDay(day['time'])
                        : null,
                    'transportMode': day['transportMode'],
                    'coaches': List<String>.from(
                        day['coaches'] ?? []), // ✅ Vérification ici
                    'departureTime': day['departureTime'] != null
                        ? _convertToTimeOfDay(day['departureTime'])
                        : null,
                    'fee': day['fee'],
                  })
              .toList() ??
          [];
    });
  }

  TimeOfDay _convertToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

  Future<void> _pickTime(BuildContext context, int index, String key) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _matchDays[index][key] =
            "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
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
        'imageUrl': _tournamentImageUrl,
        'matchDays': _matchDays
            .map((day) => {
                  'day': day['day'],
                  'date': day['date']?.toIso8601String(),
                  'time': day['time'] is TimeOfDay
                      ? day['time']?.format(context)
                      : day['time'],
                  'transportMode': day['transportMode'],
                  'coaches': List<String>.from(
                      day['coaches'] ?? []), // ✅ Vérification ici
                  'departureTime': day['departureTime'] is TimeOfDay
                      ? day['departureTime']?.format(context)
                      : day['departureTime'],
                  'fee': day['fee'],
                })
            .toList(),
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
        _buildSectionHeader('Photo'),
        _buildSectionTitle('Télécharger une photo', Icons.photo),
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
        _buildSectionHeader('Journées du Championnat'),
        _buildMatchDaysSection(),
      ],
    );
  }

  Widget _buildMatchDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _matchDays.add({
                'day': 'Journée ${_matchDays.length + 1}',
                'date': null,
                'time': null,
                'transportMode': null,
                'coaches': [],
                'departureTime': null,
                'fee': null,
              });
            });
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter une Journée"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        ),
        const SizedBox(height: 10),
        Column(
          children: _matchDays.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> day = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day['day'],
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 8),

                    // Date Picker
                    ListTile(
                      leading: const Icon(Icons.date_range,
                          color: Colors.blueAccent),
                      title: Text(day['date'] is DateTime
                          ? "Date: ${DateFormat('dd/MM/yyyy').format(day['date'] as DateTime)}"
                          : "Sélectionner la date"),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(
                              () => _matchDays[index]['date'] = pickedDate);
                        }
                      },
                    ),

                    // Time Picker (Always 24h)
                    ListTile(
                      leading: const Icon(Icons.access_time,
                          color: Colors.blueAccent),
                      title: Text(day['time'] != null
                          ? "Heure: ${day['time']}"
                          : "Sélectionner l'heure"),
                      onTap: () => _pickTime(context, index, 'time'),
                    ),

                    // Transport Mode
                    DropdownButtonFormField<String>(
                      value: day['transportMode'],
                      items: ['Covoiturage', 'Bus', 'Individuel'].map((mode) {
                        return DropdownMenuItem(value: mode, child: Text(mode));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _matchDays[index]['transportMode'] = value;
                          if (value != 'Bus') {
                            _matchDays[index]['departureTime'] = null;
                            _matchDays[index]['fee'] = null;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Mode de transport",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_bus,
                            color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Coach Selection
                    _loadingCoaches
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Coachs assignés",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 8,
                                children: _coaches.map((coach) {
                                  final isSelected =
                                      (day['coaches'] ?? []).contains(coach);
                                  return FilterChip(
                                    label: Text(coach),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          (_matchDays[index]['coaches'] ??= [])
                                              .add(coach);
                                        } else {
                                          (_matchDays[index]['coaches'] ??= [])
                                              .remove(coach);
                                        }
                                      });
                                    },
                                    selectedColor:
                                        Colors.blueAccent.withOpacity(0.3),
                                    checkmarkColor: Colors.white,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),

                    // Bus-Specific Fields
                    if (day['transportMode'] == 'Bus') ...[
                      const SizedBox(height: 12),
                      // Departure Time
                      ListTile(
                        leading:
                            const Icon(Icons.schedule, color: Colors.redAccent),
                        title: Text(day['departureTime'] != null
                            ? "Heure de départ: ${day['departureTime']}"
                            : "Sélectionner l'heure de départ"),
                        onTap: () => _pickTime(context, index, 'departureTime'),
                      ),

                      // Transport Fee
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Frais de transport (€)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro, color: Colors.redAccent),
                        ),
                        onChanged: (value) {
                          setState(() => _matchDays[index]['fee'] = value);
                        },
                      ),
                    ],

                    // Remove Button
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _matchDays.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Supprimer cette Journée",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
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
