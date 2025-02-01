import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FriendlyMatchForm extends StatefulWidget {
  final List<String> groups;

  const FriendlyMatchForm({Key? key, required this.groups}) : super(key: key);

  @override
  _FriendlyMatchFormState createState() => _FriendlyMatchFormState();
}

class _FriendlyMatchFormState extends State<FriendlyMatchForm> {
  final _matchNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _tenueController = TextEditingController();
  final _feeController = TextEditingController();

  String? _matchType;
  List<String> _selectedGroups = [];
  List<String> _selectedChildren = [];
  List<DateTime> _matchDates = [];
  TimeOfDay? _departureTime; // For departure time

  final _firestore = FirebaseFirestore.instance;
  Map<String, List<String>> _childrenByGroup = {};

  String? _locationType;
  String? _transportMode;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFree = false;

  final List<String> _matchTypes = ['Contre une académie', 'Contre un groupe Ifoot'];
  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];
  final List<String> _transportModes = ['Covoiturage', 'Bus', 'Individuel'];

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndChildren();
  }

  Future<void> _fetchGroupsAndChildren() async {
    final groupsSnapshot = await _firestore.collection('groups').get();
    final childrenSnapshot = await _firestore.collection('children').get();

    setState(() {
      _childrenByGroup = {
        for (var groupDoc in groupsSnapshot.docs)
          groupDoc['name']: childrenSnapshot.docs
              .where((childDoc) => (childDoc['assignedGroups'] as List).contains(groupDoc.id))
              .map((childDoc) => childDoc['name'] as String)
              .toList(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un match amical')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _matchType,
              items: _matchTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _matchType = value),
              decoration: const InputDecoration(
                labelText: 'Type de match',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
              ),
            ),
            const SizedBox(height: 16),

            if (_matchType == 'Contre une académie')
              TextField(
                controller: _matchNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'académie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
            if (_matchType == 'Contre un groupe Ifoot') ...[
              const SizedBox(height: 16),
              _buildDropdown('Équipe 1', widget.groups),
              const SizedBox(height: 16),
              _buildDropdown('Équipe 2', widget.groups),
            ],
            const SizedBox(height: 16),

            _buildGroupAndChildrenSelection(),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _locationType,
              items: _locationTypes.map((location) {
                return DropdownMenuItem(value: location, child: Text(location));
              }).toList(),
              onChanged: (value) => setState(() => _locationType = value),
              decoration: const InputDecoration(
                labelText: 'Lieu',
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _transportMode,
                items: _transportModes.map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
                }).toList(),
                onChanged: (value) => setState(() {
                  _transportMode = value;
                  if (value == 'Bus') {
                    _pickDepartureTime();
                  }
                }),
                decoration: const InputDecoration(
                  labelText: 'Mode de déplacement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
              ),
              if (_transportMode == 'Bus' && _departureTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Heure de départ : ${_departureTime!.format(context)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickDate,
              child: const Text('Ajouter une date de match'),
            ),
            Wrap(
              spacing: 8,
              children: _matchDates
                  .map((date) => Chip(
                        label: Text('${date.day}/${date.month}/${date.year}'),
                        onDeleted: () => setState(() => _matchDates.remove(date)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tenueController,
              decoration: const InputDecoration(
                labelText: 'Tenue',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checkroom),
              ),
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
            ElevatedButton(
              onPressed: _saveMatch,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupAndChildrenSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMultiSelect('Groupes participants', widget.groups, _selectedGroups),
        const SizedBox(height: 16),
        Text('Enfants participants (${_selectedChildren.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildDropdown(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      value: null,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: (newValue) {
        // Logic for team selection goes here
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() => _matchDates.add(pickedDate));
    }
  }

  Future<void> _pickDepartureTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() => _departureTime = pickedTime);
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

  Future<void> _saveMatch() async {
    if (_matchNameController.text.isEmpty ||
        _selectedGroups.isEmpty ||
        _selectedChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
      return;
    }

    final matchData = {
      'matchName': _matchNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'locationType': _locationType,
      'address': _addressController.text.trim(),
      'fee': _isFree ? 'Gratuit' : _feeController.text.trim(),
      'tenue': _tenueController.text.trim(),
      'dates': _matchDates.map((date) => Timestamp.fromDate(date)).toList(),
      'selectedGroups': _selectedGroups,
      'selectedChildren': _selectedChildren,
      'transportMode': _transportMode,
      'departureTime': _departureTime?.format(context),
    };

    try {
      await _firestore.collection('friendlyMatches').add(matchData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match enregistré avec succès!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    }
  }
}
