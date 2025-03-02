// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:intl/intl.dart';

class AssignTrainingPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AssignTrainingPage(
      {Key? key, required this.groupId, required this.groupName})
      : super(key: key);

  @override
  _AssignTrainingPageState createState() => _AssignTrainingPageState();
}

class _AssignTrainingPageState extends State<AssignTrainingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedDay = "Lundi";
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _daysOfWeek = [
    "Lundi",
    "Mardi",
    "Mercredi",
    "Jeudi",
    "Vendredi",
    "Samedi",
    "Dimanche",
  ];

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStart ? _startTime ?? TimeOfDay.now() : _endTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dateTime).replaceAll(':', 'h');
  }

  Future<void> _saveTraining() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Veuillez sélectionner une heure de début et de fin.")),
      );
      return;
    }

    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final lastDayOfYear = DateTime(now.year, 12, 31);

    final List<DateTime> trainingDates = [];
    DateTime currentDate = firstDayOfYear;

    while (!currentDate.isAfter(lastDayOfYear)) {
      final currentDayName =
          DateFormat('EEEE', 'fr_FR').format(currentDate).capitalize();
      if (_selectedDay == currentDayName) {
        trainingDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (trainingDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Aucune date trouvée pour ce jour sélectionné.")),
      );
      return;
    }

    final batch = _firestore.batch();
    for (final date in trainingDates) {
      final trainingRef = _firestore.collection("trainings").doc();
      batch.set(trainingRef, {
        "groupId": widget.groupId,
        "groupName": widget.groupName,
        "day": _selectedDay,
        "date": date.toIso8601String(),
        "startTime": formatTimeOfDay(_startTime!),
        "endTime": formatTimeOfDay(_endTime!),
      });
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Séances ajoutées pour toute l'année !")),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: ("Planifier une séance - ${widget.groupName}"),
            footerIndex: 2, // Set the correct footer index for the "Users" page

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choisissez un jour de la semaine :",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: _selectedDay,
                isExpanded: true,
                underline: Container(),
                items: _daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(day),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Heure de début :",
                      style: TextStyle(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => _pickTime(true),
                      child: Text(
                        _startTime != null
                            ? formatTimeOfDay(_startTime!)
                            : "Sélectionner",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Heure de fin :",
                      style: TextStyle(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => _pickTime(false),
                      child: Text(
                        _endTime != null
                            ? formatTimeOfDay(_endTime!)
                            : "Sélectionner",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveTraining,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "Enregistrer la séance",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this; // Retourne la chaîne d'origine si elle est vide
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}