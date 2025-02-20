import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/intl.dart';

class JourneeDetails extends StatefulWidget {
  final String championshipId;
  final int journeeIndex;
  final Map<String, dynamic> journeeData;

  const JourneeDetails({
    Key? key,
    required this.championshipId,
    required this.journeeIndex,
    required this.journeeData,
  }) : super(key: key);

  @override
  _JourneeDetailsState createState() => _JourneeDetailsState();
}

class _JourneeDetailsState extends State<JourneeDetails> {
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _transportModeController = TextEditingController();
  final _coachesController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _feeController = TextEditingController();
  final List<String> _transportModes = ['Covoiturage', 'Bus', 'Individuel'];

  List<String> _allCoaches = []; // Stores all available coaches
List<String> _selectedCoaches = []; // Stores selected coaches
  String? _selectedTransportMode;

  @override
  void initState() {
    super.initState();
    _loadData();
      _fetchCoaches(); // ✅ Fetch coaches when the screen loads

  }


Future<void> _fetchCoaches() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('coaches').get();
    setState(() {
      _allCoaches = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  } catch (e) {
    print("❌ Error fetching coaches: $e");
  }
}
  void _loadData() {
    // 🛠 Fix Date Handling
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
          print("❌ Error parsing date: ${widget.journeeData['date']} - $e");
          _dateController.text = ''; // Set to empty if invalid
        }
      } else {
        _dateController.text = ''; // Default empty value if missing
      }
    } else {
      _dateController.text = ''; // Ensure default empty value
    }

    // 🛠 Fix Dropdown Default Value
    List<String> transportModes = ['Covoiturage', 'Bus', 'Individuel'];
    _selectedTransportMode =
        transportModes.contains(widget.journeeData['transportMode'])
            ? widget.journeeData['transportMode']
            : transportModes.first; // Default to first option if invalid

    _transportModeController.text =
        _selectedTransportMode ?? transportModes.first;
    _timeController.text = widget.journeeData['time'] ?? '';
    _departureTimeController.text = widget.journeeData['departureTime'] ?? '';
    _feeController.text = widget.journeeData['fee']?.toString() ?? '';
  }

  Future<void> _saveJournee() async {
    DocumentReference championshipRef = FirebaseFirestore.instance
        .collection('championships')
        .doc(widget.championshipId);
    DocumentSnapshot snapshot = await championshipRef.get();
    List<dynamic> matchDays =
        (snapshot.data() as Map<String, dynamic>)['matchDays'] ?? [];

    matchDays[widget.journeeIndex] = {
      'date': _dateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd/MM/yyyy').parse(_dateController.text))
          : null,
      'time': _timeController.text,
      'transportMode': _selectedTransportMode,
      'coaches': _selectedCoaches,
      'departureTime': _departureTimeController.text,
      'fee': _feeController.text.isNotEmpty
          ? double.parse(_feeController.text)
          : null,
    };

    await championshipRef.update({'matchDays': matchDays});
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: "Détails de la Journée",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _buildSectionTitle('Journée N°${widget.journeeIndex + 1}', Icons.calendar_today),
            const SizedBox(height: 16),
            _buildSectionTitle('Date', Icons.calendar_today),
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
                }
              },
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Heure du match', Icons.access_time),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Sélectionner une heure',
                border: OutlineInputBorder(),
              ),
              onTap: () => _pickTime(_timeController),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Mode de Transport', Icons.directions_bus),
            DropdownButtonFormField<String>(
              value: _selectedTransportMode, // ✅ Always valid
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
              TextField(
                controller: _departureTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner une heure',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _pickTime(_departureTimeController),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Frais de Transport (€)', Icons.euro),
              TextField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Frais de transport',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
           _buildCoachesSelection(),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveJournee,
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCoachesSelection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Coachs assignés', Icons.person),
      Wrap(
        spacing: 8,
        children: _allCoaches.map((coach) {
          final isSelected = _selectedCoaches.contains(coach);
          return FilterChip(
            label: Text(coach),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedCoaches.add(coach);
                } else {
                  _selectedCoaches.remove(coach);
                }
              });
            },
            selectedColor: Colors.blueAccent.withOpacity(0.3),
            checkmarkColor: Colors.white,
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
      Text("Coach(s) sélectionné(s): ${_selectedCoaches.join(', ')}"),
    ],
  );
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
}
