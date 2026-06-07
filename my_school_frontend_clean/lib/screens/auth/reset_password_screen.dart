import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'login_screen.dart';

/// Écran de réinitialisation du mot de passe
/// Permet à l'utilisateur de saisir le code de vérification reçu par email
/// et de définir un nouveau mot de passe
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==================== RÉINITIALISATION ====================
  
  /// Envoie la demande de réinitialisation du mot de passe
  Future<void> _handleReset() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    // Appel API pour réinitialiser le mot de passe
    final result = await ApiService.resetPassword(
      email: widget.email,
      code: _codeController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // Succès - rediriger vers l'écran de connexion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
      // Erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône
                      _buildIcon(),
                      
                      const SizedBox(height: 16),
                      
                      // Titre
                      const Text(
                        'Nouveau mot de passe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email
                      _buildEmailChip(),
                      
                      const SizedBox(height: 24),
                      
                      // Formulaire
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Champ Code de vérification
                            _buildCodeField(),
                            
                            const SizedBox(height: 16),
                            
                            // Champ Nouveau mot de passe
                            _buildNewPasswordField(),
                            
                            const SizedBox(height: 16),
                            
                            // Champ Confirmation
                            _buildConfirmPasswordField(),
                            
                            const SizedBox(height: 24),
                            
                            // Bouton Réinitialiser
                            _buildResetButton(),
                            
                            const SizedBox(height: 16),
                            
                            // Lien retour
                            _buildBackButton(),
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

  /// Construit l'icône de l'écran
  Widget _buildIcon() {
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
        Icons.password,
        color: Colors.white,
        size: 35,
      ),
    );
  }

  /// Construit le chip affichant l'email de l'utilisateur
  Widget _buildEmailChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0288D1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.email,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF0288D1),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Construit le champ du code de vérification
  Widget _buildCodeField() {
    return _buildTextField(
      controller: _codeController,
      label: 'Code de vérification',
      icon: Icons.lock,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le code est requis';
        }
        return null;
      },
    );
  }

  /// Construit le champ du nouveau mot de passe
  Widget _buildNewPasswordField() {
    return _buildTextField(
      controller: _newPasswordController,
      label: 'Nouveau mot de passe',
      icon: Icons.lock_outline,
      obscureText: !_isNewPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF0288D1),
        ),
        onPressed: () {
          setState(() {
            _isNewPasswordVisible = !_isNewPasswordVisible;
          });
        },
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
          color: const Color(0xFF0288D1),
        ),
        onPressed: () {
          setState(() {
            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez confirmer';
        }
        if (value != _newPasswordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
    );
  }

  /// Construit le bouton de réinitialisation
  Widget _buildResetButton() {
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
        onPressed: _isLoading ? null : _handleReset,
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
                'Réinitialiser',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Construit le bouton de retour
  Widget _buildBackButton() {
    return TextButton(
      onPressed: _isLoading ? null : () {
        Navigator.pop(context);
      },
      child: const Text(
        'Retour',
        style: TextStyle(
          color: Color(0xFF0288D1),
          fontWeight: FontWeight.w500,
        ),
      ),
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