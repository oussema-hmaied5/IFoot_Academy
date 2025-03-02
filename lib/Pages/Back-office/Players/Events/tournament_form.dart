// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
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
  final _dateController = TextEditingController();
  String? _transportMode;
  final List<String> _selectedCoaches = []; // ✅ Liste des coachs assignés
  List<Map<String, dynamic>> _coaches = []; // ✅ Correct
  final List<String> _locationTypes = ['Ifoot', 'Extérieur'];
  final List<String> _transportModes = ['Covoiturage', 'Bus', 'Individuel'];
  Map<String, List<String>> _childrenByGroup = {};
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchCoaches();

    _fetchGroupsAndChildren();
    if (widget.tournament != null) {
      _loadTournamentData(widget.tournament!);
    }
 
  }

  Future<void> _fetchCoaches() async {
    try {
      final snapshot = await _firestore.collection('coaches').get();
      final allCoaches = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'],
        'maxSessionsPerDay': doc.data().containsKey('maxSessionsPerDay')
            ? doc.data()['maxSessionsPerDay']
            : 2,
        'maxSessionsPerWeek': doc.data().containsKey('maxSessionsPerWeek')
            ? doc.data()['maxSessionsPerWeek']
            : 10,
      }).toList();

      setState(() {
        _coaches = allCoaches;
      });
  // ✅ Charger les séances en fonction de la date actuelle (ou date sélectionnée)
    if (_dateController.text.isNotEmpty) {
      DateTime selectedDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
      await _fetchCoachSessionCounts(selectedDate);
    }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des coachs: $e')),
      );
    }
  }


Future<void> _fetchCoachSessionCounts(DateTime selectedDate) async {
  // ✅ Déterminer la semaine (du lundi au dimanche)
  DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

  Map<String, int> dailySessions = {};
  Map<String, int> weeklySessions = {};

  // ✅ Liste des collections à vérifier
  List<String> collections = ['trainings', 'championships', 'friendlyMatches', 'tournaments'];

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
      } else if (collection == "championships" && data.containsKey('matchDays')) {
        // ✅ Extraire les dates des matchs dans un championnat
        for (var matchDay in data['matchDays']) {
          if (matchDay is Map<String, dynamic> && matchDay.containsKey('date')) {
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
        if (sessionDate.isAfter(startOfWeek) && sessionDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
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


Widget _buildCoachSelection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Coachs disponibles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _coaches.map((coach) {
          final isSelected = _selectedCoaches.contains(coach['id']);
          final maxPerDay = (coach['maxSessionsPerDay'] ?? 2);
          final maxPerWeek = (coach['maxSessionsPerWeek'] ?? 10);
          final dailySessions = (coach['dailySessions'] ?? 0);
          final weeklySessions = (coach['weeklySessions'] ?? 0);

          final remainingDaily = maxPerDay - dailySessions;
          final remainingWeekly = maxPerWeek - weeklySessions;

          return ChoiceChip(
            label: Text("${coach['name']} 📅$remainingDaily/$maxPerDay 🗓️$remainingWeekly/$maxPerWeek"),
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
              TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Sélectionner une date',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dateController.text =
                        DateFormat('dd/MM/yyyy').format(pickedDate);
                  });
                await _fetchCoachSessionCounts(pickedDate);

                }
              },
            ),            const SizedBox(height: 16),
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
            ],
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
            _buildCoachSelection(),
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
      'coaches': _selectedCoaches,

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
