import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Backend_template.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class AddCoachPage extends StatefulWidget {
  const AddCoachPage({Key? key}) : super(key: key);

  @override
  _AddCoachPageState createState() => _AddCoachPageState();
}

class _AddCoachPageState extends State<AddCoachPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
  final TextEditingController _diplomaTypeController = TextEditingController();
  final TextEditingController _maxSessionsPerDayController =
      TextEditingController(); // Max sessions per day
  final TextEditingController _maxSessionsPerWeekController =
      TextEditingController(); // Max sessions per week

  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'TN'); // Default to Tunisia
  String? _validatedPhoneNumber; // Validated phone number
  DateTime? _birthDate;
  bool _hasOtherActivity = false;

  String _maritalStatus = "Célibataire";
  String _financialStatus = "Bonne";
  List<String> _selectedObjectives = [];
  String _diploma = "Non";
  String _coachLevel = "Niveau 1";
  bool _isLoading = false;

  Future<void> _addCoach() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String coachId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('coaches').doc(coachId).set({
        'name': _nameController.text.trim(),
        'phone': _validatedPhoneNumber,
        'email': _emailController.text.trim(),
        'birthDate': _birthDate != null
            ? Timestamp.fromDate(DateTime(
                _birthDate!.year,
                _birthDate!.month,
                _birthDate!.day,
              ))
            : null,
        'address': _addressController.text.trim(),
        'maritalStatus': _maritalStatus,
        'numberOfChildren': _maritalStatus == 'Marié(e)'
            ? int.tryParse(_childrenController.text.trim())
            : null,
        'financialStatus': _financialStatus,
        'objectives': _selectedObjectives,
        'diploma': _diploma,
        'diplomaType':
            _diploma == 'Oui' ? _diplomaTypeController.text.trim() : null,
        'coachLevel': _coachLevel,
        'maxSessionsPerDay':
            int.tryParse(_maxSessionsPerDayController.text.trim()) ?? 0,
        'maxSessionsPerWeek':
            int.tryParse(_maxSessionsPerWeekController.text.trim()) ?? 0,
        'hasOtherActivity': _hasOtherActivity,
        'salary': double.tryParse(_salaryController.text.trim()) ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach ajouté avec succès!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        obscureText: isPassword,
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

  Widget _buildDropdownField(String label, String value, List<String> items,
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

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InternationalPhoneNumberInput(
        onInputChanged: (PhoneNumber number) {
          _phoneNumber = number;
        },
        onSaved: (PhoneNumber number) {
          _validatedPhoneNumber = number.phoneNumber;
        },
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.DROPDOWN,
          setSelectorButtonAsPrefixIcon: true,
        ),
        ignoreBlank: false,
        countries: const ['TN', 'FR', 'US', 'DE', 'IT'],
        initialValue: _phoneNumber,
        textFieldController: TextEditingController(),
        inputDecoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Numéro de téléphone',
          prefixIcon: Icon(Icons.phone),
        ),
      ),
    );
  }

  Widget _buildCheckboxField(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...options.map((option) {
            return CheckboxListTile(
              title: Text(option),
              value: _selectedObjectives.contains(option),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedObjectives.add(option);
                  } else {
                    _selectedObjectives.remove(option);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplatePageBack(
      title: 'Ajouter un Coach',
      footerIndex: 1,
      isCoach: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Nom et Prénom (Coach)', _nameController),
              _buildPhoneNumberField(),
              _buildTextField('Adresse Email', _emailController),
              _buildTextField('Mot de Passe', _passwordController,
                  isPassword: true),
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
                  _maxSessionsPerDayController, isNumeric: true),
              _buildTextField('Nombre de Séances Max Par Semaine',
                  _maxSessionsPerWeekController, isNumeric: true),
              _buildTextField('Salaire Mensuel', _salaryController,
                  isNumeric: true),
              Row(
                children: [
                  Checkbox(
                    value: _hasOtherActivity,
                    onChanged: (value) {
                      setState(() {
                        _hasOtherActivity = value!;
                      });
                    },
                  ),
                  const Text('Autre activité qu\'entraîneur de foot'),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addCoach,
                        child: const Text('Ajouter le Coach'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
