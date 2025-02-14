import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
  final TextEditingController _diplomaTypeController = TextEditingController();
  final TextEditingController _maxSessionsPerDayController = TextEditingController();
  final TextEditingController _maxSessionsPerWeekController = TextEditingController();
  File? _image;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  DateTime? _birthDate;
  String? _maritalStatus;
  String? _financialStatus;
  String? _diploma;
  String? _coachLevel;
  List<String> _selectedObjectives = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCoachDetails();
  }

  Future<void> _loadCoachDetails() async {
    final coachDoc = await _firestore.collection('coaches').doc(widget.coachId).get();
    if (coachDoc.exists) {
      final data = coachDoc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _addressController.text = data['address'] ?? '';
        _salaryController.text = (data['salary'] ?? '').toString();
        _birthDate = data['birthDate'] != null
            ? (data['birthDate'] as Timestamp).toDate()
            : null;
        _imageUrl = data['imageUrl'] ?? null;
        _maritalStatus = data['maritalStatus'] ?? '';
        _childrenController.text = (data['children'] ?? '').toString();
        _financialStatus = data['financialStatus'] ?? '';
        _diploma = data['diploma'] ?? '';
        _diplomaTypeController.text = data['diplomaType'] ?? '';
        _coachLevel = data['coachLevel'] ?? '';
        _maxSessionsPerDayController.text = (data['maxSessionsPerDay'] ?? '').toString();
        _maxSessionsPerWeekController.text = (data['maxSessionsPerWeek'] ?? '').toString();
        _selectedObjectives = List<String>.from(data['objectives'] ?? []);
      });
    }
  }

  Future<void> _saveCoachDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update coach details
      await _firestore.collection('coaches').doc(widget.coachId).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
        'maritalStatus': _maritalStatus,
        'children': int.tryParse(_childrenController.text) ?? 0,
        'financialStatus': _financialStatus,
        'diploma': _diploma,
        'diplomaType': _diplomaTypeController.text.trim(),
        'coachLevel': _coachLevel,
        'maxSessionsPerDay': int.tryParse(_maxSessionsPerDayController.text) ?? 0,
        'maxSessionsPerWeek': int.tryParse(_maxSessionsPerWeekController.text) ?? 0,
        'objectives': _selectedObjectives,
      });

      // Upload new image if changed
      if (_image != null) {
        await _uploadImage(widget.coachId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations du coach mises à jour avec succès!')),
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

  Future<void> _uploadImage(String coachId) async {
    if (_image == null) return;
    try {
      final ref = FirebaseStorage.instance.ref().child('coaches/$coachId.jpg');
      await ref.putFile(_image!);
      String imageUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('coaches').doc(coachId).update({'imageUrl': imageUrl});
      setState(() {
        _imageUrl = imageUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image mise à jour avec succès!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement de l\'image: $e')),
      );
    }
  }

  Widget _buildDropdownField(String label, String? value, List<String> items,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }

  Widget _buildCheckboxField(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Wrap(
            spacing: 8.0,
            children: options.map((option) {
              return FilterChip(
                label: Text(option),
                selected: _selectedObjectives.contains(option),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedObjectives.add(option);
                    } else {
                      _selectedObjectives.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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
              Center(
                child: Column(
                  children: [
                    _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _image!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrl!,
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Modifier la photo'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTextField('Nom et Prénom', _nameController),
              _buildTextField('Adresse Email', _emailController),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
              _buildDropdownField(
                'Situation Familiale',
                _maritalStatus,
                ['Célibataire', 'Marié(e)', 'Divorcé(e)'],
                (value) => setState(() => _maritalStatus = value!),
              ),
              if (_maritalStatus == 'Marié(e)')
                _buildTextField('Nombre d’Enfants', _childrenController,
                    isNumeric: true),
              _buildDropdownField(
                'Situation Financière',
                _financialStatus,
                ['Bonne', 'Moyenne', 'Limitée'],
                (value) => setState(() => _financialStatus = value!),
              ),
              _buildCheckboxField('Objectifs', [
                'Raisons Pécuniaires',
                'Occupation du Temps et Passion au football',
              ]),
              _buildDropdownField(
                'Diplôme',
                _diploma,
                ['Oui', 'Non'],
                (value) => setState(() {
                  _diploma = value!;
                  if (_diploma == 'Non') {
                    _diplomaTypeController.clear();
                  }
                }),
              ),
              if (_diploma == 'Oui')
                _buildTextField('Type de Diplôme', _diplomaTypeController),
              _buildDropdownField(
                'Niveau du Coach',
                _coachLevel,
                ['Niveau 1', 'Niveau 2'],
                (value) => setState(() => _coachLevel = value!),
              ),
              _buildTextField('Nombre de Séances Max Par Jour',
                  _maxSessionsPerDayController,
                  isNumeric: true),
              _buildTextField('Nombre de Séances Max Par Semaine',
                  _maxSessionsPerWeekController,
                  isNumeric: true),
              _buildTextField('Salaire Mensuel', _salaryController, isNumeric: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCoachDetails,
                child: const Text('Enregistrer les Modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
