import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

/// Écran d'ajout d'un enseignant par l'administrateur
/// Permet de créer un compte enseignant avec matière et classes assignées
class AdminAddTeacherScreen extends StatefulWidget {
  final String adminEmail;

  const AdminAddTeacherScreen({super.key, required this.adminEmail});

  @override
  State<AdminAddTeacherScreen> createState() => _AdminAddTeacherScreenState();
}

class _AdminAddTeacherScreenState extends State<AdminAddTeacherScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  
  // ==================== LISTES DES DONNÉES ====================
  
  /// Liste des matières enseignables (école primaire)
  final List<String> _subjects = [
    'Maths', 'Français', 'Arabe', 'Anglais', 'Sciences', 
    'Islamique', 'Dessin', 'Musique', 'Sport', 'Informatique'
  ];
  
  /// Matière sélectionnée (l'enseignant ne peut enseigner qu'une seule matière)
  String? _selectedSubject;

  /// Liste des classes disponibles
  final List<String> _availableClasses = [
    '1ère année A', '1ère année B', 
    '2ème année A', '2ème année B', 
    '3ème année A', '3ème année B', 
    '4ème année A', '4ème année B', 
    '5ème année A', '5ème année B', 
    '6ème année A', '6ème année B'
  ];
  
  /// Map des classes sélectionnées (true = sélectionné, false = non sélectionné)
  Map<String, bool> _selectedClasses = {};

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    // Initialiser toutes les classes comme non sélectionnées
    _selectedClasses = {for (var c in _availableClasses) c: false};
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ==================== MÉTHODES UTILITAIRES ====================
  
  /// Génère un mot de passe aléatoire de 10 caractères
  /// Composé de lettres majuscules, minuscules et chiffres
  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String password = '';
    for (int i = 0; i < 10; i++) {
      password += chars[DateTime.now().microsecond % chars.length];
    }
    return password;
  }

  /// Affiche un message SnackBar à l'écran
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: color, 
        duration: const Duration(seconds: 2)
      )
    );
  }

  // ==================== CRÉATION DE L'ENSEIGNANT ====================
  
  /// Valide le formulaire et ajoute un nouvel enseignant
  Future<void> _handleAddTeacher() async {
    // Vérifier la validité du formulaire
    if (!_formKey.currentState!.validate()) return;
    
    // Vérifier qu'une matière est sélectionnée
    if (_selectedSubject == null) {
      _showSnackBar('Veuillez sélectionner une matière', Colors.orange);
      return;
    }
    
    setState(() => _isLoading = true);

    // Récupérer la liste des classes sélectionnées
    List<String> selectedClasses = _selectedClasses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    try {
      // Appel API pour ajouter l'enseignant
      final result = await ApiService.addTeacher(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _generateRandomPassword(),
        phoneNumber: _phoneController.text.trim(),
        subjects: [_selectedSubject!], // Une seule matière dans une liste
        classes: selectedClasses,
      );

      if (result['success']) {
        if (mounted) {
          // Afficher la boîte de dialogue de succès
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
                  Text('Matière: $_selectedSubject'),
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
        _showSnackBar('❌ Erreur: $e', Colors.red);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== BUILD UI ====================
  
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
          // Arrière-plan décoratif
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
                          // En-tête avec icône
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
                          
                          // Champ Nom complet
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
                          
                          // Champ Email
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
                          
                          // Champ Téléphone (optionnel)
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Téléphone (optionnel)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Sélection de la matière (une seule)
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
                                  'Matière enseignée *',
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
                                  children: _subjects.map((subject) {
                                    final isSelected = _selectedSubject == subject;
                                    return FilterChip(
                                      label: Text(
                                        subject,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected 
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          _selectedSubject = selected ? subject : null;
                                        });
                                      },
                                      backgroundColor: Colors.grey.shade100,
                                      selectedColor: const Color(0xFF0288D1),
                                      checkmarkColor: Colors.white,
                                      side: BorderSide(
                                        color: isSelected 
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
                          
                          // Sélection des classes (multiples)
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

  // ==================== WIDGETS RÉUTILISABLES ====================
  
  /// Construit un champ de texte stylisé avec validation
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