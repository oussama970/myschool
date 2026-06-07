import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

/// Écran de gestion des élèves pour l'administrateur
/// Permet de visualiser la liste des élèves par classe,
/// de filtrer par classe ou par recherche, et de supprimer un élève
class AdminStudentsScreen extends StatefulWidget {
  final String adminEmail;

  const AdminStudentsScreen({super.key, required this.adminEmail});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final TextEditingController _searchController = TextEditingController();
  String _selectedClass = 'Toutes les classes';
  bool _isLoading = true;
  List<dynamic> _students = [];
  List<String> _classes = [];

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge la liste des élèves depuis l'API
  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getStudents();
      
      if (result['success']) {
        final students = result['students'] ?? [];
        
        // Extraire les classes uniques pour le filtre
        Set<String> uniqueClasses = {'Toutes les classes'};
        for (var student in students) {
          String className = student['className'] ?? 'Sans classe';
          if (className.isNotEmpty) {
            uniqueClasses.add(className);
          } else {
            uniqueClasses.add('Sans classe');
          }
        }
        
        setState(() {
          _students = students;
          _classes = uniqueClasses.toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement élèves: $e');
      setState(() => _isLoading = false);
    }
  }

  // ==================== GESTION DES ÉLÈVES ====================
  
  /// Supprime un élève après confirmation
  Future<void> _deleteStudent(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cet élève ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.deleteStudent(id);
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Élève supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadStudents();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ==================== MÉTHODES DE FILTRAGE ====================
  
  /// Filtre les élèves selon la classe sélectionnée et le terme de recherche
  List<dynamic> _getFilteredStudents() {
    var filtered = _students;
    
    // Filtrer par classe
    if (_selectedClass != 'Toutes les classes') {
      if (_selectedClass == 'Sans classe') {
        filtered = filtered.where((s) => s['className'] == null || s['className'] == '').toList();
      } else {
        filtered = filtered.where((s) => s['className'] == _selectedClass).toList();
      }
    }
    
    // Filtrer par recherche
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((s) =>
        s['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
        s['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  /// Groupe les élèves par classe pour l'affichage
  Map<String, List<dynamic>> _getStudentsByClass() {
    Map<String, List<dynamic>> grouped = {};
    for (var student in _getFilteredStudents()) {
      String className = student['className'] ?? 'Sans classe';
      if (className.isEmpty) className = 'Sans classe';
      if (!grouped.containsKey(className)) {
        grouped[className] = [];
      }
      grouped[className]!.add(student);
    }
    return grouped;
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    final groupedStudents = _getStudentsByClass();
    final classNames = groupedStudents.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Titre
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '🧑‍🎓 ÉLÈVES',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF01579B),
              ),
            ),
          ),

          // Barre de recherche et filtre
          _buildSearchAndFilter(),

          const SizedBox(height: 20),

          // Liste des élèves par classe
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredStudents().isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: classNames.length,
                        itemBuilder: (context, index) {
                          final className = classNames[index];
                          final students = groupedStudents[className] ?? [];
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête de classe
                              _buildClassHeader(className, students.length),
                              // Cartes des élèves
                              ...students.map((student) => _buildStudentCard(student)),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Construit la barre de recherche et les filtres
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Champ de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: '🔍 Rechercher un élève...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtres par classe
          if (_classes.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _classes.map((className) => _buildClassFilterChip(className)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Construit un chip de filtre par classe
  Widget _buildClassFilterChip(String className) {
    final isSelected = _selectedClass == className;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(className),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedClass = className;
          });
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: const Color(0xFF0288D1).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF0288D1) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: const Color(0xFF0288D1),
      ),
    );
  }

  /// Affiche l'état vide (aucun élève trouvé)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun élève trouvé',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête d'une section de classe
  Widget _buildClassHeader(String className, int studentCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0288D1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '📚 $className ($studentCount élèves)',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Construit la carte d'un élève
  Widget _buildStudentCard(dynamic student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : nom et actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    student['fullName'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Badge de vérification
                    _buildVerificationBadge(student['isVerified'] == true),
                    // Bouton suppression
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteStudent(student['_id']),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              student['email'] ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Code enfant
            Row(
              children: [
                const Icon(Icons.code, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Code: ${student['childCode'] ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Parents liés
            const Text(
              '👪 Parents liés:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ..._buildParentsList(student),
          ],
        ),
      ),
    );
  }

  /// Construit le badge de vérification (Vérifié / En attente)
  Widget _buildVerificationBadge(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isVerified ? 'Vérifié' : 'En attente',
        style: TextStyle(
          color: isVerified ? Colors.green : Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Construit la liste des parents liés à un élève
  List<Widget> _buildParentsList(dynamic student) {
    final parents = student['linkedParents'] as List?;
    
    if (parents == null || parents.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            'Aucun parent lié',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ];
    }
    
    return parents.map((p) => Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.person, size: 12, color: Color(0xFF4CAF9F)),
          const SizedBox(width: 4),
          Expanded(child: Text(p, style: const TextStyle(fontSize: 12))),
        ],
      ),
    )).toList();
  }
}