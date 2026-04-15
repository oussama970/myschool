import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class AdminAddTeacherScreen extends StatefulWidget {
  final String adminEmail;

  const AdminAddTeacherScreen({super.key, required this.adminEmail});

  @override
  State<AdminAddTeacherScreen> createState() => _AdminAddTeacherScreenState();
}

class _AdminAddTeacherScreenState extends State<AdminAddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  
  // Matières d'école primaire tunisienne
  final Map<String, bool> _subjects = {
    'Mathématiques': false,
    'Français': false,
    'Arabe': false,
    'Anglais': false,
    'Sciences': false,
    'Éducation islamique': false,
    'Histoire-Géographie': false,
    'Technologie': false,
    'Dessin': false,
    'Musique': false,
    'Sport': false,
  };

  // Changé: Classes au format "1ère année A", "1ère année B", etc.
  final List<String> _availableClasses = [
    '1ère année A', '1ère année B', 
    '2ème année A', '2ème année B', 
    '3ème année A', '3ème année B', 
    '4ème année A', '4ème année B', 
    '5ème année A', '5ème année B', 
    '6ème année A', '6ème année B'
  ];
  
  Map<String, bool> _selectedClasses = {};

  @override
  void initState() {
    super.initState();
    _selectedClasses = {for (var c in _availableClasses) c: false};
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String password = '';
    for (int i = 0; i < 10; i++) {
      password += chars[DateTime.now().microsecond % chars.length];
    }
    return password;
  }

  Future<void> _handleAddTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    List<String> selectedSubjects = _subjects.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    List<String> selectedClasses = _selectedClasses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    try {
      final result = await ApiService.addTeacher(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _generateRandomPassword(),
        phoneNumber: _phoneController.text.trim(),
        subjects: selectedSubjects,
        classes: selectedClasses,
      );

      if (result['success']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Succès'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enseignant ajouté avec succès !'),
                  const SizedBox(height: 8),
                  Text('Email: ${_emailController.text}'),
                  const Text('Un email a été envoyé avec les identifiants.'),
                ],
              ),
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
              'Ajouter Enseignant',
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
                          // Titre
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0288D1).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 35,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ajouter un enseignant',
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
                          
                          // Nom complet
                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Nom complet *',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le nom est requis';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email *',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'L\'email est requis';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Téléphone
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Téléphone (optionnel)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Matières enseignées
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Matières enseignées',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF01579B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _subjects.keys.map((subject) {
                                    return FilterChip(
                                      label: Text(
                                        subject,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _subjects[subject]! 
                                              ? const Color(0xFF0288D1)
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      selected: _subjects[subject]!,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          _subjects[subject] = selected;
                                        });
                                      },
                                      backgroundColor: Colors.grey.shade100,
                                      selectedColor: const Color(0xFF0288D1).withOpacity(0.1),
                                      checkmarkColor: const Color(0xFF0288D1),
                                      side: BorderSide(
                                        color: _subjects[subject]! 
                                            ? const Color(0xFF0288D1) 
                                            : Colors.grey.shade300,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Classes assignées
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Classes assignées',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF01579B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _availableClasses.map((className) {
                                    return FilterChip(
                                      label: Text(
                                        className,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _selectedClasses[className]! 
                                              ? const Color(0xFF4CAF9F)
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      selected: _selectedClasses[className]!,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          _selectedClasses[className] = selected;
                                        });
                                      },
                                      backgroundColor: Colors.grey.shade100,
                                      selectedColor: const Color(0xFF4CAF9F).withOpacity(0.1),
                                      checkmarkColor: const Color(0xFF4CAF9F),
                                      side: BorderSide(
                                        color: _selectedClasses[className]! 
                                            ? const Color(0xFF4CAF9F) 
                                            : Colors.grey.shade300,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Bouton d'ajout
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0288D1).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAddTeacher,
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
                                      'AJOUTER L\'ENSEIGNANT',
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
    String? Function(String?)? validator,
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
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF01579B)),
          prefixIcon: Icon(icon, color: const Color(0xFF0288D1)),
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
}