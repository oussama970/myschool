import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/user_role.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';
import 'parent_first_link_screen.dart';

/// Écran d'inscription pour les nouveaux utilisateurs
/// Permet aux élèves et aux parents de créer un compte
/// Gère la validation des champs et la redirection appropriée
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  UserRole? _selectedRole;
  bool _acceptTerms = false;
  bool _isLoading = false;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==================== INSCRIPTION ====================
  
  /// Gère l'inscription de l'utilisateur
  Future<void> _handleRegister() async {
    // Validation du formulaire
    if (!_formKey.currentState!.validate()) return;
    
    // Validation du rôle
    if (_selectedRole == null) {
      _showErrorSnackBar('Veuillez sélectionner votre rôle');
      return;
    }
    
    // Validation des conditions
    if (!_acceptTerms) {
      _showErrorSnackBar('Veuillez accepter les conditions');
      return;
    }
    
    setState(() => _isLoading = true);

    // Appel API pour l'inscription
    final result = await ApiService.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
      role: _selectedRole == UserRole.student ? 'student' : 'parent',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      await _handleRegistrationSuccess(result);
    } else {
      _showErrorSnackBar(result['message']);
    }
  }

  /// Gère la redirection après une inscription réussie
  Future<void> _handleRegistrationSuccess(Map<String, dynamic> result) async {
    // Vérification que le token est sauvegardé
    final token = await ApiService.getToken();
    print('🔑 Token après inscription: ${token != null}');
    
    // Message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['data']['message']),
        backgroundColor: Colors.green,
      ),
    );

    if (_selectedRole == UserRole.student) {
      // Élève : va vers vérification email
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: result['data']['user']['email'],
          ),
        ),
      );
    } else {
      // Parent : va vers la page pour lier son enfant
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParentFirstLinkScreen(
            parentEmail: result['data']['user']['email'],
            parentName: result['data']['user']['fullName'],
          ),
        ),
      );
    }
  }

  /// Affiche un message d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE57373),
      ),
    );
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0288D1),
              Color(0xFF4FC3F7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      _buildLogo(),
                      
                      const SizedBox(height: 16),
                      
                      // Titre
                      const Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sous-titre
                      const Text(
                        'Rejoignez notre communauté éducative',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Formulaire
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Sélection du rôle
                            _buildRoleSelector(),
                            
                            const SizedBox(height: 20),
                            
                            // Nom complet
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Nom complet',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.name,
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
                              label: 'Adresse email',
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
                            
                            // Mot de passe
                            _buildPasswordField(),
                            
                            const SizedBox(height: 8),
                            
                            // Confirmation mot de passe
                            _buildConfirmPasswordField(),
                            
                            const SizedBox(height: 20),
                            
                            // Conditions d'utilisation
                            _buildTermsCheckbox(),
                            
                            const SizedBox(height: 24),
                            
                            // Bouton d'inscription
                            _buildRegisterButton(),
                            
                            const SizedBox(height: 16),
                            
                            // Lien vers connexion
                            _buildLoginLink(),
                          ],
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
    );
  }

  /// Construit le logo de l'application
  Widget _buildLogo() {
    return Container(
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
    );
  }

  /// Construit le sélecteur de rôle
  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vous êtes :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF01579B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  title: 'Élève',
                  icon: Icons.school,
                  color: const Color(0xFF0288D1),
                  isSelected: _selectedRole == UserRole.student,
                  onTap: () => setState(() => _selectedRole = UserRole.student),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleCard(
                  title: 'Parent',
                  icon: Icons.family_restroom,
                  color: const Color(0xFF4FC3F7),
                  isSelected: _selectedRole == UserRole.parent,
                  onTap: () => setState(() => _selectedRole = UserRole.parent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une carte de sélection de rôle
  Widget _buildRoleCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le champ de mot de passe
  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      label: 'Mot de passe',
      icon: Icons.lock_outline,
      obscureText: !_isPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          size: 20,
          color: const Color(0xFF0288D1),
        ),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le mot de passe est requis';
        }
        if (value.length < 8) {
          return 'Minimum 8 caractères';
        }
        if (!value.contains(RegExp(r'[A-Z]'))) {
          return 'Doit contenir une majuscule';
        }
        if (!value.contains(RegExp(r'[0-9]'))) {
          return 'Doit contenir un chiffre';
        }
        return null;
      },
    );
  }

  /// Construit le champ de confirmation du mot de passe
  Widget _buildConfirmPasswordField() {
    return _buildTextField(
      controller: _confirmPasswordController,
      label: 'Confirmer le mot de passe',
      icon: Icons.lock_outline,
      obscureText: !_isConfirmPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
          size: 20,
          color: const Color(0xFF0288D1),
        ),
        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez confirmer';
        }
        if (value != _passwordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
    );
  }

  /// Construit la case à cocher des conditions
  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Checkbox(
            value: _acceptTerms,
            onChanged: _isLoading ? null : (value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            activeColor: const Color(0xFF0288D1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Expanded(
            child: Text(
              'J\'accepte les conditions générales d\'utilisation',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF01579B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le bouton d'inscription
  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 50,
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
        onPressed: _isLoading ? null : _handleRegister,
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
                'S\'inscrire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Construit le lien vers la page de connexion
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Déjà un compte ? ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'Se connecter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0288D1),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget générique pour les champs de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?)? validator,
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
        obscureText: obscureText,
        validator: validator,
        enabled: !_isLoading,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF01579B),
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: const Color(0xFF0288D1),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}