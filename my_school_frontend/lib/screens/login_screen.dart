import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'student_dashboard_screen.dart';
import 'parent_first_link_screen.dart';

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
      
      if (user['role'] == 'parent') {
        // Vérifier si le parent a déjà un enfant lié
        final linkedChildResult = await ApiService.getLinkedChild(user['email']);
        print('📦 Résultat getLinkedChild: ${linkedChildResult['success']}');
        
        if (linkedChildResult['success']) {
          // Parent a déjà un enfant lié → va directement à son espace
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
        } else {
          // Parent n'a pas encore d'enfant lié → va vers la page de première liaison
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
        // Élève
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFFE57373),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0288D1), // Bleu foncé
              Color(0xFF4FC3F7), // Bleu clair
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450),
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
                    children: [
                      // Logo
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
                          Icons.school,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Titre
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sous-titre
                      const Text(
                        'Connectez-vous à votre espace',
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
                            // Champ Email
                            Container(
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
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Adresse email',
                                  labelStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF01579B),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                    color: Color(0xFF0288D1),
                                  ),
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
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Champ Mot de passe
                            Container(
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
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                enabled: !_isLoading,
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  labelStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF01579B),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                    color: Color(0xFF0288D1),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      size: 20,
                                      color: const Color(0xFF0288D1),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
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
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                            
                            const SizedBox(height: 20),
                            
                            // Bouton Connexion
                            Container(
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
                                onPressed: _isLoading ? null : _handleLogin,
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
                                        'Se connecter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Lien vers inscription
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Pas encore de compte ? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
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
                                      fontSize: 14,
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