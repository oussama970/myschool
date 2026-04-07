import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'teacher_student_detail_screen.dart';

class TeacherClassScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;

  const TeacherClassScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
  });

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _students = [];
  List<dynamic> _allStudents = [];
  List<String> _selectedStudentIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadStudents();
    await _loadAllStudents();
    setState(() => _isLoading = false);
  }

  Future<void> _loadStudents() async {
    try {
      final result = await ApiService.getStudentsByClass(widget.className);
      
      if (result['success']) {
        setState(() {
          _students = result['students'] ?? [];
        });
      } else {
        _loadMockStudents();
      }
    } catch (e) {
      _loadMockStudents();
    }
  }

  Future<void> _loadAllStudents() async {
    try {
      final result = await ApiService.getAllStudents();
      
      if (result['success']) {
        setState(() {
          _allStudents = result['students'] ?? [];
        });
      } else {
        _loadMockAllStudents();
      }
    } catch (e) {
      _loadMockAllStudents();
    }
  }

  void _loadMockStudents() {
    setState(() {
      _students = [
        {
          '_id': '1',
          'fullName': 'Chloé Dupont',
          'email': 'chloe.d@ecole.fr',
          'parentEmail': 'sophie.dupont@email.com',
          'className': widget.className,
        },
        {
          '_id': '2',
          'fullName': 'Léo Martin',
          'email': 'leo.m@ecole.fr',
          'parentEmail': 'marc.martin@email.com',
          'className': widget.className,
        },
        {
          '_id': '3',
          'fullName': 'Emma Bernard',
          'email': 'emma.b@ecole.fr',
          'parentEmail': 'julie.bernard@email.com',
          'className': widget.className,
        },
      ];
    });
  }

  void _loadMockAllStudents() {
    setState(() {
      _allStudents = [
        {'_id': '1', 'fullName': 'Chloé Dupont', 'email': 'chloe.d@ecole.fr', 'className': widget.className, 'parentEmail': 'sophie.dupont@email.com'},
        {'_id': '2', 'fullName': 'Léo Martin', 'email': 'leo.m@ecole.fr', 'className': widget.className, 'parentEmail': 'marc.martin@email.com'},
        {'_id': '3', 'fullName': 'Emma Bernard', 'email': 'emma.b@ecole.fr', 'className': widget.className, 'parentEmail': 'julie.bernard@email.com'},
        {'_id': '4', 'fullName': 'Paul Petit', 'email': 'paul.p@ecole.fr', 'className': 'CM1 A', 'parentEmail': 'claire.petit@email.com'},
        {'_id': '5', 'fullName': 'Lucas Moreau', 'email': 'lucas.m@ecole.fr', 'className': '6ème B', 'parentEmail': 'sophie.moreau@email.com'},
        {'_id': '6', 'fullName': 'Tom Chen', 'email': 'tom.c@ecole.fr', 'className': '', 'parentEmail': 'li.chen@email.com'},
        {'_id': '7', 'fullName': 'Julie Robert', 'email': 'julie.r@ecole.fr', 'className': 'CM2 B', 'parentEmail': 'pierre.robert@email.com'},
        {'_id': '8', 'fullName': 'Sophie Martin', 'email': 'sophie.m@ecole.fr', 'className': '', 'parentEmail': 'jean.martin@email.com'},
      ];
    });
  }

  void _showAddStudentsDialog() {
    List<String> tempSelectedIds = List.from(_students.map((s) => s['_id'].toString()));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableStudents = _allStudents.where((s) => 
              s['className'] == '' || s['className'] == widget.className
            ).toList();
            
            final studentsInClass = availableStudents.where((s) => 
              tempSelectedIds.contains(s['_id'].toString())
            ).toList();
            
            final studentsNotInClass = availableStudents.where((s) => 
              !tempSelectedIds.contains(s['_id'].toString())
            ).toList();
            
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
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '➕ AJOUTER DES ÉLÈVES',
                        style: TextStyle(
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
                              '${tempSelectedIds.length} élèves sélectionnés',
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
                                tempSelectedIds = List.from(_students.map((s) => s['_id'].toString()));
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
                                  '📌 Élèves déjà dans la classe',
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
                                      tempSelectedIds.remove(student['_id'].toString());
                                    }
                                  });
                                },
                                title: Text(
                                  student['fullName'],
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(student['email']),
                                secondary: const Icon(Icons.check_circle, color: Color(0xFF4CAF9F)),
                                controlAffinity: ListTileControlAffinity.leading,
                              )),
                              const Divider(),
                            ],
                            
                            if (studentsNotInClass.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(
                                  '➕ Élèves disponibles',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0288D1),
                                  ),
                                ),
                              ),
                              ...studentsNotInClass.map((student) => CheckboxListTile(
                                value: tempSelectedIds.contains(student['_id'].toString()),
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      tempSelectedIds.add(student['_id'].toString());
                                    } else {
                                      tempSelectedIds.remove(student['_id'].toString());
                                    }
                                  });
                                },
                                title: Text(
                                  student['fullName'],
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(student['email']),
                                secondary: Icon(
                                  student['className'].isEmpty 
                                      ? Icons.person_add 
                                      : Icons.block,
                                  color: student['className'].isEmpty 
                                      ? const Color(0xFF0288D1) 
                                      : Colors.grey,
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                              )),
                            ],
                            
                            if (studentsNotInClass.isEmpty && studentsInClass.isEmpty)
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
                                _addStudentsToClass(tempSelectedIds);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text('AJOUTER'),
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

  Future<void> _addStudentsToClass(List<String> studentIds) async {
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
        className: widget.className,
        studentIds: studentIds,
      );
      
      if (result['success']) {
        await _loadStudents();
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
      final newStudents = _allStudents.where((s) => 
        studentIds.contains(s['_id'].toString())
      ).map((s) => ({
        '_id': s['_id'],
        'fullName': s['fullName'],
        'email': s['email'],
        'parentEmail': s['parentEmail'] ?? '-',
        'className': widget.className,
      })).toList();
      
      setState(() {
        _students = newStudents;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${studentIds.length} élève(s) ajouté(s) à la classe (mode démo)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeStudent(String studentId, String studentName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'élève'),
        content: Text('Voulez-vous vraiment retirer $studentName de cette classe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                final result = await ApiService.removeStudentFromClass(
                  studentId: studentId,
                  className: widget.className,
                );
                
                if (result['success']) {
                  await _loadStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ $studentName a été retiré de la classe'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else {
                  throw Exception(result['message']);
                }
              } catch (e) {
                setState(() {
                  _students.removeWhere((s) => s['_id'] == studentId);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ $studentName a été retiré de la classe (mode démo)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
              
              if (mounted) {
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

  List<dynamic> _getFilteredStudents() {
    if (_searchController.text.isEmpty) return _students;
    return _students.where((s) =>
      s['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
      s['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
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
                Flexible(
                  child: Text(
                    '👥 MA CLASSE - ${widget.className} (${_students.length} élèves)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Color(0xFF0288D1)),
                  onPressed: _showAddStudentsDialog,
                  tooltip: 'Ajouter des élèves',
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

          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredStudents().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun élève dans cette classe',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddStudentsDialog,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Ajouter des élèves'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
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
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeacherStudentDetailScreen(
                                      student: student,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF0288D1),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['fullName'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            student['email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Parent: ${student['parentEmail'] ?? '-'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () => _removeStudent(student['_id'], student['fullName']),
                                      tooltip: 'Retirer de la classe',
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
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