// ignore_for_file: empty_catches, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:intl/intl.dart';

class JourneeDetails extends StatefulWidget {
  final String championshipId;
  final int journeeIndex;
  final Map<String, dynamic> journeeData;
  final Map<String, dynamic>? session;

  const JourneeDetails({
    Key? key,
    required this.championshipId,
    required this.journeeIndex,
    required this.journeeData,
    this.session,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _JourneeDetailsState createState() => _JourneeDetailsState();
}

class _JourneeDetailsState extends State<JourneeDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _transportModeController = TextEditingController();

  final _departureTimeController = TextEditingController();
  final _feeController = TextEditingController();
  List<Map<String, dynamic>> _coaches = []; // Stores coaches with session count
  List<String> _selectedCoaches = []; // Selected coaches
  String? _selectedTransportMode;
  String? _championshipName;

  @override
  void initState() {
    super.initState();
    _selectedCoaches = List<String>.from(widget.session?['coaches'] ?? []);

    _loadData();
    _fetchCoaches(); // ✅ Fetch coaches and their session limits
    _fetchChampionshipName(); // ✅ Fetch championship name when screen loads
  }

  /// ✅ **Fetch Championship Name from Firestore**
  Future<void> _fetchChampionshipName() async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('championships')
          .doc(widget.championshipId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _championshipName = snapshot['name'] ?? 'Championnat Introuvable';
        });
      } else {
        setState(() {
          _championshipName = 'Championnat Introuvable';
        });
      }
    } catch (e) {
      setState(() {
        _championshipName = 'Erreur de chargement';
      });
    }
  }

 void _loadData() {
  // ✅ Vérifier si une date est enregistrée et la convertir correctement
  if (widget.journeeData.containsKey('date')) {
    if (widget.journeeData['date'] is Timestamp) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(
        (widget.journeeData['date'] as Timestamp).toDate(),
      );
    } else if (widget.journeeData['date'] is String &&
        widget.journeeData['date'].isNotEmpty) {
      try {
        _dateController.text = DateFormat('dd/MM/yyyy').format(
          DateTime.parse(widget.journeeData['date']),
        );
      } catch (e) {
        _dateController.text = ''; // ✅ S'assurer que la valeur est correcte
      }
    } else {
      _dateController.text = ''; // ✅ Valeur par défaut si vide
    }
  } else {
    _dateController.text = ''; // ✅ Valeur par défaut
  }

  // ✅ Assurer que les autres champs ne sont pas nuls
  _timeController.text = widget.journeeData['time'] ?? '';
  _departureTimeController.text = widget.journeeData['departureTime'] ?? '';
  _feeController.text = widget.journeeData['fee']?.toString() ?? '';

  // ✅ Vérifier que le mode de transport est valide
  List<String> transportModes = ['Covoiturage', 'Bus', 'Individuel'];
  _selectedTransportMode = transportModes.contains(widget.journeeData['transportMode'])
      ? widget.journeeData['transportMode']
      : transportModes.first;
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
    _selectedCoaches = List<String>.from(widget.journeeData['coaches'] ?? []);
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

  /// ✅ **Save "Journée" with assigned coaches**
 Future<void> _saveJournee() async {
  try {
    if (widget.championshipId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Vous devez d'abord enregistrer un championnat !"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    DocumentReference championshipRef =
        _firestore.collection('championships').doc(widget.championshipId);
    DocumentSnapshot snapshot = await championshipRef.get();

    if (!snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Erreur : Le championnat n'existe pas !")),
      );
      return;
    }

    List<dynamic> matchDays =
        (snapshot.data() as Map<String, dynamic>)['matchDays'] ?? [];

    // ✅ Vérifier si la journée existe déjà, sinon en créer une vide
    Map<String, dynamic> existingDay = matchDays.length > widget.journeeIndex
        ? Map<String, dynamic>.from(matchDays[widget.journeeIndex])
        : {};

    // ✅ Mise à jour conditionnelle (si l'utilisateur a modifié un champ)
    existingDay['date'] = _dateController.text.isNotEmpty
        ? DateFormat('yyyy-MM-dd')
            .format(DateFormat('dd/MM/yyyy').parse(_dateController.text))
        : existingDay['date'];

    existingDay['time'] = _timeController.text.isNotEmpty
        ? _timeController.text
        : existingDay['time'];

    existingDay['transportMode'] =
        _selectedTransportMode ?? existingDay['transportMode'];

    existingDay['coaches'] = _selectedCoaches.isNotEmpty
        ? _selectedCoaches
        : existingDay['coaches'];

    existingDay['departureTime'] = _departureTimeController.text.isNotEmpty
        ? _departureTimeController.text
        : existingDay['departureTime'];

    existingDay['fee'] = _feeController.text.isNotEmpty
        ? double.parse(_feeController.text)
        : existingDay['fee'];

    // ✅ Vérifier si la liste `matchDays` est assez grande
    while (matchDays.length <= widget.journeeIndex) {
      matchDays.add({});
    }

    matchDays[widget.journeeIndex] = existingDay; // ✅ Mise à jour des valeurs

    await championshipRef.update({'matchDays': matchDays});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Journée mise à jour avec succès !")),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Erreur lors de l'enregistrement : $e")),
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

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: "Détails de la Journée",
      footerIndex: 3,
      isCoach: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Display Championship Name at the Top
            if (_championshipName != null) ...[
              Text(
                _championshipName!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
            ],

            _buildSectionTitle(
                'Journée N°${widget.journeeIndex + 1}', Icons.calendar_today),
            const SizedBox(height: 16),

            // 🔹 Date & Time in One Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          'Date du Journée', Icons.calendar_today),
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
                            onPressed: () => _pickDate(),
                          ),
                        ),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16), // Space between fields
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Heure du Match', Icons.access_time),
                      TextFormField(
                        readOnly: true,
                        controller: _timeController,
                        decoration: InputDecoration(
                          labelText: 'Sélectionner une heure',
                          border: const OutlineInputBorder(),
                          prefixIcon:
                              const Icon(Icons.schedule, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time,
                                color: Colors.green),
                            onPressed: () => _pickTime(_timeController),
                          ),
                        ),
                        onTap: () => _pickTime(_timeController),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('Mode de Transport', Icons.directions_bus),
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
              _buildSectionTitle('Heure de départ', Icons.departure_board),
              TextFormField(
                        readOnly: true,
                        controller: _departureTimeController,
                        decoration: InputDecoration(
                          labelText: 'Sélectionner une heure',
                          border: const OutlineInputBorder(),
                          prefixIcon:
                              const Icon(Icons.schedule, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time,
                                color: Colors.green),
                            onPressed: () => _pickTime(_departureTimeController),
                          ),
                        ),
                        onTap: () => _pickTime(_departureTimeController),
                      ),
              const SizedBox(height: 16),
              _buildSectionTitle('Frais de Transport (TND)', Icons.money),
              TextFormField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Frais de transport',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildCoachSelection(),
            const SizedBox(height: 16),
            Row(
  mainAxisAlignment: MainAxisAlignment.center, // ✅ Center the button
  children: [
    ElevatedButton(
      onPressed: _saveJournee,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), // ✅ Adjust size
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // ✅ Bigger text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // ✅ Rounded corners
        ),
      ),
      child: const Text("Enregistrer"),
    ),
  ],
),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _updateDateController(pickedDate); // ✅ Met à jour le champ de texte
      });
    }
  }

  void _updateDateController(DateTime date) {
    _dateController.text = "${date.day}/${date.month}/${date.year}";
  }

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
}
