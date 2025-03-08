// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:intl/intl.dart';

import '../../Coach/coach_service.dart';

class FriendlyMatchForm extends StatefulWidget {
  final List<String> groups;
  final Map<String, dynamic>? eventData;

  const FriendlyMatchForm({Key? key, required this.groups, this.eventData})
      : super(key: key);

  @override
  _FriendlyMatchFormState createState() => _FriendlyMatchFormState();
}

class _FriendlyMatchFormState extends State<FriendlyMatchForm> {
  // Contrôleurs de formulaire
  final _matchNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _dateController = TextEditingController();
  final _addressController = TextEditingController();
  final _tenueController = TextEditingController();
  final _feeController = TextEditingController();
  final Map<String, TextEditingController> _uniformControllers = {};
  String? _selectedTransportMode;
  final _departureTimeController = TextEditingController();

  // Services et connexion Firestore
  final _firestore = FirebaseFirestore.instance;
  final _coachService = CoachService();

  // Types de match disponibles
  final List<String> _matchTypes = [
    'Contre une académie',
    'Contre un groupe Ifoot'
  ];

  // Variables pour les académies
  final Map<String, String> _selectedGroupsWithUniforms = {}; // Groupe -> Tenue
  List<String> _selectedGroupsForAcademy = [];
  final Map<String, List<String>> _selectedPlayersByGroup = {};

  // Variables communes
  String? _matchType;
  List<String> _selectedGroups = [];
  List<DateTime> _matchDates = [];
  String? _locationType;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFree = false;

  // Variables pour les groupes
  bool _loadingGroups = true;
  List<String> _availableGroups = [];
  String? _group1;
  String? _group2;
  Map<String, String> _groupUniforms = {};

  // Variables pour les joueurs et coachs
  List<String> _availablePlayers = [];
  bool _loadingPlayers = false;
  List<Map<String, dynamic>> _coaches = [];
  List<String> _selectedCoaches = [];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
    _loadCoaches();
    _preFillFormFields();
  }

  /// Charge les coachs disponibles pour la date sélectionnée
  Future<void> _loadCoaches() async {
    if (_dateController.text.isNotEmpty) {
      DateTime selectedDate =
          DateFormat('dd/MM/yyyy').parse(_dateController.text);
      final coaches =
          await _coachService.getCoachesWithSessionCounts(selectedDate);
      setState(() {
        _coaches = coaches;
      });
    } else {
      // Si aucune date n'est sélectionnée, chargez tous les coachs sans compter les sessions
      final coaches = await _coachService.fetchAllCoaches();
      setState(() {
        _coaches = coaches;
      });
    }
  }

  /// Optimisation de la fonction pour charger les joueurs depuis un groupe
  Future<void> _fetchPlayersForGroup(String groupName) async {
    setState(() {
      _loadingPlayers = true;
      _availablePlayers.clear();
    });

    try {
      final groupSnapshot = await _firestore
          .collection('groups')
          .where('name', isEqualTo: groupName)
          .limit(1)
          .get();

      if (groupSnapshot.docs.isEmpty) {
        debugPrint('Groupe non trouvé: $groupName');
        setState(() => _loadingPlayers = false);
        return;
      }

      var groupData = groupSnapshot.docs.first.data();
      List<String> playerIds = [];

      if (groupData.containsKey('players') && groupData['players'] is List) {
        List<dynamic> playersData = groupData['players'];
        if (playersData.isNotEmpty && playersData.first is Map) {
          playerIds =
              playersData.map((player) => player['id'].toString()).toList();
        } else {
          playerIds = playersData.map((player) => player.toString()).toList();
        }
      }

      List<String> playerNames = [];
      for (String playerId in playerIds) {
        try {
          DocumentSnapshot childDoc =
              await _firestore.collection('children').doc(playerId).get();
          if (childDoc.exists) {
            var childData = childDoc.data() as Map<String, dynamic>;
            if (childData.containsKey('name')) {
              playerNames.add(childData['name'] as String);
            }
          }
        } catch (e) {
          debugPrint('Erreur lors de la récupération du joueur $playerId: $e');
        }
      }

      setState(() {
        _availablePlayers = playerNames;
        _loadingPlayers = false;
      });
    } catch (e) {
      debugPrint('Erreur lors de la récupération des joueurs: $e');
      setState(() => _loadingPlayers = false);
    }
  }

  /// Optimisation de la fonction de pré-remplissage des données
  Future<void> _preFillFormFields() async {
    if (widget.eventData == null) return;

    final data = widget.eventData!;
    setState(() {
      _matchType = data['matchType'];
      _matchNameController.text = data['matchName'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _locationType = data['locationType'];
      _addressController.text = data['address'] ?? '';
      _itineraryController.text = data['itinerary'] ?? '';
      _isFree = data['fee'] == 'Gratuit';
      _feeController.text = _isFree ? '' : (data['fee'] ?? '');
      _tenueController.text = data['tenue'] ?? '';

      if (data.containsKey('dates') && data['dates'] is List) {
        _matchDates = (data['dates'] as List)
            .map((date) => (date as Timestamp).toDate())
            .toList();
        _dateController.text = _matchDates.isNotEmpty
            ? _matchDates
                .map((date) => DateFormat('dd/MM/yyyy').format(date))
                .join(', ')
            : '';
      }

      if (data.containsKey('startTime')) {
        _startTime = TimeOfDay.fromDateTime(
            DateFormat('HH:mm').parse(data['startTime']));
      }

      if (data.containsKey('endTime')) {
        _endTime =
            TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(data['endTime']));
      }

      if (data.containsKey('selectedGroups') &&
          data['selectedGroups'] is List) {
        _selectedGroups = List<String>.from(data['selectedGroups']);
      }

      if (data.containsKey('coaches') && data['coaches'] is List) {
        _selectedCoaches.clear();
        _selectedCoaches.addAll(List<String>.from(data['coaches']));
      }

      if (_matchType == 'Contre une académie') {
        _selectedGroupsForAcademy = List<String>.from(_selectedGroups);

        if (data.containsKey('uniforms') && data['uniforms'] is Map) {
          final uniforms = data['uniforms'] as Map<String, dynamic>;
          uniforms.forEach((group, tenue) {
            _selectedGroupsWithUniforms[group] = tenue.toString();
          });
        }

        if (data.containsKey('playersByGroup') &&
            data['playersByGroup'] is Map) {
          final playersByGroup = data['playersByGroup'] as Map<String, dynamic>;
          playersByGroup.forEach((group, players) {
            if (players is List) {
              _selectedPlayersByGroup[group] = List<String>.from(players);
            }
          });
        }
      } else if (_matchType == 'Contre un groupe Ifoot' &&
          _selectedGroups.length >= 2) {
        _group1 = _selectedGroups[0];
        _group2 = _selectedGroups[1];

        if (data.containsKey('uniforms') && data['uniforms'] is Map) {
          Map<String, dynamic> uniforms = data['uniforms'];
          _groupUniforms = {};

          uniforms.forEach((group, tenue) {
            if (!_uniformControllers.containsKey(group)) {
              _uniformControllers[group] = TextEditingController();
            }
            _uniformControllers[group]!.text = tenue.toString();
            _groupUniforms[group] = tenue.toString();
          });
        }
      }
    });

    // Mode de transport
    List<String> transportModes = ['Covoiturage', 'Bus', 'Individuel'];
    _selectedTransportMode = transportModes.contains(data['transportMode'])
        ? data['transportMode']
        : transportModes.first;

    if (_matchType == 'Contre une académie') {
      for (String group in _selectedGroupsForAcademy) {
        if (!_selectedPlayersByGroup.containsKey(group) ||
            _selectedPlayersByGroup[group]!.isEmpty) {
          await _fetchPlayersForGroup(group);
          setState(() {
            _selectedPlayersByGroup[group] = List.from(_availablePlayers);
          });
        }
      }
    }
  }

  /// Met à jour le champ de texte avec la date formatée
  void _updateDateController(DateTime date) {
    _dateController.text = "${date.day}/${date.month}/${date.year}";
  }

  /// Récupère les groupes disponibles depuis Firestore
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
      title: widget.eventData != null
          ? 'Modifier un match amical'
          : 'Ajouter un match amical',
      footerIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle('Type de match', Icons.sports_soccer),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _matchType,
              items: _matchTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _matchType = value;
                  if (_matchType == 'Contre un groupe Ifoot') {
                    _locationType = 'Ifoot';
                  } else {
                    _locationType = "Extérieur";
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Équipe 1', Icons.group),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 8),
                        if (_group1 != null) _buildUniformInput(_group1!),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Équipe 2', Icons.group),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 8),
                        if (_group2 != null) _buildUniformInput(_group2!),
                      ],
                    ),
                  ),
                ],
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
                      const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Début du match', Icons.access_time),
                      const SizedBox(height: 16),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Fin du match', Icons.access_time),
                      const SizedBox(height: 16),
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
            // Dans la méthode build, après la section des heures de début et fin, ajoutez ceci:
            const SizedBox(height: 16),
            _buildSectionTitle('Lieu du match', Icons.place),
            const SizedBox(height: 8),
            if (_matchType == 'Contre une académie') ...[
              DropdownButtonFormField<String>(
                value: _locationType,
                items: ['Ifoot', 'Extérieur'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _locationType = value),
                decoration: const InputDecoration(
                  labelText: 'Type de lieu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place, color: Colors.blue),
                ),
              ),
            ] else ...[
              // Pour les matchs entre groupes Ifoot, le lieu est toujours Ifoot
              const Card(
                elevation: 0,
                color: Color(0xFFE3F2FD),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le match entre groupes Ifoot se déroule toujours au sein de l\'académie.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

// Si Extérieur est sélectionné, montrez les champs d'adresse et d'itinéraire
            if (_matchType == 'Contre une académie' &&
                _locationType == 'Extérieur') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse du lieu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _itineraryController,
                decoration: const InputDecoration(
                  labelText: 'Itinéraire',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Transport', Icons.directions_bus),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTransportMode,
                items: ['Covoiturage', 'Bus', 'Individuel'].map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedTransportMode = value),
                decoration: const InputDecoration(
                  labelText: "Mode de transport",
                  border: OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.directions_bus, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedTransportMode == 'Bus') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Heure de départ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            controller: _departureTimeController,
                            decoration: InputDecoration(
                              labelText: 'Sélectionner une heure',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.schedule,
                                  color: Colors.blue),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.access_time,
                                    color: Colors.green),
                                onPressed: () =>
                                    _pickTime(_departureTimeController),
                              ),
                            ),
                            onTap: () => _pickTime(_departureTimeController),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Frais de transport',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _feeController,
                                  enabled: !_isFree,
                                  decoration: const InputDecoration(
                                    labelText: 'Tarif (TND)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.money),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
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
                              const Text('Gratuit'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 16),
            _buildSectionTitle('Description', Icons.description),
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
            _buildSectionTitle('Frais de participation', Icons.money),
            const SizedBox(height: 16),
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
            if (_matchType == 'Contre une académie') ...[
              _buildAcademyGroupSelection(),
            ],
            const SizedBox(height: 16),
            _buildSectionTitle('Sélection des coachs', Icons.sports),
            const SizedBox(height: 16),
            _coaches.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        "Veuillez d'abord sélectionner une date pour voir les coachs disponibles"),
                  ))
                : _coachService.buildCoachSelectionWidget(
                    _coaches, _selectedCoaches, (updatedSelection) {
                    setState(() {
                      _selectedCoaches = updatedSelection;
                    });
                  }),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saveMatch,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Enregistrer',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 222, 107, 6),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sélectionne une heure
  Future<void> _pickTime(TextEditingController controller) async {
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
        controller.text =
            "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _showPlayerSelectionDialog(String group) async {
    List<String> selectedPlayers = _selectedPlayersByGroup[group] ?? [];

    await _fetchPlayersForGroup(group);

    // ✅ Utiliser la liste mise à jour par _fetchPlayersForGroup
    selectedPlayers = _selectedPlayersByGroup[group] ?? [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Sélectionner les joueurs pour $group'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: _loadingPlayers
                    ? const Center(child: CircularProgressIndicator())
                    : _availablePlayers.isEmpty
                        ? const Center(
                            child:
                                Text('Aucun joueur disponible dans ce groupe'))
                        : Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${_availablePlayers.length} joueurs disponibles',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    // ✅ Boutons pour tout sélectionner/désélectionner
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            setStateDialog(() {
                                              selectedPlayers = [];
                                            });
                                          },
                                          child: const Text("Aucun"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setStateDialog(() {
                                              selectedPlayers =
                                                  List<String>.from(
                                                      _availablePlayers);
                                            });
                                          },
                                          child: const Text("Tous"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _availablePlayers.length,
                                  itemBuilder: (context, index) {
                                    final player = _availablePlayers[index];
                                    return CheckboxListTile(
                                      title: Text(player),
                                      value: selectedPlayers.contains(player),
                                      onChanged: (value) {
                                        setStateDialog(() {
                                          if (value == true) {
                                            selectedPlayers.add(player);
                                          } else {
                                            selectedPlayers.remove(player);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPlayersByGroup[group] = selectedPlayers;
                      // ✅ Mettre à jour la liste globale
                      _updateSelectedChildrenList();
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Valider (${selectedPlayers.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// 6. Ajoutez cette méthode pour mettre à jour la liste complète des joueurs sélectionnés
  void _updateSelectedChildrenList() {
    _selectedGroups.clear();
    _selectedPlayersByGroup.forEach((_, players) {
      _selectedGroups.addAll(players);
    });
  }

  /// Construction de l'interface de sélection des groupes pour une académie
  Widget _buildAcademyGroupSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _buildSectionTitle('Groupes participant', Icons.group),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add,
                  color: Color.fromARGB(255, 255, 255, 255), size: 20),
              label: const Text(
                'Ajouter',
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _showGroupSelectionDialog();
              },
            ),
          ],
        ),
        if (_selectedGroupsForAcademy.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
                "Aucun groupe sélectionné. Ajoutez des groupes pour participer au match."),
          ),
        ..._selectedGroupsForAcademy.map((group) {
          final playersCount = _selectedPlayersByGroup[group]?.length ?? 0;

          if (!_uniformControllers.containsKey(group)) {
            _uniformControllers[group] = TextEditingController(
                text: _selectedGroupsWithUniforms[group] ?? '');
          } else {
            _uniformControllers[group]!.text =
                _selectedGroupsWithUniforms[group] ?? '';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            color: Colors.deepPurple.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.deepPurple.shade200, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Groupe: $group",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      Row(
                        children: [
                          Badge(
                            backgroundColor: Colors.deepPurple,
                            label: Text('$playersCount',
                                style: const TextStyle(color: Colors.white)),
                            child: IconButton(
                              icon: const Icon(Icons.people,
                                  color: Colors.deepPurple),
                              tooltip: 'Sélectionner des joueurs',
                              onPressed: () {
                                _showPlayerSelectionDialog(group);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Supprimer le groupe',
                            onPressed: () {
                              setState(() {
                                _selectedGroupsForAcademy.remove(group);
                                _selectedGroupsWithUniforms.remove(group);
                                _selectedPlayersByGroup.remove(group);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _uniformControllers[group],
                    decoration: const InputDecoration(
                      labelText: 'Tenue pour ce groupe',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.checkroom, color: Colors.deepPurple),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedGroupsWithUniforms[group] = value;
                      });
                    },
                  ),
                  if (_selectedPlayersByGroup.containsKey(group) &&
                      _selectedPlayersByGroup[group]!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text("Joueurs sélectionnés:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _selectedPlayersByGroup[group]!.map((player) {
                        return Chip(
                          backgroundColor: Colors.deepPurple.shade100,
                          avatar: const CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.person,
                                size: 14, color: Colors.white),
                          ),
                          label: Text(player),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() {
                              _selectedPlayersByGroup[group]!.remove(player);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ]
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Dialogue pour la sélection d'un nouveau groupe
  Future<void> _showGroupSelectionDialog() async {
    String? selectedGroup;
    List<String> availableGroupsToSelect = _availableGroups
        .where((group) => !_selectedGroupsForAcademy.contains(group))
        .toList();

    if (availableGroupsToSelect.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tous les groupes ont déjà été ajoutés!')));
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sélectionner un groupe'),
              content: DropdownButton<String>(
                value: selectedGroup,
                hint: const Text('Choisissez un groupe'),
                isExpanded: true,
                items: availableGroupsToSelect.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedGroup = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedGroup != null) {
                      setState(() {
                        _selectedGroupsForAcademy.add(selectedGroup!);
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Construit un titre de section avec une icône
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ],
    );
  }

  /// Construit un champ de texte déroulant pour la sélection de groupe
  Widget _buildDropdown(String title, List<String> items, String? value,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.group),
      ),
    );
  }

  /// Construit un champ de texte pour la saisie de la tenue
  Widget _buildUniformInput(String group) {
    return TextField(
      controller: _uniformControllers[group],
      decoration: const InputDecoration(
        labelText: 'Tenue pour ce groupe',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.checkroom),
      ),
    );
  }

  /// Ouvre un dialogue pour la sélection de la date du match
  Future<void> _pickDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      // Si une ancienne date existe, mettez à jour les sessions
      if (_matchDates.isNotEmpty) {
        await _coachService.updateCoachSessionsForDateChange(
          coachIds: _selectedCoaches,
          oldDate: _matchDates.first, // Supposons qu'il n'y a qu'une seule date
          newDate: selectedDate,
        );
      }

      // Mettre à jour la date dans le formulaire
      _updateDateController(selectedDate);
      await _loadCoaches();
    }
  }

  /// Ouvre un dialogue pour la sélection de l'heure de début du match
  Future<void> _pickStartTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        _startTime = selectedTime;
      });
    }
  }

  /// Ouvre un dialogue pour la sélection de l'heure de fin du match
  Future<void> _pickEndTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      if (_startTime != null &&
          _timeOfDayToDateTime(selectedTime)
              .isBefore(_timeOfDayToDateTime(_startTime!))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('L\'heure de fin doit être après l\'heure de début')));
        return;
      }

      if (selectedTime.hour == 0 && selectedTime.minute == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('L\'heure de fin ne peut pas être minuit')));
        return;
      }

      setState(() {
        _endTime = selectedTime;
      });
    }
  }

  /// Convertit TimeOfDay en DateTime pour comparaison
  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  /// Enregistre les données du formulaire dans Firestore
  Future<void> _saveMatch() async {
    // Validation de base
    if (_matchType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez sélectionner un type de match')));
      return;
    }

    // Vérification du type de match
    if (_matchType == 'Contre une académie' &&
        _matchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez saisir le nom de l\'académie')));
      return;
    } else if (_matchType == 'Contre un groupe Ifoot') {
      if (_group1 == null || _group2 == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez sélectionner deux groupes')));
        return;
      }
    }

    // Vérification de la date
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une date')));
      return;
    }
    // ✅ Convertir le texte de date en objet DateTime AVANT la validation du coach
    try {
      _matchDates = [DateFormat('dd/MM/yyyy').parse(_dateController.text)];
      debugPrint('Date parsée: ${_matchDates.first.toString()}');
    } catch (e) {
      debugPrint('Erreur lors du parsing de la date: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Format de date invalide: ${_dateController.text}')));
      return;
    }

    // Vérification des heures
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez sélectionner les horaires du match')));
      return;
    }

    // Vérification des coachs surchargés
    bool canProceed = await _coachService.validateCoachSelection(
        _selectedCoaches, _matchDates.first, context);

    if (!canProceed) {
      return; // L'utilisateur a annulé ou attend sa confirmation
    }

    // Vérification des coachs
    if (_selectedCoaches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez sélectionner au moins un coach')));
      return;
    }

    // ✅ Convertir le texte de date en objet DateTime (pour matchDates)
    try {
      // Important: S'assurer que _matchDates est initialisé
      _matchDates = [DateFormat('dd/MM/yyyy').parse(_dateController.text)];
      debugPrint('Date parsée: ${_matchDates.first.toString()}');
    } catch (e) {
      debugPrint('Erreur lors du parsing de la date: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Format de date invalide: ${_dateController.text}')));
      return;
    }

    // ✅ Préparation des données
    Map<String, dynamic> eventData = {
      'matchType': _matchType,
      'description': _descriptionController.text,
      'fee': _isFree ? 'Gratuit' : _feeController.text,
      'dates': _matchDates.map((date) => Timestamp.fromDate(date)).toList(),
      'startTime': _formatTime24(_startTime!),
      'endTime': _formatTime24(_endTime!),
      'coaches': _selectedCoaches,
    };

    // ✅ Données spécifiques selon le type de match
    if (_matchType == 'Contre une académie') {
      // Vérification des groupes
      if (_selectedGroupsForAcademy.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez sélectionner au moins un groupe')));
        return;
      }

      eventData['matchName'] = _matchNameController.text;
      eventData['selectedGroups'] = _selectedGroupsForAcademy;
      eventData['uniforms'] = _selectedGroupsWithUniforms;
      eventData['playersByGroup'] = _selectedPlayersByGroup;

      // Créer une liste de tous les joueurs sélectionnés
      List<String> allPlayers = [];
      _selectedPlayersByGroup.forEach((_, players) {
        allPlayers.addAll(players);
      });
      eventData['selectedPlayers'] = allPlayers;
    } else if (_matchType == 'Contre un groupe Ifoot') {
      eventData['selectedGroups'] = [_group1!, _group2!];

      // Créer la structure des uniformes
      Map<String, String> uniforms = {};
      _uniformControllers.forEach((group, controller) {
        uniforms[group] = controller.text;
      });
      eventData['uniforms'] = uniforms;
      eventData['locationType'] = 'Ifoot'; // Par défaut pour ce type de match
    }

    // ✅ Informations de location si extérieur
    if (_locationType == 'Extérieur') {
      eventData['address'] = _addressController.text;
      eventData['itinerary'] = _itineraryController.text;
    }

    try {
      // ✅ Enregistrement dans Firestore
      if (widget.eventData != null && widget.eventData!.containsKey('id')) {
        String docId = widget.eventData!['id'];
        await _firestore
            .collection('friendlyMatches')
            .doc(docId)
            .update(eventData);
        debugPrint('Match mis à jour avec ID: $docId');
      } else {
        // Création d'un nouveau document
        DocumentReference docRef =
            await _firestore.collection('friendlyMatches').add(eventData);
        // Ajouter l'ID du document au document lui-même
        await docRef.update({'id': docRef.id});
      }

      // Confirmation et retour
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Match enregistré avec succès!'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du match: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'enregistrement: $e'),
          backgroundColor: Colors.red));
    }
  }

  /// Formate l'heure au format 24 heures
  String _formatTime24(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
