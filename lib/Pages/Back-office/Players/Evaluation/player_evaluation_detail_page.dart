// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';
import 'package:percent_indicator/percent_indicator.dart';

class PlayerEvaluationDetailPage extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String groupName;

  const PlayerEvaluationDetailPage({
    Key? key,
    required this.playerId,
    required this.playerName,
    required this.groupName,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PlayerEvaluationDetailPageState createState() =>
      _PlayerEvaluationDetailPageState();
}

class _PlayerEvaluationDetailPageState extends State<PlayerEvaluationDetailPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  // Variables pour stocker les évaluations
  final Map<String, int> _mentalEvaluation = {
    'motivation': 0,
    'concentration': 0,
    'desir_gagner': 0,
    'esprit_equipe': 0,
    'force_caractere': 0,
    'sociabilite': 0,
    'intelligence': 0,
  };

  final Map<String, int> _physicalEvaluation = {
    'taille': 0,
    'poids': 0,
    'rapidite': 0,
    'endurance': 0,
    'vitesse_reaction': 0,
  };

  final Map<String, int> _technicalEvaluation = {
    'conduite_pied_fort': 0,
    'conduite_pied_faible': 0,
    'passe_pied_fort': 0,
    'passe_pied_faible': 0,
    'passe_en_mouvement': 0,
    'controle_statique': 0,
    'controle_oriente': 0,
    'jonglage_pied_fort': 0,
    'jonglage_pied_faible': 0,
    'jonglage_simultane': 0,
    'maitrise_ballon': 0,
    'tir_pied_fort': 0,
    'tir_pied_faible': 0,
    'tir_en_mouvement': 0,
    'jeu_de_tete': 0,
    'dribble_1v1': 0,
    'defense_1v1': 0,
    'controle_aerien': 0,
  };

  bool _isLoading = true;
  Map<String, dynamic>? _playerData;
  Map<String, dynamic>? _existingEvaluation;

  // Définir les poids pour chaque catégorie (pourcentage d'importance)
  final Map<String, double> _categoryWeights = {
    'technical': 0.5, // 50% de la note globale
    'physical': 0.3, // 30% de la note globale
    'mental': 0.2, // 20% de la note globale
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPlayerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _calculateCategoryScore(Map<String, int> evaluations) {
    if (evaluations.isEmpty) return 0;

    int total = 0;
    int filledCriteria = 0;

    for (var score in evaluations.values) {
      if (score > 0) {
        total += score;
        filledCriteria++;
      }
    }

    if (filledCriteria == 0) return 0;
    return total / (filledCriteria * 4); // Score sur 4
  }

  double _calculateWeightedScore() {
    double technicalScore = _calculateCategoryScore(_technicalEvaluation);
    double physicalScore = _calculateCategoryScore(_physicalEvaluation);
    double mentalScore = _calculateCategoryScore(_mentalEvaluation);

    return (technicalScore * _categoryWeights['technical']!) +
        (physicalScore * _categoryWeights['physical']!) +
        (mentalScore * _categoryWeights['mental']!);
  }

  Future<void> _fetchPlayerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les données du joueur
      DocumentSnapshot playerDoc =
          await _firestore.collection('children').doc(widget.playerId).get();

      if (playerDoc.exists) {
        _playerData = playerDoc.data() as Map<String, dynamic>;
      }

      // Vérifier s'il existe déjà une évaluation pour ce joueur
      QuerySnapshot evaluationSnapshot = await _firestore
          .collection('evaluations')
          .where('playerId', isEqualTo: widget.playerId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (evaluationSnapshot.docs.isNotEmpty) {
        _existingEvaluation =
            evaluationSnapshot.docs.first.data() as Map<String, dynamic>;

        // Charger les valeurs existantes
        if (_existingEvaluation!['mental'] != null) {
          Map<String, dynamic> mental = _existingEvaluation!['mental'];
          mental.forEach((key, value) {
            if (_mentalEvaluation.containsKey(key)) {
              _mentalEvaluation[key] = value as int;
            }
          });
        }

        if (_existingEvaluation!['physical'] != null) {
          Map<String, dynamic> physical = _existingEvaluation!['physical'];
          physical.forEach((key, value) {
            if (_physicalEvaluation.containsKey(key)) {
              _physicalEvaluation[key] = value as int;
            }
          });
        }

        if (_existingEvaluation!['technical'] != null) {
          Map<String, dynamic> technical = _existingEvaluation!['technical'];
          technical.forEach((key, value) {
            if (_technicalEvaluation.containsKey(key)) {
              _technicalEvaluation[key] = value as int;
            }
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEvaluation() async {
    // Vérifier si au moins une évaluation a été faite
    bool hasAnyEvaluation = false;

    for (var value in _mentalEvaluation.values) {
      if (value > 0) {
        hasAnyEvaluation = true;
        break;
      }
    }

    if (!hasAnyEvaluation) {
      for (var value in _physicalEvaluation.values) {
        if (value > 0) {
          hasAnyEvaluation = true;
          break;
        }
      }
    }

    if (!hasAnyEvaluation) {
      for (var value in _technicalEvaluation.values) {
        if (value > 0) {
          hasAnyEvaluation = true;
          break;
        }
      }
    }

    if (!hasAnyEvaluation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez faire au moins une évaluation avant d\'enregistrer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculer les scores moyens pour chaque catégorie
      double technicalScore = _calculateCategoryScore(_technicalEvaluation);
      double physicalScore = _calculateCategoryScore(_physicalEvaluation);
      double mentalScore = _calculateCategoryScore(_mentalEvaluation);

      // Calculer le score global pondéré
      double weightedScore = _calculateWeightedScore();

      Map<String, dynamic> evaluationData = {
        'playerId': widget.playerId,
        'playerName': widget.playerName,
        'groupName': widget.groupName,
        'date': Timestamp.now(),
        'mental': _mentalEvaluation,
        'physical': _physicalEvaluation,
        'technical': _technicalEvaluation,
        'scores': {
          'technicalScore': technicalScore,
          'physicalScore': physicalScore,
          'mentalScore': mentalScore,
          'weightedScore': weightedScore,
        },
        'weights': _categoryWeights,
      };

      // Ajouter l'évaluation à la collection
      await _firestore.collection('evaluations').add(evaluationData);

      // Mettre à jour le score moyen du joueur
      await _firestore.collection('children').doc(widget.playerId).update({
        'lastEvaluationScore': weightedScore,
        'lastEvaluationDate': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Évaluation enregistrée avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isLoading = false;
      });

      // Retourner à la page précédente après sauvegarde
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double technicalScore = _calculateCategoryScore(_technicalEvaluation);
    double physicalScore = _calculateCategoryScore(_physicalEvaluation);
    double mentalScore = _calculateCategoryScore(_mentalEvaluation);
    double weightedScore = _calculateWeightedScore();

    // Traduire les noms des critères pour l'affichage
    Map<String, String> criteriaLabels = {
      // Mental
      'motivation': 'Motivation',
      'concentration': 'Concentration',
      'desir_gagner': 'Désir de gagner',
      'esprit_equipe': 'Esprit d\'équipe',
      'force_caractere': 'Force de caractère',
      'sociabilite': 'Sociabilité',
      'intelligence': 'Intelligence de jeu',

      // Physique
      'taille': 'Taille',
      'poids': 'Poids/Gabarit',
      'rapidite': 'Rapidité',
      'endurance': 'Endurance',
      'vitesse_reaction': 'Vitesse de réaction',

      // Technique
      'conduite_pied_fort': 'Conduite pied fort',
      'conduite_pied_faible': 'Conduite pied faible',
      'passe_pied_fort': 'Passe pied fort',
      'passe_pied_faible': 'Passe pied faible',
      'passe_en_mouvement': 'Passe en mouvement',
      'controle_statique': 'Contrôle statique',
      'controle_oriente': 'Contrôle orienté',
      'jonglage_pied_fort': 'Jonglage pied fort',
      'jonglage_pied_faible': 'Jonglage pied faible',
      'jonglage_simultane': 'Jonglage simultané',
      'maitrise_ballon': 'Maîtrise du ballon',
      'tir_pied_fort': 'Tir pied fort',
      'tir_pied_faible': 'Tir pied faible',
      'tir_en_mouvement': 'Tir en mouvement',
      'jeu_de_tete': 'Jeu de tête',
      'dribble_1v1': 'Dribble 1v1',
      'defense_1v1': 'Défense 1v1',
      'controle_aerien': 'Contrôle aérien',
    };

    return TemplatePageBack(
      title: 'Évaluation - ${widget.playerName}',
      footerIndex: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _saveEvaluation,
          tooltip: 'Enregistrer l\'évaluation',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Informations du joueur
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _playerData != null &&
                                  _playerData!['imageUrl'] != null
                              ? NetworkImage(_playerData!['imageUrl'])
                              : null,
                          child: _playerData == null ||
                                  _playerData!['imageUrl'] == null
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.playerName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Groupe: ${widget.groupName}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_playerData != null &&
                                  _playerData!['birthDate'] != null)
                                Text(
                                  'Date de naissance: ${_formatDate(_playerData!['birthDate'])}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Score global
                Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blueGrey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.blueGrey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Column(
                      children: [
                        const Text(
                          'Score Global',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 12.0,
                          animation: true,
                          percent: weightedScore,
                          center: Text(
                            '${(weightedScore * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: _getColorForPercentage(weightedScore),
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildScoreIndicator(
                              'Technique',
                              technicalScore,
                              Colors.blue,
                              '${(_categoryWeights['technical']! * 100).toInt()}%',
                            ),
                            _buildScoreIndicator(
                              'Physique',
                              physicalScore,
                              Colors.green,
                              '${(_categoryWeights['physical']! * 100).toInt()}%',
                            ),
                            _buildScoreIndicator(
                              'Mental',
                              mentalScore,
                              Colors.orange,
                              '${(_categoryWeights['mental']! * 100).toInt()}%',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // TabBar pour navigation entre sections
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.sports_soccer),
                      text: 'Technique',
                    ),
                    Tab(
                      icon: Icon(Icons.fitness_center),
                      text: 'Physique',
                    ),
                    Tab(
                      icon: Icon(Icons.psychology),
                      text: 'Mental',
                    ),
                  ],
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 3,
                ),

                // TabBarView pour le contenu des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet Technique
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildScoreCard(
                              title: 'Évaluation Technique',
                              icon: Icons.sports_soccer,
                              color: Colors.blue,
                              score: technicalScore,
                              weight: _categoryWeights['technical']!,
                            ),
                            const SizedBox(height: 8),
                            ...(_technicalEvaluation.keys.toList()..sort())
                                .map((key) {
                              return _buildRatingRow(
                                criteriaLabels[key] ?? key.replaceAll('_', ' '),
                                _technicalEvaluation[key]!,
                                (value) => setState(
                                    () => _technicalEvaluation[key] = value),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Onglet Physique
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Onglet Technique
                            ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _technicalEvaluation.keys.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildScoreCard(
                                    title: 'Évaluation Technique',
                                    icon: Icons.sports_soccer,
                                    color: Colors.blue,
                                    score: technicalScore,
                                    weight: _categoryWeights['technical']!,
                                  );
                                }
                                final key = _technicalEvaluation.keys
                                    .toList()[index - 1];
                                return _buildRatingRow(
                                  criteriaLabels[key] ??
                                      key.replaceAll('_', ' '),
                                  _technicalEvaluation[key]!,
                                  (value) => setState(
                                      () => _technicalEvaluation[key] = value),
                                );
                              },
                            ),

                            // Onglet Physique
                            ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _physicalEvaluation.keys.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildScoreCard(
                                    title: 'Évaluation Physique',
                                    icon: Icons.fitness_center,
                                    color: Colors.green,
                                    score: physicalScore,
                                    weight: _categoryWeights['physical']!,
                                  );
                                }
                                final key = _physicalEvaluation.keys
                                    .toList()[index - 1];
                                return _buildRatingRow(
                                  criteriaLabels[key] ??
                                      key.replaceAll('_', ' '),
                                  _physicalEvaluation[key]!,
                                  (value) => setState(
                                      () => _physicalEvaluation[key] = value),
                                );
                              },
                            ),

                            // Onglet Mental
                            ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _mentalEvaluation.keys.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildScoreCard(
                                    title: 'Évaluation Mentale',
                                    icon: Icons.psychology,
                                    color: Colors.orange,
                                    score: mentalScore,
                                    weight: _categoryWeights['mental']!,
                                  );
                                }
                                final key =
                                    _mentalEvaluation.keys.toList()[index - 1];
                                return _buildRatingRow(
                                  criteriaLabels[key] ??
                                      key.replaceAll('_', ' '),
                                  _mentalEvaluation[key]!,
                                  (value) => setState(
                                      () => _mentalEvaluation[key] = value),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildScoreIndicator(
      String label, double score, Color color, String weight) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          width: 80.0,
          lineHeight: 8.0,
          percent: score,
          backgroundColor: Colors.grey.shade200,
          progressColor: color,
          barRadius: const Radius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          '${(score * 100).toStringAsFixed(1)}% (Poids: $weight)',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required String title,
    required IconData icon,
    required Color color,
    required double score,
    required double weight,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Score: ${(score * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 12.0,
              percent: score,
              backgroundColor: Colors.grey.shade200,
              progressColor: color,
              barRadius: const Radius.circular(6),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Poids dans l\'évaluation globale: ${(weight * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'Impact: ${(score * weight * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Non spécifiée';

    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Non spécifiée';
  }

  Color _getColorForPercentage(double percent) {
    if (percent < 0.3) return Colors.red;
    if (percent < 0.5) return Colors.orange;
    if (percent < 0.7) return Colors.amber;
    if (percent < 0.9) return Colors.green;
    return Colors.blue;
  }

  Widget _buildRatingRow(String label, int value, Function(int) onChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (value > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getColorForRating(value).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getColorForRating(value)),
                    ),
                    child: Text(
                      _getRatingLabel(value),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorForRating(value),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRatingButton('Faible', 1, value, onChanged),
                _buildRatingButton('Moyen', 2, value, onChanged),
                _buildRatingButton('Assez Bien', 3, value, onChanged),
                _buildRatingButton('Bien', 4, value, onChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButton(
      String label, int rating, int currentValue, Function(int) onChanged) {
    bool isSelected = currentValue == rating;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => onChanged(rating),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _getColorForRating(rating).withOpacity(0.2)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? _getColorForRating(rating)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getIconForRating(rating),
                  color: isSelected ? _getColorForRating(rating) : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? _getColorForRating(rating)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForRating(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber.shade700;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForRating(int rating) {
    switch (rating) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_satisfied;
      case 4:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.circle;
    }
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Faible';
      case 2:
        return 'Moyen';
      case 3:
        return 'Assez Bien';
      case 4:
        return 'Bien';
      default:
        return 'Non évalué';
    }
  }
}
