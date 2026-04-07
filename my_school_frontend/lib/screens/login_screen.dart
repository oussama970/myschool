import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'student_dashboard_screen.dart';
import 'parent_first_link_screen.dart';
import 'admin_dashboard_screen.dart';
import 'teacher/teacher_dashboard_screen.dart'; // Import pour enseignant

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final result = await ApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final data = result['data'];
      final user = data['user'];
      
      // Vérification que le token est bien sauvegardé
      final token = await ApiService.getToken();
      print('🔑 Token après login: ${token != null}');
      
      // GESTION DES RÔLES
      if (user['role'] == 'admin') {
        // 👑 ADMIN
        print('👑 Connexion administrateur');
        if (mounted) {
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
      }
      else if (user['role'] == 'teacher') {
        // 👨‍🏫 ENSEIGNANT
        print('👨‍🏫 Connexion enseignant');
        
        // Récupérer les informations de l'enseignant (classe, etc.)
        // Dans une vraie application, ces données viendraient du backend
        final teacherInfo = await ApiService.getTeacherInfo(user['email']);
        
        if (mounted) {
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
      }
      else if (user['role'] == 'parent') {
        // 👨‍👩‍👧 PARENT
        print('👨‍👩‍👧 Connexion parent');
        
        // Afficher un indicateur de chargement
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final linkedChildResult = await ApiService.getLinkedChild(user['email']);
        print('📦 Résultat getLinkedChild: ${linkedChildResult['success']}');
        
        if (mounted) {
          Navigator.pop(context); // Fermer le dialogue de chargement
        }
        
        if (linkedChildResult['success'] && mounted) {
          // Parent a déjà un enfant lié
          final child = linkedChildResult['child'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboardScreen(
                email: child['email'],
                studentName: child['fullName'],
                isParent: true,
                parentEmail: user['email'],
              ),
            ),
          );
        } else if (mounted) {
          // Parent n'a pas encore d'enfant lié
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
      } else {
        // 👦 ÉLÈVE
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
    } else {
      // ERREUR DE CONNEXION
      String errorMessage = result['message'] ?? 'Erreur de connexion';
      
      // Vérifier si l'erreur indique une vérification d'email requise
      if (result.containsKey('requiresVerification') && result['requiresVerification'] == true) {
        errorMessage = 'Veuillez vérifier votre email avant de vous connecter';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFE57373),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

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
                      // Logo avec animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
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
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Titre
                      const Text(
                        'Bienvenue',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sous-titre
                      Text(
                        'Connectez-vous à votre espace',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // Formulaire
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Champ Email
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Adresse email',
                                  labelStyle: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    size: 22,
                                    color: Color(0xFF0288D1),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'L\'email est requis';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email invalide';
                                  }
                                  if (!value.contains('.')) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Champ Mot de passe
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
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
                                  labelStyle: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 22,
                                    color: Color(0xFF0288D1),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      size: 22,
                                      color: const Color(0xFF0288D1),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Le mot de passe est requis';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Lien mot de passe oublié
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4FC3F7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 25),
                            
                            // Bouton Connexion
                            Container(
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 25,
                                        width: 25,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Lien vers inscription
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pas encore de compte ? ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading ? null : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    'S\'inscrire',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0288D1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
}