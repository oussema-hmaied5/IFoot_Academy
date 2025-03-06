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

// Optimisation de la classe _FriendlyMatchFormState

class _FriendlyMatchFormState extends State<FriendlyMatchForm> {
  // Variables existantes, gardées identiques
  final _matchNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _dateController = TextEditingController();
  final _addressController = TextEditingController();
  final _tenueController = TextEditingController();
  final _feeController = TextEditingController();
  final Map<String, TextEditingController> _uniformControllers = {};
  final _firestore = FirebaseFirestore.instance;
  final List<String> _matchTypes = [
    'Contre une académie',
    'Contre un groupe Ifoot'
  ];

  // Variables organisées par fonctionnalité
  // Académie
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

  // Groupes
  bool _loadingGroups = true;
  List<String> _availableGroups = [];
  String? _group1;
  String? _group2;
  Map<String, String> _groupUniforms = {};

  // Coachs et Joueurs
  List<Map<String, dynamic>> _coaches = [];
  final List<String> _selectedCoaches = [];
  List<String> _availablePlayers = [];
  bool _loadingPlayers = false;

  // Variables obsolètes supprimées:
  // _selectedChildren - Redondant avec les données dans _selectedPlayersByGroup
  // _transportMode - Déplacé directement dans matchData lors de la sauvegarde

  @override
  void initState() {
    super.initState();
    // Simplification des appels d'initialisation
    _fetchGroups();
    _fetchCoaches();

    if (widget.eventData != null) {
      _preFillFormFields().then((_) {
        if (_dateController.text.isNotEmpty) {
          DateTime selectedDate =
              DateFormat('dd/MM/yyyy').parse(_dateController.text);
          _fetchCoachSessionCountsForDate(selectedDate);
        }
      });
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
              'maxSessionsPerWeek': doc.data().containsKey('maxSessionsPerWeek')
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
        const Text("Coachs disponibles :",
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

  /// Optimisation de la fonction pour charger les joueurs depuis un groupe
  Future<void> _fetchPlayersForGroup(String groupName) async {
    setState(() {
      _loadingPlayers = true;
      _availablePlayers.clear();
    });

    try {
      // 1. Récupérer le document de groupe par son nom
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

      // 2. Extraire les IDs des joueurs du document de groupe
      var groupData = groupSnapshot.docs.first.data();
      List<String> playerIds = [];

      if (groupData.containsKey('players') && groupData['players'] is List) {
        List<dynamic> playersData = groupData['players'];

        // Si players est une liste d'objets avec des ids
        if (playersData.isNotEmpty && playersData.first is Map) {
          playerIds =
              playersData.map((player) => player['id'].toString()).toList();
        }
        // Si players est directement une liste d'IDs
        else {
          playerIds = playersData.map((player) => player.toString()).toList();
        }
      }

      // 3. Récupérer les noms des joueurs à partir de leurs IDs
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

      debugPrint('Joueurs chargés pour $groupName: ${playerNames.length}');
    } catch (e) {
      debugPrint('Erreur lors de la récupération des joueurs: $e');
      setState(() => _loadingPlayers = false);
    }
  }

  /// Optimisation de la fonction de pré-remplissage des données
  Future<void> _preFillFormFields() async {
    if (widget.eventData == null) return;

    // Extraction des données de base
    final data = widget.eventData!;

    setState(() {
      // Données générales
      _matchType = data['matchType'];
      _matchNameController.text = data['matchName'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _locationType = data['locationType'];
      _addressController.text = data['address'] ?? '';
      _itineraryController.text = data['itinerary'] ?? '';

      // Gestion des tarifs
      _isFree = data['fee'] == 'Gratuit';
      _feeController.text = _isFree ? '' : (data['fee'] ?? '');

      // Gestion des tenues
      _tenueController.text = data['tenue'] ?? '';

      // Gestion des dates
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

      // Gestion des horaires
      if (data.containsKey('startTime')) {
        _startTime = TimeOfDay.fromDateTime(
            DateFormat('HH:mm').parse(data['startTime']));
      }

      if (data.containsKey('endTime')) {
        _endTime =
            TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(data['endTime']));
      }

      // Récupération des groupes
      if (data.containsKey('selectedGroups') &&
          data['selectedGroups'] is List) {
        _selectedGroups = List<String>.from(data['selectedGroups']);
      }

      // Récupération des coachs
      if (data.containsKey('coaches') && data['coaches'] is List) {
        _selectedCoaches.clear();
        _selectedCoaches.addAll(List<String>.from(data['coaches']));
      }

      // Traitement spécifique selon le type de match
      if (_matchType == 'Contre une académie') {
        _selectedGroupsForAcademy = List<String>.from(_selectedGroups);

        // Récupération des tenues par groupe
        if (data.containsKey('uniforms') && data['uniforms'] is Map) {
          final uniforms = data['uniforms'] as Map<String, dynamic>;
          uniforms.forEach((group, tenue) {
            _selectedGroupsWithUniforms[group] = tenue.toString();
          });
        }

        // Récupération des joueurs par groupe
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

        // Récupération des tenues
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

    // Chargement des joueurs pour chaque groupe sélectionné
    if (_matchType == 'Contre une académie') {
      for (String group in _selectedGroupsForAcademy) {
        // Seulement si les joueurs n'ont pas déjà été chargés
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

            if (_matchType == 'Contre une académie') ...[
              _buildAcademyGroupSelection(),
            ],

            const SizedBox(height: 16),
            _buildSectionTitle('Selection des coaches ', Icons.sports),

            _buildCoachSelection(),
            const SizedBox(height: 16),

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

  Future<void> _showPlayerSelectionDialog(String group) async {
    List<String> selectedPlayers = _selectedPlayersByGroup[group] ?? [];

    // Charger les joueurs pour ce groupe
    await _fetchPlayersForGroup(group);

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
                                child: Text(
                                    '${_availablePlayers.length} joueurs disponibles',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
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
                    // Sauvegarder les joueurs sélectionnés pour ce groupe
                    setState(() {
                      _selectedPlayersByGroup[group] = selectedPlayers;
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

  Widget _buildAcademyGroupSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placer le titre et le bouton dans une Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //   Utiliser Flexible pour permettre au titre de se rétrécir si nécessaire
            Flexible(
              child: _buildSectionTitle(
                  'Groupes participant ', Icons.group),
            ),
            const SizedBox(width: 8),

            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Color.fromARGB(255, 230, 10, 10)),
label: const Text('Ajouter', 
              style: TextStyle(color: Color.fromARGB(255, 175, 44, 44)),
              // Réduire la taille du texte si nécessaire
              overflow: TextOverflow.ellipsis,
            ),              style: ElevatedButton.styleFrom(
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

        // Affichage des cartes pour chaque groupe (enlever le bouton dans la carte)
        ..._selectedGroupsForAcademy.map((group) {
          final playersCount = _selectedPlayersByGroup[group]?.length ?? 0;

          // Créer un contrôleur pour la tenue s'il n'existe pas déjà
          if (!_uniformControllers.containsKey(group)) {
            _uniformControllers[group] = TextEditingController(
                text: _selectedGroupsWithUniforms[group] ?? '');
          } else {
            // Mettre à jour le texte du contrôleur existant si nécessaire
            _uniformControllers[group]!.text =
                _selectedGroupsWithUniforms[group] ?? '';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            color: Colors
                .deepPurple.shade50, // Couleur de fond légèrement violette
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
                  // Afficher les joueurs sélectionnés
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
          // Utiliser StatefulBuilder pour gérer l'état interne du dialogue
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sélectionner un groupe'),
              content: DropdownButton<String>(
                value: selectedGroup,
                hint: const Text('Choisissez un groupe'),
                isExpanded: true,
                items: availableGroupsToSelect.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    // Utiliser setDialogState pour mettre à jour l'état du dialogue
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
                  onPressed: () async {
                    if (selectedGroup != null) {
                      // Charger les joueurs pour ce groupe
                      await _fetchPlayersForGroup(selectedGroup!);

                      setState(() {
                        _selectedGroupsForAcademy.add(selectedGroup!);
                        _selectedGroupsWithUniforms[selectedGroup!] =
                            ''; // Initialize uniform
                        _uniformControllers[selectedGroup!] =
                            TextEditingController(); // Créer un contrôleur
                        _selectedPlayersByGroup[selectedGroup!] =
                            List.from(_availablePlayers);
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

      // ✅ Fetch coach session counts for the selected date
      await _fetchCoachSessionCountsForDate(pickedDate);
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

  /// Optimisation de la fonction de sauvegarde
  Future<void> _saveMatch() async {
    // Validation de base
    if (_matchType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez sélectionner un type de match')));
      return;
    }

    if (_matchDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une date')));
      return;
    }

    // Préparation des données de base du match
    Map<String, dynamic> matchData = {
      'matchType': _matchType,
      'description': _descriptionController.text.trim(),
      'locationType': _locationType,
      'fee': _isFree ? 'Gratuit' : _feeController.text.trim(),
      'dates': _matchDates.map((date) => Timestamp.fromDate(date)).toList(),
      'coaches': _selectedCoaches,
    };

    // Ajout des horaires s'ils sont définis
    if (_startTime != null) matchData['startTime'] = _formatTime24(_startTime!);
    if (_endTime != null) matchData['endTime'] = _formatTime24(_endTime!);

    // Traitement spécifique selon le type de match
    if (_matchType == 'Contre une académie') {
      // Validation pour match contre académie
      if (_matchNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez saisir le nom de l\'académie')));
        return;
      }

      if (_selectedGroupsForAcademy.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez sélectionner au moins un groupe')));
        return;
      }

      matchData['matchName'] = _matchNameController.text.trim();
      matchData['selectedGroups'] = _selectedGroupsForAcademy;

      // Vérification et ajout des tenues
      Map<String, String> uniforms = {};
      for (String group in _selectedGroupsForAcademy) {
        String tenue = _selectedGroupsWithUniforms[group] ?? '';
        if (tenue.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Veuillez définir une tenue pour le groupe $group')));
          return;
        }
        uniforms[group] = tenue;
      }
      matchData['uniforms'] = uniforms;

      // Ajout des joueurs par groupe
      matchData['playersByGroup'] = _selectedPlayersByGroup;

      // Création d'une liste plate de tous les joueurs sélectionnés
      List<String> allSelectedPlayers = [];
      _selectedPlayersByGroup.forEach((_, players) {
        allSelectedPlayers.addAll(players);
      });
      matchData['selectedChildren'] = allSelectedPlayers;
    } else if (_matchType == 'Contre un groupe Ifoot') {
      // Validation pour match entre groupes Ifoot
      if (_group1 == null || _group2 == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez sélectionner deux groupes')));
        return;
      }

      // Mise à jour des uniformes depuis les contrôleurs
      Map<String, String> uniforms = {};
      for (String group in [_group1!, _group2!]) {
        String tenue = _uniformControllers[group]?.text.trim() ?? '';
        if (tenue.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Veuillez définir une tenue pour le groupe $group')));
          return;
        }
        uniforms[group] = tenue;
      }

      matchData['selectedGroups'] = [_group1!, _group2!];
      matchData['uniforms'] = uniforms;
    }

    // Informations de localisation si en extérieur
    if (_locationType == 'Extérieur') {
      matchData['address'] = _addressController.text.trim();
      matchData['itinerary'] = _itineraryController.text.trim();
    }

    try {
      final String? eventId = widget.eventData?['id'];

      if (eventId != null && eventId.isNotEmpty) {
        await _firestore
            .collection('friendlyMatches')
            .doc(eventId)
            .update(matchData);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match mis à jour avec succès!')));
      } else {
        DocumentReference newEvent =
            await _firestore.collection('friendlyMatches').add(matchData);

        await newEvent.update({'id': newEvent.id});

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match enregistré avec succès!')));
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')));
    }
  }
}
