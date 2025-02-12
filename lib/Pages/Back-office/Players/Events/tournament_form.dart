import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:url_launcher/url_launcher.dart';

class TournamentForm extends StatefulWidget {
  final DocumentSnapshot<Object?>? tournament;
  final List<String> groups;

  const TournamentForm({Key? key, this.tournament, required this.groups})
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

  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];
  List<String> _groups = [];
  Map<String, List<String>> _childrenByGroup = {};
  String? _transportMode;

  final List<String> _transportModes = ['Covoiturage', 'Bus', 'Individuel'];

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndChildren();
    if (widget.tournament != null) {
      _loadTournamentData(widget.tournament!);
    }
  }

  Future<void> _fetchGroupsAndChildren() async {
    final groupsSnapshot = await _firestore.collection('groups').get();
    final childrenSnapshot = await _firestore.collection('children').get();

    setState(() {
      _groups =
          groupsSnapshot.docs.map((doc) => doc['name'] as String).toList();

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
        .map((date) => (date as Timestamp).toDate())
        .toList();
    _selectedGroups = List<String>.from(data['selectedGroups'] ?? []);
    _selectedChildren = List<String>.from(data['selectedChildren'] ?? []);
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

  Future<void> _selectItinerary() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez activer les services de localisation.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Permission de localisation refusée.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Permission de localisation bloquée définitivement.')),
        );
        return;
      }

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
        throw 'Impossible d\'ouvrir la carte.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la localisation : $e')),
      );
    }
  }

    Future<void> _saveTournament() async {
      if (_nameController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _locationType == null ||
          _tournamentDates.isEmpty ||
          _selectedGroups.isEmpty) {
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
        'dates':
            _tournamentDates.map((date) => Timestamp.fromDate(date)).toList(),
        'selectedGroups': _selectedGroups,
        'selectedChildren': _selectedChildren,
        'transportMode': _transportMode,
      };

      try {
        if (widget.tournament == null) {
          await _firestore.collection('tournaments').add(tournamentData);
        } else {
          await _firestore
              .collection('tournaments')
              .doc(widget.tournament!.id)
              .update(tournamentData);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournoi enregistré avec succès!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }

    Widget _buildMultiSelect(
        String label, List<String> items, List<String> selectedItems) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${selectedItems.length} sélectionné(s)',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
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
                    } else {
                      selectedItems.remove(item);
                    }
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
          _buildMultiSelect('Groupes participants', _groups, _selectedGroups),
          const SizedBox(height: 16),
          Text('Enfants participants (${_selectedChildren.length})',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._selectedGroups.map((group) {
            final children = _childrenByGroup[group] ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$group (${children.length})',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () {
                        setState(() {
                          for (final child in children) {
                            if (!_selectedChildren.contains(child)) {
                              _selectedChildren.add(child);
                            }
                          }
                        });
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: children.map((child) {
                    final isSelected = _selectedChildren.contains(child);
                    return FilterChip(
                      label: Text(child),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedChildren.add(child);
                          } else {
                            _selectedChildren.remove(child);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      );
    }

    @override
    Widget build(BuildContext context) {
      return TemplatePageBack(
          title: (widget.tournament == null
              ? 'Ajouter un tournoi'
              : 'Modifier un tournoi'),
        
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du tournoi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_soccer),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itineraryController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Itinéraire',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _selectItinerary,
                      child: const Text('Choisir un point sur Google Maps'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _transportMode,
                  items: _transportModes.map((mode) {
                    return DropdownMenuItem(value: mode, child: Text(mode));
                  }).toList(),
                  onChanged: (value) => setState(() => _transportMode = value),
                  decoration: const InputDecoration(
                    labelText: 'Mode de déplacement',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickDate,
                child: const Text('Ajouter une date'),
              ),
              Wrap(
                spacing: 8,
                children: _tournamentDates
                    .map((date) => Chip(
                          label: Text('${date.day}/${date.month}/${date.year}'),
                          onDeleted: () =>
                              setState(() => _tournamentDates.remove(date)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
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
              Row(
                children: [
                  const Text('Tarif:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
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
              _buildGroupAndChildrenSelection(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveTournament,
                child: Text(widget.tournament == null
                    ? 'Enregistrer'
                    : 'Mettre à jour'),
              ),
            ],
          ),
        ),
      );
    }
  }

