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
  String _selectedClass = '';
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
        setState(() {
          _students = result['students'] ?? [];
          _classes = [...{for (var s in _students) s['className']}.whereType<String>()];
          if (_classes.isNotEmpty) _selectedClass = _classes.first;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
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
    
    if (_selectedClass.isNotEmpty) {
      filtered = filtered.where((s) => s['className'] == _selectedClass).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((s) =>
        s['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
        s['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                Expanded(
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
                ),
                const SizedBox(width: 12),
                if (_classes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      underline: const SizedBox(),
                      items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) => setState(() => _selectedClass = value!),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Liste des élèves
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
                        itemCount: _getFilteredStudents().length,
                        itemBuilder: (context, index) {
                          final student = _getFilteredStudents()[index];
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
                                        student['fullName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF01579B),
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
                                                fontSize: 12,
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
                                  Text(student['email'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text('Classe: ${student['className'] ?? '-'}'),
                                  Text('Code enfant: ${student['childCode'] ?? '-'}'),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Parents:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...(student['parents'] as List? ?? []).map((p) => Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                                    child: Text('• $p'),
                                  )),
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