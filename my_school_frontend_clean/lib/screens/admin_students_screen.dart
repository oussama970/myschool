import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  final String adminEmail;

  const AdminStudentsScreen({super.key, required this.adminEmail});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedClass = 'Toutes les classes';
  bool _isLoading = true;
  List<dynamic> _students = [];
  List<String> _classes = [];

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

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getStudents();
      
      if (result['success']) {
        final students = result['students'] ?? [];
        
        // Extraire les classes uniques
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

  List<dynamic> _getFilteredStudents() {
    var filtered = _students;
    
    if (_selectedClass != 'Toutes les classes') {
      if (_selectedClass == 'Sans classe') {
        filtered = filtered.where((s) => s['className'] == null || s['className'] == '').toList();
      } else {
        filtered = filtered.where((s) => s['className'] == _selectedClass).toList();
      }
    }
    
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((s) =>
        s['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
        s['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  // Grouper les élèves par classe
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

  @override
  Widget build(BuildContext context) {
    final groupedStudents = _getStudentsByClass();
    final classNames = groupedStudents.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
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
                if (_classes.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _classes.map((className) {
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
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Liste des élèves par classe
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredStudents().isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: classNames.length,
                        itemBuilder: (context, index) {
                          final className = classNames[index];
                          final students = groupedStudents[className] ?? [];
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0288D1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '📚 $className (${students.length} élèves)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              ...students.map((student) => Card(
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
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: student['isVerified'] == true
                                                      ? Colors.green.withOpacity(0.1)
                                                      : Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  student['isVerified'] == true ? 'Vérifié' : 'En attente',
                                                  style: TextStyle(
                                                    color: student['isVerified'] == true
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
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
                                      Text(
                                        student['email'] ?? '',
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
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
                              )),
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