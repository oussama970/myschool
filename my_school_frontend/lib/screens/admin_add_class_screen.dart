import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class AdminAddClassScreen extends StatefulWidget {
  final String adminEmail;

  const AdminAddClassScreen({super.key, required this.adminEmail});

  @override
  State<AdminAddClassScreen> createState() => _AdminAddClassScreenState();
}

class _AdminAddClassScreenState extends State<AdminAddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();
  final _roomController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedLevel;
  String? _selectedGroup;
  String? _selectedTeacher;

  // Niveaux de l'école primaire tunisienne
  final List<String> _levels = [
    '1ère année', 
    '2ème année', 
    '3ème année', 
    '4ème année', 
    '5ème année', 
    '6ème année'
  ];
  
  final List<String> _groups = ['A', 'B', 'C', 'D'];
  List<String> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final result = await ApiService.getTeachersList();
      
      if (result['success']) {
        setState(() {
          _teachers = List<String>.from(result['teachers'] ?? []);
        });
      }
    } catch (e) {
      print('Erreur chargement enseignants: $e');
    }
  }

  String? _getClassName() {
    if (_selectedLevel != null && _selectedGroup != null) {
      return '$_selectedLevel $_selectedGroup';
    }
    return null;
  }

  Future<void> _addClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.addClass(
        level: _selectedLevel!,
        group: _selectedGroup!,
        className: '$_selectedLevel $_selectedGroup',
        teacher: _selectedTeacher!,
        capacity: int.tryParse(_capacityController.text) ?? 30,
        room: _roomController.text.trim(),
      );

      if (result['success']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Succès'),
              content: const Text('Classe ajoutée avec succès'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: const Text('OK'),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    String? className = _getClassName();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF0288D1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ajouter une classe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0288D1).withOpacity(0.05),
                  const Color(0xFF4FC3F7).withOpacity(0.05),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône et titre
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4CAF9F), Color(0xFF66BB6A)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF9F).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_box,
                                    color: Colors.white,
                                    size: 35,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ajouter une classe',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF01579B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Année
                          _buildDropdown(
                            label: 'Année *',
                            value: _selectedLevel,
                            items: _levels,
                            onChanged: (value) => setState(() => _selectedLevel = value),
                            validator: (value) => value == null ? 'L\'année est requise' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Groupe
                          _buildDropdown(
                            label: 'Groupe *',
                            value: _selectedGroup,
                            items: _groups,
                            onChanged: (value) => setState(() => _selectedGroup = value),
                            validator: (value) => value == null ? 'Le groupe est requis' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Nom de la classe (aperçu)
                          if (className != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF9F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF4CAF9F)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.class_, color: Color(0xFF4CAF9F)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      className,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Enseignant principal
                          _buildDropdown(
                            label: 'Enseignant principal *',
                            value: _selectedTeacher,
                            items: _teachers,
                            onChanged: (value) => setState(() => _selectedTeacher = value),
                            validator: (value) => value == null ? 'L\'enseignant est requis' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Capacité maximale
                          _buildTextField(
                            controller: _capacityController,
                            label: 'Capacité maximale',
                            icon: Icons.people,
                            keyboardType: TextInputType.number,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Salle
                          _buildTextField(
                            controller: _roomController,
                            label: 'Salle',
                            icon: Icons.meeting_room,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Bouton d'ajout
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF9F), Color(0xFF66BB6A)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF9F).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: (_selectedLevel != null && _selectedGroup != null && _selectedTeacher != null && !_isLoading) 
                                  ? _addClass 
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'AJOUTER LA CLASSE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Lien retour
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                              ),
                              child: const Text('Retour'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF01579B)),
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF9F)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF01579B)),
          border: InputBorder.none,
        ),
        hint: Text('Sélectionner ${label.toLowerCase()}'),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
      ),
    );
  }
}