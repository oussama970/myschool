import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'admin_add_class_screen.dart';

/// Écran de gestion des classes pour l'administrateur
/// Permet de visualiser, ajouter, modifier et supprimer des classes
/// Permet également de gérer les élèves dans chaque classe
class AdminClassesScreen extends StatefulWidget {
  final String adminEmail;

  const AdminClassesScreen({super.key, required this.adminEmail});

  @override
  State<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends State<AdminClassesScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _classes = [];
  List<dynamic> _allStudents = [];

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadAllStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge la liste des classes depuis l'API
  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getClasses();
      
      if (result['success']) {
        setState(() {
          _classes = result['classes'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Charge la liste de tous les élèves depuis l'API
  Future<void> _loadAllStudents() async {
    try {
      final result = await ApiService.getAllStudents();
      
      if (result['success']) {
        setState(() {
          _allStudents = result['students'] ?? [];
        });
      }
    } catch (e) {
      print('Erreur chargement élèves: $e');
      setState(() {
        _allStudents = [];
      });
    }
  }

  // ==================== GESTION DES CLASSES ====================
  
  /// Supprime une classe après confirmation
  Future<void> _deleteClass(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cette classe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.deleteClass(id);
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Classe supprimée'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadClasses();
                _loadAllStudents();
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

  /// Affiche les détails d'une classe dans une boîte de dialogue
  void _showClassDetails(Map<String, dynamic> classe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${classe['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Année', classe['level'] ?? '-'),
            _buildDetailRow('Groupe', classe['group'] ?? '-'),
            _buildDetailRow('Effectif', '${classe['studentCount'] ?? 0}/${classe['capacity'] ?? 30}'),
            _buildDetailRow('Date création', _formatDate(classe['createdAt'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ==================== GESTION DES ÉLÈVES ====================
  
  /// Retire un élève d'une classe après confirmation
  Future<void> _removeStudentFromClass(String studentId, String studentName, String className) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment retirer $studentName de la classe $className ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              final result = await ApiService.removeStudentFromClass(
                studentId: studentId,
                className: className,
              );
              
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ $studentName retiré de la classe $className'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadClasses();
                await _loadAllStudents();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Erreur lors du retrait'),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() => _isLoading = false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RETIRER'),
          ),
        ],
      ),
    );
  }

  /// Ajoute des élèves sélectionnés à une classe
  Future<void> _addStudentsToClass(String className, List<String> studentIds) async {
    if (studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun élève sélectionné'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.addStudentsToClass(
        className: className,
        studentIds: studentIds,
      );
      
      if (result['success']) {
        await _loadClasses();
        await _loadAllStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${studentIds.length} élève(s) ajouté(s) à la classe'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Affiche une boîte de dialogue modale pour gérer les élèves d'une classe
  /// Permet d'ajouter des élèves (sans classe) et de retirer des élèves existants
  void _showManageStudentsDialog(Map<String, dynamic> classe) {
    final String className = classe['name'];
    final List<String> currentStudentIds = (classe['students'] as List?)?.map((s) => s.toString()).toList() ?? [];
    
    // Élèves déjà dans cette classe
    List<dynamic> studentsInClass = _allStudents.where((student) {
      return currentStudentIds.contains(student['_id'].toString());
    }).toList();
    
    // Filtrer les élèves disponibles (sans classe)
    List<dynamic> availableStudents = _allStudents.where((student) {
      String studentClass = student['className'] ?? '';
      return (studentClass.isEmpty || studentClass == null || studentClass == '') && 
             !currentStudentIds.contains(student['_id'].toString());
    }).toList();
    
    List<String> selectedStudentIds = List.from(currentStudentIds);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Poignée de fermeture
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Titre
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Gérer les élèves - ${classe['name']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Statistiques
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0288D1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${studentsInClass.length} élèves dans la classe',
                              style: const TextStyle(
                                color: Color(0xFF0288D1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                selectedStudentIds.clear();
                                selectedStudentIds.addAll(currentStudentIds);
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Réinitialiser'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Liste des élèves
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section: Élèves déjà dans la classe
                            if (studentsInClass.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(
                                  '📌 Élèves dans cette classe',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0288D1),
                                  ),
                                ),
                              ),
                              ...studentsInClass.map((student) => Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                                    child: Text(
                                      (student['fullName']?.substring(0, 1) ?? '?').toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF0288D1),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    student['fullName'] ?? 'Sans nom',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(student['email'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeStudentFromClass(
                                      student['_id'],
                                      student['fullName'],
                                      className,
                                    ),
                                    tooltip: 'Retirer de la classe',
                                  ),
                                ),
                              )),
                              const Divider(),
                            ],
                            
                            // Section: Ajouter des élèves
                            if (availableStudents.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(
                                  '➕ Ajouter des élèves',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF9F),
                                  ),
                                ),
                              ),
                              ...availableStudents.map((student) => CheckboxListTile(
                                value: selectedStudentIds.contains(student['_id'].toString()),
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      selectedStudentIds.add(student['_id'].toString());
                                    } else {
                                      selectedStudentIds.remove(student['_id'].toString());
                                    }
                                  });
                                },
                                title: Text(
                                  student['fullName'] ?? 'Sans nom',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(student['email'] ?? ''),
                                secondary: const Icon(Icons.person_add, color: Color(0xFF4CAF9F)),
                                controlAffinity: ListTileControlAffinity.leading,
                              )),
                            ],
                            
                            if (availableStudents.isEmpty && studentsInClass.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: Text(
                                    'Aucun élève disponible',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                              
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                    // Boutons d'action
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side: const BorderSide(color: Colors.grey),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text('ANNULER'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _addStudentsToClass(className, selectedStudentIds);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text('VALIDER'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ==================== MÉTHODES UTILITAIRES ====================
  
  /// Formate une date pour l'affichage
  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }

  /// Construit une ligne de détail (label + valeur) pour les dialogues
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Filtre les classes selon le terme de recherche
  List<dynamic> _getFilteredClasses() {
    if (_searchController.text.isEmpty) return _classes;
    return _classes.where((c) =>
      c['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête avec titre et bouton d'ajout
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🏫 CLASSES',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01579B),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminAddClassScreen(
                          adminEmail: widget.adminEmail,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadClasses();
                      _loadAllStudents();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle classe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
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
                  hintText: '🔍 Rechercher une classe...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Liste des classes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredClasses().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.class_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune classe trouvée',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredClasses().length,
                        itemBuilder: (context, index) {
                          final classe = _getFilteredClasses()[index];
                          int effectif = classe['studentCount'] ?? 0;
                          int capacite = classe['capacity'] ?? 30;
                          
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
                                  // En-tête de la carte avec nom et boutons d'action
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        classe['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF01579B),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Bouton Détails
                                          IconButton(
                                            icon: const Icon(
                                              Icons.visibility,
                                              color: Color(0xFF0288D1),
                                            ),
                                            onPressed: () => _showClassDetails(classe),
                                            tooltip: 'Détails',
                                          ),
                                          // Bouton Gérer les élèves
                                          IconButton(
                                            icon: const Icon(
                                              Icons.people,
                                              color: Color(0xFF0288D1),
                                            ),
                                            onPressed: () => _showManageStudentsDialog(classe),
                                            tooltip: 'Gérer les élèves',
                                          ),
                                          // Bouton Supprimer la classe
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteClass(classe['_id']),
                                            tooltip: 'Supprimer la classe',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Niveau: ${classe['level'] ?? '-'} ${classe['group'] ?? '-'}'),
                                  const SizedBox(height: 8),
                                  // Barre de progression de l'effectif
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Effectif: $effectif/$capacite'),
                                            const SizedBox(height: 4),
                                            LinearProgressIndicator(
                                              value: effectif / capacite,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                effectif == capacite ? Colors.red : const Color(0xFF0288D1),
                                              ),
                                              minHeight: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}