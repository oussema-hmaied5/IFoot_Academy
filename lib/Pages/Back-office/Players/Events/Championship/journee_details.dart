// ignore_for_file: empty_catches, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Coach/coach_service.dart';
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
  final _coachService = CoachService(); // Utilisation du service de coach

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  bool _isFree = false;
  late DateTime _date;
  final _departureTimeController = TextEditingController();
  final _feeController = TextEditingController();
  List<Map<String, dynamic>> _coaches = []; // Coachs avec leurs sessions
  List<String> _selectedCoaches = []; // Coachs sélectionnés
  String? _selectedTransportMode;
  String? _championshipName;

  @override
  void initState() {
    super.initState();
    _selectedCoaches = List<String>.from(widget.session?['coaches'] ?? []);

    _loadData();
    _loadCoachesData();
    _fetchChampionshipName();
  }

  /// Charge les données des coachs avec leur disponibilité
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

  /// Récupère le nom du championnat depuis Firestore
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

  /// Charge les données initiales du formulaire
  void _loadData() {
    // Gestion de la date
    if (widget.journeeData.containsKey('date')) {
      if (widget.journeeData['date'] is Timestamp) {
        _date = (widget.journeeData['date'] as Timestamp).toDate();
      } else if (widget.journeeData['date'] is String &&
          widget.journeeData['date'].isNotEmpty) {
        try {
          _date = DateTime.parse(widget.journeeData['date']);
        } catch (e) {
          _date = DateTime.now();
        }
      } else {
        _date = DateTime.now();
      }

      _dateController.text = DateFormat('dd/MM/yyyy').format(_date);
    } else {
      _date = DateTime.now();
      _dateController.text = '';
    }

    // Autres champs du formulaire
    _timeController.text = widget.journeeData['time'] ?? '';
    _departureTimeController.text = widget.journeeData['departureTime'] ?? '';

    _feeController.text = !_isFree && widget.journeeData['fee'] != null
        ? widget.journeeData['fee'].toString()
        : '';
    _isFree = widget.journeeData['fee'] == 'Gratuit';

    // Mode de transport
    List<String> transportModes = ['Covoiturage', 'Bus', 'Individuel'];
    _selectedTransportMode =
        transportModes.contains(widget.journeeData['transportMode'])
            ? widget.journeeData['transportMode']
            : transportModes.first;
  }

 

  
  /// Enregistre les données de la journée
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

      // Validation de la date
      if (_dateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Veuillez spécifier une date pour la journée"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validation du temps
      if (_timeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Veuillez spécifier l'heure du match"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Vérification des coachs surchargés
      if (_selectedCoaches.isNotEmpty && _dateController.text.isNotEmpty) {
        DateTime selectedDate =
            DateFormat('dd/MM/yyyy').parse(_dateController.text);
        bool canProceed = await _coachService.validateCoachSelection(
            _selectedCoaches, selectedDate, context);

        if (!canProceed) {
          return; // L'utilisateur a annulé ou attend sa confirmation
        }
      }

      DocumentReference championshipRef =
          _firestore.collection('championships').doc(widget.championshipId);
      DocumentSnapshot snapshot = await championshipRef.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("⚠️ Erreur : Le championnat n'existe pas !")),
        );
        return;
      }

      List<dynamic> matchDays =
          (snapshot.data() as Map<String, dynamic>)['matchDays'] ?? [];

      // Préparation des données de la journée
      Map<String, dynamic> existingDay = matchDays.length > widget.journeeIndex
          ? Map<String, dynamic>.from(matchDays[widget.journeeIndex])
          : {};

      // Mise à jour des données
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

      existingDay['fee'] = _isFree
          ? 'Gratuit'
          : _feeController.text.isNotEmpty
              ? int.tryParse(_feeController.text)
              : existingDay['fee'];

      // Assurer que la liste matchDays est assez grande
      while (matchDays.length <= widget.journeeIndex) {
        matchDays.add({});
      }

      matchDays[widget.journeeIndex] = existingDay;

      await championshipRef.update({'matchDays': matchDays});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Journée mise à jour avec succès !"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de l'enregistrement : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Crée un titre de section
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
            // Titre du championnat
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

            // Date et heure
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                        'Informations du match', Icons.sports_soccer),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date du match',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                readOnly: true,
                                controller: _dateController,
                                decoration: InputDecoration(
                                  labelText: 'Sélectionner une date',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.calendar_today,
                                      color: Colors.blue),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.event,
                                        color: Colors.green),
                                    onPressed: () => _pickDate(),
                                  ),
                                ),
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Heure du match',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                readOnly: true,
                                controller: _timeController,
                                decoration: InputDecoration(
                                  labelText: 'Sélectionner une heure',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.schedule,
                                      color: Colors.blue),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Transport
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        prefixIcon: Icon(Icons.directions_bus,
                            color: Colors.blueAccent),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
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
                                  onTap: () =>
                                      _pickTime(_departureTimeController),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
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
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Coaches
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Affectation des Coaches', Icons.sports),
                    const SizedBox(height: 8),
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
            const SizedBox(height: 32),                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton d'enregistrement
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveJournee,
                icon: const Icon(Icons.save, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                label: const Text("Enregistrer",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
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
}
