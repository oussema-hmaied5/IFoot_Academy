import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/intl.dart';

class EditCoachPage extends StatefulWidget {
  final String coachId;

  const EditCoachPage({Key? key, required this.coachId}) : super(key: key);

  @override
  _EditCoachPageState createState() => _EditCoachPageState();
}

class _EditCoachPageState extends State<EditCoachPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
  final TextEditingController _diplomaTypeController = TextEditingController();
  final TextEditingController _maxSessionsPerDayController =
      TextEditingController();
  final TextEditingController _maxSessionsPerWeekController =
      TextEditingController();

  DateTime? _birthDate;
  String _maritalStatus = "Célibataire";
  String _financialStatus = "Bonne";
  List<String> _objectives = [];
  String _diploma = "Non";
  String _coachLevel = "Niveau 1";
  bool _hasOtherActivity = false;

  bool _isLoading = false;

  final List<String> _objectiveOptions = [
    'Raisons Pécunaires',
    'Occupation du Temps et Passion au football',
  ];

  @override
  void initState() {
    super.initState();
    _loadCoachDetails();
  }

  Future<void> _loadCoachDetails() async {
    final coachDoc =
        await _firestore.collection('coaches').doc(widget.coachId).get();
    if (coachDoc.exists) {
      final data = coachDoc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _addressController.text = data['address'] ?? '';
        _salaryController.text = (data['salary'] ?? '').toString();
        _birthDate = data['birthDate'] != null
            ? (data['birthDate'] as Timestamp).toDate()
            : null;
        _maritalStatus = data['maritalStatus'] ?? 'Célibataire';
        _financialStatus = data['financialStatus'] ?? 'Bonne';
        _objectives = List<String>.from(data['objectives'] ?? []);
        _diploma = data['diploma'] ?? 'Non';
        _coachLevel = data['coachLevel'] ?? 'Niveau 1';
        _maxSessionsPerDayController.text =
            (data['maxSessionsPerDay'] ?? '').toString();
        _maxSessionsPerWeekController.text =
            (data['maxSessionsPerWeek'] ?? '').toString();
        _childrenController.text = (data['numberOfChildren'] ?? '').toString();
        _diplomaTypeController.text = data['diplomaType'] ?? '';
        _hasOtherActivity = data['hasOtherActivity'] ?? false;
      });
    }
  }

  Future<void> _saveCoachDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('coaches').doc(widget.coachId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'birthDate': _birthDate != null
            ? Timestamp.fromDate(DateTime(
                _birthDate!.year,
                _birthDate!.month,
                _birthDate!.day,
              ))
            : null,
        'maritalStatus': _maritalStatus,
        'financialStatus': _financialStatus,
        'objectives': _objectives,
        'diploma': _diploma,
        'diplomaType': _diploma == 'Oui'
            ? _diplomaTypeController.text.trim()
            : null,
        'coachLevel': _coachLevel,
        'maxSessionsPerDay':
            int.tryParse(_maxSessionsPerDayController.text) ?? 0,
        'maxSessionsPerWeek':
            int.tryParse(_maxSessionsPerWeekController.text) ?? 0,
        'numberOfChildren': _maritalStatus == 'Marié(e)'
            ? int.tryParse(_childrenController.text) ?? 0
            : null,
        'hasOtherActivity': _hasOtherActivity,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Informations du coach mises à jour avec succès!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMultiSelectField(
      String label, List<String> items, List<String> selectedItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return CheckboxListTile(
              title: Text(item),
              value: selectedItems.contains(item),
              onChanged: (bool? isSelected) {
                setState(() {
                  if (isSelected == true) {
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Modifier un Coach',
      footerIndex: 1,
      isCoach: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Nom et Prénom', _nameController),
              _buildTextField('Numéro de Téléphone', _phoneController),
              GestureDetector(
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _birthDate = selectedDate;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _birthDate == null
                            ? 'Sélectionnez une Date de Naissance'
                            : 'Date de Naissance: ${DateFormat('dd/MM/yyyy').format(_birthDate!)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              _buildTextField('Adresse Domicile', _addressController),
              _buildTextField('Salaire Mensuel', _salaryController,
                  isNumeric: true),
              _buildTextField('Nombre de Séances Max Par Jour',
                  _maxSessionsPerDayController,
                  isNumeric: true),
              _buildTextField('Nombre de Séances Max Par Semaine',
                  _maxSessionsPerWeekController,
                  isNumeric: true),
              _buildMultiSelectField('Objectifs', _objectiveOptions, _objectives),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _hasOtherActivity,
                    onChanged: (value) =>
                        setState(() => _hasOtherActivity = value!),
                  ),
                  const Text('Autre Activité qu\'entraîneur de foot'),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCoachDetails,
                        child: const Text('Enregistrer les Modifications'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
