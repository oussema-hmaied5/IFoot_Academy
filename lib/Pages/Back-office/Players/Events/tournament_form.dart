import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TournamentForm extends StatefulWidget {
  final DocumentSnapshot<Object?>? tournament;
  final List<String> groups;
  final Map<String, dynamic>? eventData;

  const TournamentForm(
      {Key? key, this.tournament, required this.groups, this.eventData})
      : super(key: key);

  @override
  _TournamentFormState createState() => _TournamentFormState();
}

class _TournamentFormState extends State<TournamentForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _tenueController = TextEditingController();
  final _documentsController = TextEditingController();
  final _feeController = TextEditingController();

  String? _locationType;
  bool _isFree = false;
  List<DateTime> _tournamentDates = [];
  List<String> _selectedGroups = [];
  List<String> _selectedChildren = [];
  String? _transportMode;

  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];
  final List<String> _transportModes = ['Covoiturage', 'Bus', 'Individuel'];
  Map<String, List<String>> _childrenByGroup = {};
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndChildren();
    if (widget.tournament != null) {
      _loadTournamentData(widget.tournament!);
    }
    if (widget.eventData != null) {
      _loadTournamentDataFromEvent(widget.eventData!);
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

  void _loadTournamentData(DocumentSnapshot<Object?> tournament) {
    final data = tournament.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _locationType = data['locationType'];
    _addressController.text = data['address'] ?? '';
    _itineraryController.text = data['itinerary'] ?? '';
    _feeController.text = data['fee'] ?? '';
    _isFree = data['fee'] == 'Gratuit';
    _tenueController.text = data['tenue'] ?? '';
    _documentsController.text = data['documents'] ?? '';
    _tournamentDates = (data['dates'] as List)
        .map((date) => date is Timestamp ? date.toDate() : DateTime.parse(date))
        .toList();
    _selectedGroups = List<String>.from(data['selectedGroups'] ?? []);
    _selectedChildren = List<String>.from(data['selectedChildren'] ?? []);
    _transportMode = data['transportMode'];
  }

  void _loadTournamentDataFromEvent(Map<String, dynamic> eventData) {
    _nameController.text = eventData['name'] ?? '';
    _descriptionController.text = eventData['description'] ?? '';
    _locationType = eventData['locationType'];
    _addressController.text = eventData['address'] ?? '';
    _itineraryController.text = eventData['itinerary'] ?? '';
    _feeController.text = eventData['fee'] ?? '';
    _isFree = eventData['fee'] == 'Gratuit';
    _tenueController.text = eventData['tenue'] ?? '';
    _documentsController.text = eventData['documents'] ?? '';
    _tournamentDates = (eventData['dates'] as List)
        .map((date) => date is Timestamp ? date.toDate() : DateTime.parse(date))
        .toList();
    _selectedGroups = List<String>.from(eventData['selectedGroups'] ?? []);
    _selectedChildren = List<String>.from(eventData['selectedChildren'] ?? []);
    _transportMode = eventData['transportMode'];
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() => _tournamentDates.add(pickedDate));
    }
  }

  Future<void> _pickTime(
      BuildContext context, void Function(String) onTimePicked) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: true), // ✅ Force 24-hour format
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Convert to "HH:mm" format
      String formattedTime =
          "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      onTimePicked(formattedTime);
    }
  }

  Future<void> _openMaps() async {
    final address = _addressController.text;
    if (address.isNotEmpty) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$address';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir Google Maps.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une adresse.')),
      );
    }
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

  Widget _buildGroupAndChildrenSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMultiSelect('Groupes participants',
            _childrenByGroup.keys.toList(), _selectedGroups),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.date_range),
              label: const Text('Ajouter une date'),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tournamentDates.map((date) {
                    String formattedDate =
                        DateFormat("dd/MM/yyyy").format(date);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(
                        label: Text(formattedDate),
                        deleteIcon: const Icon(Icons.cancel,
                            size: 18, color: Colors.red),
                        onDeleted: () =>
                            setState(() => _tournamentDates.remove(date)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: (widget.tournament == null
          ? 'Ajouter un tournoi'
          : 'Modifier un tournoi'),
      footerIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle('Informations Générales', Icons.info),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du tournoi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Date du Tournoi', Icons.date_range),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildSectionTitle('Lieu et Itinéraire', Icons.place),
            DropdownButtonFormField<String>(
              value: _locationType,
              items: _locationTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _locationType = value),
              decoration: const InputDecoration(
                labelText: 'Type de lieu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
            if (_locationType == 'Extérieur') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _openMaps,
                child: const Text('Choisir un point sur Google Maps'),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _itineraryController,
              decoration: const InputDecoration(
                labelText: 'Itinéraire',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Transport', Icons.directions_bus),
            DropdownButtonFormField<String>(
              value: _transportMode,
              items: _transportModes.map((mode) {
                return DropdownMenuItem(value: mode, child: Text(mode));
              }).toList(),
              onChanged: (value) => setState(() => _transportMode = value),
              decoration: const InputDecoration(
                labelText: 'Mode de transport',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bus),
              ),
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
                      labelText: 'Tarif (en €)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
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
            _buildSectionTitle('Tenue et Documents', Icons.description),
            TextField(
              controller: _tenueController,
              decoration: const InputDecoration(
                labelText: 'Tenue',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.style),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _documentsController,
              decoration: const InputDecoration(
                labelText: 'Documents requis',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Description', Icons.description),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildGroupAndChildrenSelection(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveTournament,
              icon: const Icon(Icons.save),
              label: Text(
                  widget.tournament == null ? 'Enregistrer' : 'Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTournament() async {
    if (_nameController.text.isEmpty ||
        _selectedGroups.isEmpty ||
        _selectedChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
      return;
    }

    final tournamentData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'locationType': _locationType,
      'address': _addressController.text.trim(),
      'itinerary': _itineraryController.text.trim(),
      'fee': _isFree ? 'Gratuit' : _feeController.text.trim(),
      'tenue': _tenueController.text.trim(),
      'documents': _documentsController.text.trim(),
      'dates': _tournamentDates
          .map((date) => Timestamp.fromDate(date))
          .toList(), // ✅ Store as Timestamp
      'selectedGroups': _selectedGroups,
      'selectedChildren': _selectedChildren,
      'transportMode': _transportMode,
    };

    try {
      if (widget.tournament == null) {
        await _firestore.collection('tournaments').add(tournamentData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournoi enregistré avec succès!')),
        );
      } else {
        await _firestore
            .collection('tournaments')
            .doc(widget.tournament!.id)
            .update(tournamentData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournoi mis à jour avec succès!')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    }
  }

  
}
