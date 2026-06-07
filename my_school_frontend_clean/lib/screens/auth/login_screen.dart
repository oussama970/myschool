// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/screens/student/student_dashboard_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

import 'parent_first_link_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';

/// Écran de connexion principal de l'application
/// Point d'entrée unique pour tous les utilisateurs (admin, enseignant, parent, élève)
/// Gère l'authentification et la redirection vers le dashboard approprié
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==================== AUTHENTIFICATION ====================
  
  /// Gère la tentative de connexion
  /// Vérifie les identifiants, récupère le rôle et redirige vers l'écran approprié
  Future<void> _handleLogin() async {
    // Fermer le clavier
    FocusScope.of(context).unfocus();
    
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;
    
    // Afficher l'indicateur de chargement
    setState(() => _isLoading = true);

    // Appel API de connexion
    final result = await ApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final data = result['data'];
      final user = data['user'];
      
      // Logs de débogage
      final token = await ApiService.getToken();
      print('🔑 Token après login: ${token != null}');
      print('👤 Rôle: ${user['role']}');
      print('📧 Email: ${user['email']}');
      
      // Redirection selon le rôle
      await _redirectBasedOnRole(user);
    } else {
      _showLoginError(result);
    }
  }

  /// Redirige l'utilisateur vers son dashboard en fonction de son rôle
  Future<void> _redirectBasedOnRole(Map<String, dynamic> user) async {
    // Rôle ADMINISTRATEUR
    if (user['role'] == 'admin') {
      print('👑 Connexion administrateur');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboardScreen(
            email: user['email'],
            adminName: user['fullName'],
          ),
        ),
      );
    }
    // Rôle ENSEIGNANT
    else if (user['role'] == 'teacher') {
      print('👨‍🏫 Connexion enseignant');
      
      final teacherInfo = await ApiService.getTeacherInfo(user['email']);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherDashboardScreen(
            email: user['email'],
            teacherName: user['fullName'],
            className: teacherInfo['className'] ?? 'CM2 A',
          ),
        ),
      );
    }
    // Rôle PARENT
    else if (user['role'] == 'parent') {
      print('👨‍👩‍👧 Connexion parent');
      
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final childrenResult = await ApiService.getParentChildren(user['email']);
      print('📦 Enfants trouvés: ${childrenResult['children']?.length ?? 0}');
      
      if (mounted) Navigator.pop(context);
      
      // Si des enfants sont liés, aller au dashboard parent
      if (childrenResult['success'] && 
          childrenResult['children'] != null && 
          childrenResult['children'].isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ParentDashboardScreen(
              parentEmail: user['email'],
              parentName: user['fullName'],
            ),
          ),
        );
      } else {
        // Sinon, aller à l'écran de liaison d'enfant
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ParentFirstLinkScreen(
              parentEmail: user['email'],
              parentName: user['fullName'],
            ),
          ),
        );
      }
    }
    // Rôle ÉLÈVE
    else if (user['role'] == 'student') {
      print('👦 Connexion élève');
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboardScreen(
              email: user['email'],
              studentName: user['fullName'],
              isParent: false,
            ),
          ),
        );
      }
    }
    // Rôle non reconnu
    else {
      print('❌ Rôle inconnu: ${user['role']}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rôle utilisateur non reconnu'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Affiche un message d'erreur en cas d'échec de connexion
  void _showLoginError(Map<String, dynamic> result) {
    String errorMessage = result['message'] ?? 'Erreur de connexion';
    
    // Message spécifique pour la vérification email
    if (result.containsKey('requiresVerification') && result['requiresVerification'] == true) {
      errorMessage = 'Veuillez vérifier votre email avant de vous connecter';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: const Color(0xFFE57373),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0288D1).withOpacity(0.9),
              const Color(0xFF4FC3F7).withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo animé
                      _buildAnimatedLogo(),
                      
                      const SizedBox(height: 25),
                      
                      // Titre de bienvenue
                      const Text(
                        'Bienvenue',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sous-titre
                      Text(
                        'Connectez-vous à votre espace',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // Formulaire de connexion
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Champ Email
                            _buildEmailField(),
                            
                            const SizedBox(height: 16),
                            
                            // Champ Mot de passe
                            _buildPasswordField(),
                            
                            const SizedBox(height: 12),
                            
                            // Lien Mot de passe oublié
                            _buildForgotPasswordLink(),
                            
                            const SizedBox(height: 25),
                            
                            // Bouton de connexion
                            _buildLoginButton(),
                            
                            const SizedBox(height: 20),
                            
                            // Lien d'inscription
                            _buildRegisterLink(),
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

  /// Construit le logo animé
  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0288D1).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.school, color: Colors.white, size: 45),
      ),
    );
  }

  /// Construit le champ de saisie de l'email
  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Adresse email',
          labelStyle: TextStyle(fontSize: 15, color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.email_outlined, size: 22, color: Color(0xFF0288D1)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2)),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'L\'email est requis';
          if (!value.contains('@')) return 'Email invalide';
          if (!value.contains('.')) return 'Email invalide';
          return null;
        },
      ),
    );
  }

  /// Construit le champ de saisie du mot de passe
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        textInputAction: TextInputAction.done,
        enabled: !_isLoading,
        onFieldSubmitted: (_) => _handleLogin(),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          labelStyle: TextStyle(fontSize: 15, color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.lock_outline, size: 22, color: Color(0xFF0288D1)),
          suffixIcon: IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 22, color: const Color(0xFF0288D1)),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2)),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Le mot de passe est requis';
          return null;
        },
      ),
    );
  }

  /// Construit le lien "Mot de passe oublié"
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
              ),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: const Text(
          'Mot de passe oublié ?',
          style: TextStyle(fontSize: 13, color: Color(0xFF4FC3F7), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  /// Construit le bouton de connexion
  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoading
            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                'Se connecter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }

  /// Construit le lien d'inscription
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Pas encore de compte ? ', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text(
            'S\'inscrire',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0288D1)),
          ),
        ),
      ],
    );
  }
}