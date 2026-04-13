import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'admin_add_class_screen.dart';

class AdminClassesScreen extends StatefulWidget {
  final String adminEmail;

  const AdminClassesScreen({super.key, required this.adminEmail});

  @override
  State<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends State<AdminClassesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _classes = [];
  List<dynamic> _allStudents = [];

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

  void _showAddStudentsDialog(Map<String, dynamic> classe) {
    final String className = classe['name'];
    final List<String> currentStudentIds = (classe['students'] as List?)?.map((s) => s.toString()).toList() ?? [];
    
    // Filtrer les élèves disponibles (sans classe)
    List<dynamic> availableStudents = _allStudents.where((student) {
      String studentClass = student['className'] ?? '';
      return studentClass.isEmpty || studentClass == null || studentClass == '';
    }).toList();
    
    // Élèves déjà dans cette classe
    List<dynamic> studentsInClass = _allStudents.where((student) {
      return currentStudentIds.contains(student['_id'].toString());
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Ajouter des élèves - ${classe['name']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                              '${selectedStudentIds.length} élèves dans la classe',
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
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (studentsInClass.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(
                                  '📌 Élèves déjà dans cette classe',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF9F),
                                  ),
                                ),
                              ),
                              ...studentsInClass.map((student) => CheckboxListTile(
                                value: true,
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == false) {
                                      selectedStudentIds.remove(student['_id'].toString());
                                    }
                                  });
                                },
                                title: Text(
                                  student['fullName'] ?? 'Sans nom',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(student['email'] ?? ''),
                                secondary: const Icon(Icons.check_circle, color: Color(0xFF4CAF9F)),
                                controlAffinity: ListTileControlAffinity.leading,
                              )),
                              const Divider(),
                            ],
                            
                            if (availableStudents.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(
                                  '➕ Élèves disponibles (sans classe)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0288D1),
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
                                secondary: const Icon(Icons.person_add, color: Color(0xFF0288D1)),
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

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }

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

  List<dynamic> _getFilteredClasses() {
    if (_searchController.text.isEmpty) return _classes;
    return _classes.where((c) =>
      c['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
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
                                          IconButton(
                                            icon: const Icon(
                                              Icons.visibility,
                                              color: Color(0xFF0288D1),
                                            ),
                                            onPressed: () => _showClassDetails(classe),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.person_add,
                                              color: Color(0xFF4CAF9F),
                                            ),
                                            onPressed: () => _showAddStudentsDialog(classe),
                                            tooltip: 'Ajouter des élèves',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteClass(classe['_id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Niveau: ${classe['level'] ?? '-'} ${classe['group'] ?? '-'}'),
                                  const SizedBox(height: 8),
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