// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:intl/intl.dart';

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
  final _dateController =
      TextEditingController(); // Controller for the date field
  final _addressController = TextEditingController();
  final _tenueController = TextEditingController();
  final _feeController = TextEditingController();
  final Map<String, TextEditingController> _uniformControllers = {};
  final _firestore = FirebaseFirestore.instance;
  final List<String> _matchTypes = [
    'Contre une académie',
    'Contre un groupe Ifoot'
  ];
  String? _matchType;
  List<String> _selectedGroups = [];
  List<String> _selectedChildren = [];
  List<DateTime> _matchDates = [];
  String? _locationType;
  bool _loadingGroups = true;
  List<String> _availableGroups = [];
  String? _transportMode;
  String? _group1;
  String? _group2;
  List<Map<String, dynamic>> _coaches = []; // Stores coaches with session count
  List<String> _selectedCoaches = []; // Selected coaches
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFree = false;
  Map<String, String> _groupUniforms = {};

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndChildren();
    _fetchGroups();
    _fetchCoaches(); // ✅ Fetch coaches and their session limits
    if (widget.eventData != null) {
      _preFillFormFields();
    }
  }


   /// ✅ **Fetch all coaches and their session counts**
  Future<void> _fetchCoaches() async {
  
      final snapshot = await _firestore.collection('coaches').get();
      final allCoaches = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'],
                'maxSessionsPerDay': doc.data().containsKey('maxSessionsPerDay')
                    ? doc.data()['maxSessionsPerDay']
                    : 2,
                'maxSessionsPerWeek':
                    doc.data().containsKey('maxSessionsPerWeek')
                        ? doc.data()['maxSessionsPerWeek']
                        : 10,
                'dailySessions': 0,
                'weeklySessions': 0,
              })
          .toList();

      setState(() {
        _coaches = allCoaches;
      });

      // ✅ Charger les séances en fonction de la date actuelle (ou date sélectionnée)
      if (_dateController.text.isNotEmpty) {
        DateTime selectedDate =
            DateFormat('dd/MM/yyyy').parse(_dateController.text);
        await _fetchCoachSessionCountsForDate(selectedDate);
      }
    
  }

  Future<void> _fetchCoachSessionCountsForDate(DateTime selectedDate) async {
    // ✅ Déterminer la semaine (du lundi au dimanche)
    DateTime startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    Map<String, int> dailySessions = {};
    Map<String, int> weeklySessions = {};

    // ✅ Liste des collections à vérifier
    List<String> collections = [
      'trainings',
      'championships',
      'friendlyMatches',
      'tournaments'
    ];

    for (String collection in collections) {
      final snapshot = await _firestore.collection(collection).get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('coaches')) continue;

        List<dynamic> assignedCoaches = data['coaches'];

        DateTime sessionDate = DateTime.now();
        if (data.containsKey('date')) {
          // ✅ Convertir la date correctement
          if (data['date'] is Timestamp) {
            sessionDate = (data['date'] as Timestamp).toDate();
          } else if (data['date'] is String) {
            try {
              sessionDate = DateTime.parse(data['date']);
            } catch (e) {
              continue;
            }
          } else {
            continue;
          }
        } else if (collection == "championships" &&
            data.containsKey('matchDays')) {
          // ✅ Extraire les dates des matchs dans un championnat
          for (var matchDay in data['matchDays']) {
            if (matchDay is Map<String, dynamic> &&
                matchDay.containsKey('date')) {
              try {
                sessionDate = DateTime.parse(matchDay['date']);
              } catch (e) {
                continue;
              }
            } else {
              continue;
            }
          }
        } else {
          continue;
        }

        for (var coachId in assignedCoaches) {
          if (coachId == null) continue;

          // ✅ Vérifier si la session est aujourd'hui
          if (sessionDate.isAtSameMomentAs(selectedDate)) {
            dailySessions[coachId] = (dailySessions[coachId] ?? 0) + 1;
          }

          // ✅ Vérifier si la session est cette semaine (entre lundi et dimanche)
          if (sessionDate.isAfter(startOfWeek) &&
              sessionDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
            weeklySessions[coachId] = (weeklySessions[coachId] ?? 0) + 1;
          }
        }
      }
    }

    // ✅ Mettre à jour les coachs avec les sessions comptées
    setState(() {
      for (var coach in _coaches) {
        String coachId = coach['id'];
        coach['dailySessions'] = dailySessions[coachId] ?? 0;
        coach['weeklySessions'] = weeklySessions[coachId] ?? 0;
      }
    });
  }

  /// ✅ **UI for selecting available coaches with session count**
  Widget _buildCoachSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Coachs disponibles",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _coaches.map((coach) {
            final isSelected = _selectedCoaches.contains(coach['id']);
            final maxPerDay = coach['maxSessionsPerDay'];
            final maxPerWeek = coach['maxSessionsPerWeek'];
            final dailySessions = coach['dailySessions'];
            final weeklySessions = coach['weeklySessions'];
            final remainingDaily = maxPerDay - dailySessions;
            final remainingWeekly = maxPerWeek - weeklySessions;

            return ChoiceChip(
              label: Text(
                  "${coach['name']} 📅$remainingDaily/$maxPerDay 🗓️$remainingWeekly/$maxPerWeek"),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.grey[200],
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedCoaches.add(coach['id']);
                  } else {
                    _selectedCoaches.remove(coach['id']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }


  void _preFillFormFields() {
    if (widget.eventData == null) return;

    setState(() {
      _matchType = widget.eventData!.containsKey('matchType')
          ? widget.eventData!['matchType']
          : null;
      _matchNameController.text = widget.eventData!.containsKey('matchName')
          ? widget.eventData!['matchName'] ?? ''
          : '';
      _descriptionController.text = widget.eventData!.containsKey('description')
          ? widget.eventData!['description'] ?? ''
          : '';
      _locationType = widget.eventData!.containsKey('locationType')
          ? widget.eventData!['locationType']
          : null;
      _addressController.text = widget.eventData!.containsKey('address')
          ? widget.eventData!['address'] ?? ''
          : '';
      _itineraryController.text = widget.eventData!.containsKey('itinerary')
          ? widget.eventData!['itinerary'] ?? ''
          : '';
      _feeController.text = widget.eventData!.containsKey('fee')
          ? widget.eventData!['fee'] ?? ''
          : '';
      _tenueController.text = widget.eventData!.containsKey('tenue')
          ? widget.eventData!['tenue'] ?? ''
          : '';


      _selectedGroups = widget.eventData!.containsKey('selectedGroups') &&
              widget.eventData!['selectedGroups'] is List
          ? List<String>.from(widget.eventData!['selectedGroups'])
          : [];

      _selectedChildren = widget.eventData!.containsKey('selectedChildren') &&
              widget.eventData!['selectedChildren'] is List
          ? List<String>.from(widget.eventData!['selectedChildren'])
          : [];

      _transportMode = widget.eventData!.containsKey('transportMode')
          ? widget.eventData!['transportMode']
          : null;
      _isFree = widget.eventData!.containsKey('fee') &&
          widget.eventData!['fee'] == 'Gratuit';

      // ✅ Récupérer les équipes si "Contre un groupe Ifoot"
      if (_matchType == 'Contre un groupe Ifoot' &&
          _selectedGroups.length >= 2) {
        _group1 = _selectedGroups[0];
        _group2 = _selectedGroups[1];
      }

      // ✅ Récupérer les tenues et initialiser les TextEditingController
      if (_matchType == 'Contre un groupe Ifoot' &&
          widget.eventData!.containsKey('uniforms') &&
          widget.eventData!['uniforms'] is Map<String, dynamic>) {
        Map<String, dynamic> uniforms = widget.eventData!['uniforms'];

        // 🔹 Correction : Assurer la conversion correcte des tenues et initialiser les contrôleurs
        uniforms.forEach((group, tenue) {
          if (!_uniformControllers.containsKey(group)) {
            _uniformControllers[group] = TextEditingController();
          }
          _uniformControllers[group]!.text = tenue.toString();
        });
      }
    });
  }

  Future<void> _fetchGroupsAndChildren() async {
    setState(() {});
  }

  void _updateDateController(DateTime date) {
    _dateController.text = "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _fetchGroups() async {
    try {
      final groupsSnapshot = await _firestore.collection('groups').get();
      setState(() {
        _availableGroups =
            groupsSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _loadingGroups = false;
      });
    } catch (e) {
      debugPrint("Erreur lors de la récupération des groupes : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableForTeam1 =
        _availableGroups.where((group) => group != _group2).toList();
    List<String> availableForTeam2 =
        _availableGroups.where((group) => group != _group1).toList();

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
                    _locationType =
                        null; // Allow user selection for other types
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

            // 🔹 Match Name for "Contre une académie"
            if (_matchType == 'Contre une académie')
              TextField(
                controller: _matchNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'académie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),

            // 🔹 Team Selection for "Contre un groupe Ifoot"
            if (_matchType == 'Contre un groupe Ifoot') ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Équipe 1', Icons.group),
                        _loadingGroups
                            ? const Center(child: CircularProgressIndicator())
                            : _buildDropdown(
                                'Équipe 1', availableForTeam1, _group1,
                                (value) {
                                setState(() {
                                  _group1 = value;
                                  if (_group1 == _group2) {
                                    _group2 = null;
                                  }
                                });
                              }),
                        if (_group1 != null) _buildUniformInput(_group1!),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16), // Space between sections
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Équipe 2', Icons.group),
                        _loadingGroups
                            ? const Center(child: CircularProgressIndicator())
                            : _buildDropdown(
                                'Équipe 2', availableForTeam2, _group2,
                                (value) {
                                setState(() {
                                  _group2 = value;
                                  if (_group2 == _group1) {
                                    _group1 = null;
                                  }
                                });
                              }),
                        if (_group2 != null) _buildUniformInput(_group2!),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // 🔹 Match Date Selection (Single Date Picker)
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Date du match', Icons.date_range),
                      TextFormField(
                        readOnly: true,
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Sélectionner une date',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today,
                              color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.event, color: Colors.green),
                            onPressed: _pickDate,
                          ),
                        ),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 🔹 Match Time Selection (Start & End Time in a Row)
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Début du match', Icons.access_time),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _startTime != null
                              ? _formatTime24(_startTime!)
                              : '',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Sélectionner une heure',
                          border: const OutlineInputBorder(),
                          prefixIcon:
                              const Icon(Icons.schedule, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time,
                                color: Colors.green),
                            onPressed: _pickStartTime,
                          ),
                        ),
                        onTap: _pickStartTime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16), // Space between fields
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Fin du match', Icons.access_time),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text:
                              _endTime != null ? _formatTime24(_endTime!) : '',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Sélectionner une heure',
                          border: const OutlineInputBorder(),
                          prefixIcon:
                              const Icon(Icons.schedule, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time,
                                color: Colors.red),
                            onPressed: _pickEndTime,
                          ),
                        ),
                        onTap: _pickEndTime,
                      ),
                    ],
                  ),
                ),
              ],
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
            _buildSectionTitle('Selection des coaches ', Icons.person),

            _buildCoachSelection(),
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
        _endTime = null; // Reset end time when start time is changed
      });
    }
  }

  Future<void> _pickEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner l\'heure de début!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(), // Default to start time
    );

    if (pickedTime != null) {
      int startMinutes = (_startTime!.hour * 60) + _startTime!.minute;
      int endMinutes = (pickedTime.hour * 60) + pickedTime.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'heure de fin doit être après l\'heure de début!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  String _formatTime24(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _matchDates.isNotEmpty ? _matchDates.first : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _matchDates = [pickedDate]; // ✅ Stocke uniquement UNE date
        _updateDateController(pickedDate); // ✅ Met à jour le champ de texte
      });
    }
  }

  Widget _buildUniformInput(String group) {
    // Si le contrôleur n'existe pas encore, on l'initialise
    if (!_uniformControllers.containsKey(group)) {
      _uniformControllers[group] = TextEditingController();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checkroom, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                "Tenue pour $group",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _uniformControllers[group],
            decoration: const InputDecoration(
              labelText: 'Choisissez la tenue',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _groupUniforms[group] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveMatch() async {
    // ✅ Mise à jour des uniformes avant d'envoyer à Firebase
    _groupUniforms = _uniformControllers.map((group, controller) {
      return MapEntry(group, controller.text.trim());
    });

    if (_matchType == 'Contre un groupe Ifoot') {
      _selectedGroups = [];
      if (_group1 != null) _selectedGroups.add(_group1!);
      if (_group2 != null) _selectedGroups.add(_group2!);

      // 🔹 Vérification que les tenues sont bien saisies
      if (_groupUniforms[_group1] == null ||
          _groupUniforms[_group1]!.isEmpty ||
          _groupUniforms[_group2] == null ||
          _groupUniforms[_group2]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez saisir la tenue pour chaque équipe.')),
        );
        return;
      }
    }

    final matchData = {
      'matchType': _matchType,
      'description': _descriptionController.text.trim(),
      'locationType': _locationType,
      'fee': _isFree ? '0' : _feeController.text.trim(),
      'dates': _matchDates.map((date) => Timestamp.fromDate(date)).toList(),
      'selectedGroups': _selectedGroups,
      'selectedChildren':
          _matchType == 'Contre une académie' ? _selectedChildren : [],
      'transportMode': _locationType == 'Ifoot' ? null : _transportMode,
      'startTime': _startTime?.format(context),
      'endTime': _endTime?.format(context),
      'coaches': _selectedCoaches,
      'tenue': _tenueController.text.trim(),
      'uniforms': _groupUniforms, // ✅ Sauvegarde correcte des uniformes
    };

    if (_matchType == 'Contre une académie') {
      matchData['matchName'] = _matchNameController.text.trim();
    }

    if (_matchType == 'Contre un groupe Ifoot') {
      matchData['uniforms'] = {
        _group1!: _groupUniforms[_group1] ?? '',
        _group2!: _groupUniforms[_group2] ?? '',
      };
    }

    if (_locationType == 'Extérieur') {
      matchData['address'] = _addressController.text.trim();
      matchData['itinerary'] = _itineraryController.text.trim();
    }

    try {
      // ✅ Vérification de l'ID de l'événement
      final String? eventId = widget.eventData?['id'];

      if (eventId != null && eventId.isNotEmpty) {
        // ✅ Mettre à jour l'événement existant
        await _firestore
            .collection('friendlyMatches')
            .doc(eventId)
            .update(matchData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match mis à jour avec succès!')),
        );
      } else {
        // ✅ Créer un nouvel événement si l'ID n'existe pas
        DocumentReference newEvent =
            await _firestore.collection('friendlyMatches').add(matchData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match enregistré avec succès!')),
        );

        // 🔹 Ajouter l'ID généré au document pour éviter ce bug à l'avenir
        await newEvent.update({'id': newEvent.id});
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    }
  }
}
