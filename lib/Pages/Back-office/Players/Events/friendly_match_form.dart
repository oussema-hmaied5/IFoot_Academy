// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:url_launcher/url_launcher.dart';

class FriendlyMatchForm extends StatefulWidget {
  final List<String> groups;
  final Map<String, dynamic>? eventData;

  const FriendlyMatchForm({Key? key, required this.groups, this.eventData})
      : super(key: key);

  @override
  _FriendlyMatchFormState createState() => _FriendlyMatchFormState();
}

class _FriendlyMatchFormState extends State<FriendlyMatchForm> {
  final _matchNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _addressController = TextEditingController();
  final _tenueController = TextEditingController();
  final _feeController = TextEditingController();

  String? _matchType;
  List<String> _selectedGroups = [];
  List<String> _selectedChildren = [];
  List<DateTime> _matchDates = [];

  final _firestore = FirebaseFirestore.instance;
  Map<String, List<String>> _childrenByGroup = {};

  String? _locationType;
  bool _loadingGroups = true;
  List<String> _availableGroups = [];
  String? _transportMode;
  String? _group1;
  String? _group2;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFree = false;

  final List<String> _matchTypes = [
    'Contre une académie',
    'Contre un groupe Ifoot'
  ];
  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];
  final List<String> _transportModes = ['Covoiturage', 'Bus', 'Individuel'];

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndChildren();
    _fetchGroups();

    if (widget.eventData != null) {
      _preFillFormFields();
    }
  }

  void _preFillFormFields() {
    _matchNameController.text = widget.eventData!['matchName'] ?? '';
    _descriptionController.text = widget.eventData!['description'] ?? '';
    _locationType = widget.eventData!['locationType'];
    _addressController.text = widget.eventData!['address'] ?? '';
    _itineraryController.text = widget.eventData!['itinerary'] ?? '';
    _feeController.text = widget.eventData!['fee'] ?? '';
    _tenueController.text = widget.eventData!['tenue'] ?? '';
    _matchDates = (widget.eventData!['dates'] as List<dynamic>)
        .map((timestamp) => (timestamp as Timestamp).toDate())
        .toList();
    _selectedGroups =
        List<String>.from(widget.eventData!['selectedGroups'] ?? []);
    _selectedChildren =
        List<String>.from(widget.eventData!['selectedChildren'] ?? []);
    _transportMode = widget.eventData!['transportMode'];
    _isFree = widget.eventData!['fee'] == 'Gratuit';
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

  Future<void> _fetchGroups() async {
    try {
      final groupsSnapshot = await _firestore.collection('groups').get();
      setState(() {
        _availableGroups = groupsSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _loadingGroups = false;
      });
    } catch (e) {
      debugPrint("Erreur lors de la récupération des groupes : $e");
    }
  }

@override
Widget build(BuildContext context) {
  return TemplatePageBack(
    title: 'Ajouter un match amical',
    footerIndex: 3,

    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionTitle('Type de match', Icons.sports_soccer),
          DropdownButtonFormField<String>(
            value: _matchType,
            items: _matchTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _matchType = value;
                if (_matchType == 'Contre un groupe Ifoot') {
                  _locationType = 'Ifoot'; // Set default location
                } else {
                  _locationType = null; // Allow user selection for other match types
                }
              });
            },
            decoration: const InputDecoration(
              labelText: 'Type de match',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_soccer),
            ),
          ),
          const SizedBox(height: 16),

          // 🔹 IF "Contre une académie", show input for academy name
          if (_matchType == 'Contre une académie')
            TextField(
              controller: _matchNameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'académie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),

          // 🔹 IF "Contre un groupe Ifoot", show Équipe selection
          if (_matchType == 'Contre un groupe Ifoot') ...[
            const SizedBox(height: 16),
            _loadingGroups
                ? const Center(child: CircularProgressIndicator())
                : _buildDropdown('Équipe 1', _availableGroups, _group1, (value) {
                    setState(() {
                      _group1 = value;
                      debugPrint("Équipe 1 sélectionnée: $_group1");
                    });
                  }),
            const SizedBox(height: 16),
            _loadingGroups
                ? const Center(child: CircularProgressIndicator())
                : _buildDropdown('Équipe 2', _availableGroups, _group2, (value) {
                    setState(() {
                      _group2 = value;
                      debugPrint("Équipe 2 sélectionnée: $_group2");
                    });
                  }),
          ],

          // 🔹 IF "Contre une académie", allow group & player selection
          if (_matchType == 'Contre une académie') ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Sélection des groupes', Icons.groups),
            _loadingGroups
                ? const Center(child: CircularProgressIndicator())
                : _buildMultiSelect(
                    'Sélectionnez les groupes',
                    _availableGroups,
                    _selectedGroups,
                  ),

            const SizedBox(height: 16),

            _buildSectionTitle('Sélection des joueurs', Icons.person),
            for (String group in _selectedGroups)
              _buildMultiSelect(
                'Joueurs du groupe $group',
                _childrenByGroup[group] ?? [],
                _selectedChildren,
              ),
          ],

          const SizedBox(height: 16),
          _buildSectionTitle('Lieu', Icons.place),
          DropdownButtonFormField<String>(
            value: _locationType,
            items: _locationTypes.map((location) {
              return DropdownMenuItem(value: location, child: Text(location));
            }).toList(),
            onChanged: _matchType == 'Contre un groupe Ifoot' ? null : (value) => setState(() => _locationType = value),
            decoration: const InputDecoration(
              labelText: 'Lieu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place),
            ),
          ),
          const SizedBox(height: 16),

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
            
          _buildSectionTitle('Mode de transport', Icons.directions_car),
          DropdownButtonFormField<String>(
            value: _transportMode,
            items: _transportModes.map((mode) {
              return DropdownMenuItem(value: mode, child: Text(mode));
            }).toList(),
            onChanged: (value) => setState(() => _transportMode = value),
            decoration: const InputDecoration(
              labelText: 'Mode de transport',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_car),
            ),
          ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Date du match', Icons.date_range),
                    ElevatedButton(
                      onPressed: _pickDate,
                      child: const Text('Choisir la date'),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _matchDates
                          .map((date) => Chip(
                                label: Text('${date.day}/${date.month}'),
                                onDeleted: () => setState(() => _matchDates.remove(date)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Heure du match', Icons.access_time),
                    ElevatedButton(
                      onPressed: _pickStartTime,
                      child: Text(_startTime != null
                          ? 'Début: ${_startTime!.format(context)}'
                          : 'Choisir heure début'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickEndTime,
                      child: Text(_endTime != null
                          ? 'Fin: ${_endTime!.format(context)}'
                          : 'Choisir heure fin'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildSectionTitle('Tenue', Icons.checkroom),
          TextField(
            controller: _tenueController,
            decoration: const InputDecoration(
              labelText: 'Tenue',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.checkroom),
            ),
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
          _buildSectionTitle('Frais de participation', Icons.money),
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
          ElevatedButton.icon(
            onPressed: _saveMatch,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _pickStartTime() async {
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (pickedTime != null) {
    setState(() {
      _startTime = pickedTime;
    });
  }
}

Future<void> _pickEndTime() async {
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (pickedTime != null) {
    setState(() {
      _endTime = pickedTime;
    });
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

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.people),
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



Future<void> _saveMatch() async {

  // ✅ **Fix: If the match type is "Contre un groupe Ifoot", store Équipe 1 and Équipe 2 in `_selectedGroups`**
  if (_matchType == 'Contre un groupe Ifoot') {
    _selectedGroups = [];
    if (_group1 != null) _selectedGroups.add(_group1!);
    if (_group2 != null) _selectedGroups.add(_group2!);
  }


  // ✅ **Ensure required fields are filled based on match type**
  if (_matchType == null ||
      _descriptionController.text.trim().isEmpty ||
      _locationType == null ||
      _matchDates.isEmpty ||
      _selectedGroups.isEmpty || // 🔹 Groups must be selected
      (_matchType == 'Contre une académie' && _matchNameController.text.trim().isEmpty) || // 🔹 Match Name required only for "Contre une académie"
      (_matchType == 'Contre une académie' && _selectedChildren.isEmpty) || // 🔹 Children required only for "Contre une académie"
      (_locationType == 'Extérieur' && _addressController.text.trim().isEmpty) || // 🔹 Address required only if "Extérieur"
      (_isFree == false && _feeController.text.trim().isEmpty) || // 🔹 Fee required if not free
      (_transportMode == 'Bus' && _startTime == null)) { // 🔹 Departure time required if transport is "Bus"
      
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires.')),
    );
    return;
  }

  // 🔹 **Set fee to "0" if match is free**
  final matchFee = _isFree ? '0' : _feeController.text.trim();

  // 🔹 **Prepare match data for Firestore**
  final matchData = {
    'matchType': _matchType,
    'description': _descriptionController.text.trim(),
    'locationType': _locationType,
    'fee': matchFee,
    'tenue': _tenueController.text.trim(),
    'dates': _matchDates.map((date) => Timestamp.fromDate(date)).toList(),
    'selectedGroups': _selectedGroups,
    'selectedChildren': _matchType == 'Contre une académie' ? _selectedChildren : [], // 🔹 Save only if required
    'transportMode': _locationType == 'Ifoot' ? null : _transportMode, // 🔹 Remove transportMode if match is in "Ifoot"
    'startTime': _startTime?.format(context),
    'endTime': _endTime?.format(context),
  };

  // 🔹 **Add match name only if it's "Contre une académie"**
  if (_matchType == 'Contre une académie') {
    matchData['matchName'] = _matchNameController.text.trim();
  }

  // 🔹 **Remove address and itinerary if match is at "Ifoot"**
  if (_locationType == 'Extérieur') {
    matchData['address'] = _addressController.text.trim();
    matchData['itinerary'] = _itineraryController.text.trim();
  }

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