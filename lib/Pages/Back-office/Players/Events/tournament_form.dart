// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Coach/coach_service.dart';

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
    final _coachService = CoachService(); // Utilisation du service de coach

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _documentsController = TextEditingController();
  final _feeController = TextEditingController();
    // Variables pour les joueurs et coachs
  List<String> _availablePlayers = [];
  bool _loadingPlayers = false;
  List<String> _availableGroups = [];
 bool _loadingGroups = false ;
  String? _selectedTransportMode;
    final _departureTimeController = TextEditingController();


    final Map<String, List<String>> _selectedPlayersByGroup = {};
  final Map<String, String> _selectedGroupsWithUniforms = {};
  final Map<String, TextEditingController> _uniformControllers = {};


  String? _locationType;
  bool _isFree = false;
  List<String> _selectedGroups = [];
  List<String> _selectedChildren = [];
  final _dateController = TextEditingController();
  String? _transportMode;
  DateTime? _date;
   List<String> _selectedCoaches = []; // ✅ Liste des coachs assignés
  List<Map<String, dynamic>> _coaches = []; // ✅ Correct
  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCoachesData();
    _fetchGroups();
    if (widget.tournament != null) {
      _loadTournamentData(widget.tournament!);
    }
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

 Future<void> _loadCoachesData() async {
    try {
      if (_dateController.text.isNotEmpty) {
        DateTime selectedDate =
            DateFormat('dd/MM/yyyy').parse(_dateController.text);

        // Utiliser le service coach pour obtenir les coachs avec leur comptage de sessions
        final coachesWithSessions =
            await _coachService.getCoachesWithSessionCounts(selectedDate);

        setState(() {
          _coaches = coachesWithSessions;
        });
      } else {
        // Si pas de date, charger tous les coachs sans compter les sessions
        final allCoaches = await _coachService.fetchAllCoaches();
        setState(() {
          _coaches = allCoaches;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des coachs: $e");
    }
  }


  void _loadTournamentData(DocumentSnapshot<Object?> tournament) {
    final data = tournament.data() as Map<String, dynamic>;

    _nameController.text = data['name'] ?? '';
    _dateController.text =
        data['dates'] is List ? data['dates'].join(', ') : data['dates'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _locationType = data['locationType'];
    _addressController.text = data['address'] ?? '';
    _itineraryController.text = data['itinerary'] ?? '';
    _feeController.text = data['fee'] ?? '';
    _isFree = data['fee'] == 'Gratuit';
    _documentsController.text = data['documents'] ?? '';
    List<String> transportModes = ['Covoiturage', 'Bus', 'Individuel'];
    _selectedTransportMode =
        transportModes.contains(data['transportMode'])
            ? data['transportMode']
            : transportModes.first;

    // ✅ Vérifier `selectedGroups` et `selectedChildren`
    _selectedGroups = (data['selectedGroups'] is List)
        ? List<String>.from(data['selectedGroups'])
        : [];

    _selectedChildren = (data['selectedChildren'] is List)
        ? List<String>.from(data['selectedChildren'])
        : [];
    
// Chargement des joueurs par groupe
  _selectedPlayersByGroup.clear();
  if (data['playersByGroup'] is Map) {
    Map<String, dynamic> playersByGroup = data['playersByGroup'] as Map<String, dynamic>;
    playersByGroup.forEach((groupName, players) {
      if (players is List) {
        _selectedPlayersByGroup[groupName] = List<String>.from(players);
      }
    });
  }

  _uniformControllers.clear();
  if (data['uniforms'] is Map) {
    Map<String, dynamic> uniforms = data['uniforms'] as Map<String, dynamic>;
    uniforms.forEach((groupName, uniform) {
      if (uniform is String) {
        _selectedGroupsWithUniforms[groupName] = uniform;
        _uniformControllers[groupName] = TextEditingController(text: uniform);
      }
    });
  }

 // ✅ Charger les coachs sélectionnés
  _selectedCoaches.clear();
  if (data['coaches'] is List) {
    _selectedCoaches.addAll(List<String>.from(data['coaches']));
  }

    setState(() {});

    // ✅ Rechargement des données des coachs avec leurs sessions
  if (_dateController.text.isNotEmpty) {
    _loadCoachesData(); 
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


  /// Sélectionne une date
  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _updateDateController(pickedDate);
      });

      // Recharger les données des coachs après changement de date
      await _loadCoachesData();
    }
  }

  /// Met à jour le contrôleur de date
  void _updateDateController(DateTime date) {
    _dateController.text = DateFormat('dd/MM/yyyy').format(date);
    _date = date;
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
          // Section Informations Générales
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informations Générales', Icons.info),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du tournoi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.sports_soccer, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section Date du Tournoi
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Date du Tournoi', Icons.date_range),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Sélectionner une date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
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
          ),
          const SizedBox(height: 16),

          // Section Lieu et Itinéraire
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Lieu et Itinéraire', Icons.place),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _locationType,
                    items: _locationTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _locationType = value),
                    decoration: InputDecoration(
                      labelText: 'Type de lieu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.place, color: Colors.blue),
                    ),
                  ),
                  if (_locationType == 'Extérieur') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Adresse',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itineraryController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Itinéraire',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _selectItinerary,
                          child: const Text('Choisir sur la carte'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section Informations Financières
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informations Financières', Icons.monetization_on),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _feeController,
                          enabled: !_isFree,
                          decoration: InputDecoration(
                            labelText: 'Tarif (en TND)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.money, color: Colors.blue),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section Tenue et Documents
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Documents', Icons.description),
                  const SizedBox(height: 16),
                                    TextField(
                    controller: _documentsController,
                    decoration: InputDecoration(
                      labelText: 'Documents requis',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.folder, color: Colors.blue),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section Description
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Description', Icons.description),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.description, color: Colors.blue),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section Groupes Participants
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                   _buildGroupSelection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section Affectation des Coaches
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Affectation des Coaches', Icons.sports),
                  const SizedBox(height: 16),
                  _coaches.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                                "Veuillez d'abord sélectionner une date pour voir les coachs disponibles"),
                          ),
                        )
                      : _coachService.buildCoachSelectionWidget(
                          _coaches, _selectedCoaches, (updatedSelection) {
                          setState(() {
                            _selectedCoaches = updatedSelection;
                          });
                        }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Bouton Enregistrer
          Center(
            child: ElevatedButton.icon(
              onPressed: _saveTournament,
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                widget.tournament == null ? 'Enregistrer' : 'Mettre à jour',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
      
      // ✅ Tous les joueurs sont sélectionnés par défaut
      if (!_selectedPlayersByGroup.containsKey(groupName) || _selectedPlayersByGroup[groupName]!.isEmpty) {
        _selectedPlayersByGroup[groupName] = List<String>.from(playerNames);
        _updateSelectedChildrenList();
      }
    });
  } catch (e) {
    debugPrint('Erreur lors de la récupération des joueurs: $e');
    setState(() => _loadingPlayers = false);
  }
}

// 6. Ajoutez cette méthode pour mettre à jour la liste complète des joueurs sélectionnés
void _updateSelectedChildrenList() {
  _selectedChildren.clear();
  _selectedPlayersByGroup.forEach((_, players) {
    _selectedChildren.addAll(players);
  });
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_availablePlayers.length} joueurs disponibles',
                                    style: const TextStyle(fontWeight: FontWeight.bold)
                                  ),
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
                                            selectedPlayers = List<String>.from(_availablePlayers);
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



  /// Construction de l'interface de sélection des groupes pour une académie
  Widget _buildGroupSelection() {
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
        if (_selectedGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
                "Aucun groupe sélectionné. Ajoutez des groupes pour participer au match."),
          ),
        ..._selectedGroups.map((group) {
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
                                _selectedGroups.remove(group);
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
        .where((group) => !_selectedGroups.contains(group))
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
                        _selectedGroups.add(selectedGroup!);
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

  Future<void> _saveTournament() async {

      _updateSelectedChildrenList();

 // ✅ Validation complète
  if (_nameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez saisir le nom du tournoi')),
    );
    return;
  }
  
  if (_dateController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez sélectionner une date')),
    );
    return;
  }
  
  if (_locationType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez sélectionner un type de lieu')),
    );
    return;
  }
  
  if (_selectedGroups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez sélectionner au moins un groupe')),
    );
    return;}

 if (_selectedChildren.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun joueur n\'est sélectionné')),
    );
    return;
  }

   // Vérifications supplémentaires pour un lieu extérieur
    if (_locationType == 'Extérieur') {
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez saisir l\'adresse du lieu')));
        return;
      }
    }

   // ✅ Vérifier si des joueurs sont sélectionnés pour au moins un groupe
  bool hasAnyPlayers = false;
  for (var group in _selectedGroups) {
    if (_selectedPlayersByGroup.containsKey(group) && 
        _selectedPlayersByGroup[group]!.isNotEmpty) {
      hasAnyPlayers = true;
      break;
    }
  }

    if (!hasAnyPlayers) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez sélectionner des joueurs pour au moins un groupe')),
    );
    return;
  }

  // Vérification des coachs surchargés si une date et des coachs sont sélectionnés
  if (_selectedCoaches.isNotEmpty && _dateController.text.isNotEmpty) {
    DateTime selectedDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    bool canProceed = await _coachService.validateCoachSelection(
      _selectedCoaches, 
      selectedDate,
      context
    );

    if (!canProceed) {
      return; // L'utilisateur a annulé ou attend sa confirmation
    }
  }

    // ✅ Récupérer les tenues depuis les contrôleurs
  for (var group in _selectedGroups) {
    if (_uniformControllers.containsKey(group)) {
      _selectedGroupsWithUniforms[group] = _uniformControllers[group]!.text;
    }
  }

    

  final tournamentData = {
    'name': _nameController.text.trim(),
    'description': _descriptionController.text.trim(),
    'locationType': _locationType,
    'address': _addressController.text.trim(),
    'itinerary': _itineraryController.text.trim(),
    'fee': _isFree ? 'Gratuit' : _feeController.text.trim(),
    'documents': _documentsController.text.trim(),
    'dates': _dateController.text.split(',').map((date) => date.trim()).toList(),
    'selectedGroups': _selectedGroups,
    'coaches': _selectedCoaches,
    'transportMode': _transportMode,
    'playersByGroup': _selectedPlayersByGroup, // ✅ Ajouter les joueurs par groupe
    'uniforms': _selectedGroupsWithUniforms, // ✅ Ajouter les uniformes

  };

  // Le reste du code d'enregistrement reste inchangé
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
