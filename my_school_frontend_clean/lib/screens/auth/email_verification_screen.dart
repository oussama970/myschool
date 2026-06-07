import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/screens/student/student_dashboard_screen.dart';

/// Écran de vérification d'email pour les élèves
/// Permet à l'élève de saisir le code à 6 chiffres reçu par email
/// pour activer son compte
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  String? _childName;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (index) => FocusNode());
    _loadChildInfo();
  }

  @override
  void dispose() {
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge les informations de l'élève (nom)
  Future<void> _loadChildInfo() async {
    try {
      final result = await ApiService.getChildInfo(widget.email);
      if (result['success'] && mounted) {
        setState(() {
          _childName = result['child']['fullName'];
        });
      }
    } catch (e) {
      print('Erreur chargement info enfant: $e');
    }
  }

  // ==================== VÉRIFICATION ====================
  
  /// Vérifie le code saisi auprès du serveur
  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    
    String code = _codeControllers.map((c) => c.text).join();
    
    try {
      final result = await ApiService.verifyEmail(
        email: widget.email,
        code: code,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Code incorrect'),
            backgroundColor: Colors.red,
          ),
        );
        // Réinitialiser les champs
        for (var c in _codeControllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Affiche la boîte de dialogue de succès et redirige vers le tableau de bord
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ Compte vérifié !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Un code à 10 chiffres a été envoyé à votre email',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous devrez communiquer ce code à vos parents.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0288D1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_read,
                    color: Color(0xFF0288D1),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Email envoyé',
                    style: TextStyle(
                      color: Color(0xFF0288D1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentDashboardScreen(
                    email: widget.email,
                    studentName: _childName ?? 'Élève',
                    isParent: false,
                  ),
                ),
              );
            },
            child: const Text('Accéder à mon espace'),
          ),
        ],
      ),
    );
  }

  // ==================== GESTION DES CHAMPS ====================
  
  /// Gère la navigation automatique entre les champs de code
  void _onCodeChanged(int index, String value) {
    // Passer au champ suivant quand un chiffre est saisi
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    // Revenir au champ précédent quand on supprime
    else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    
    // Vérification automatique quand les 6 chiffres sont saisis
    if (index == 5 && value.length == 1) {
      String fullCode = _codeControllers.map((c) => c.text).join();
      if (fullCode.length == 6) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _verifyCode();
        });
      }
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                      // Icône
                      _buildIcon(),
                      
                      const SizedBox(height: 20),
                      
                      // Titre
                      const Text(
                        'Vérification',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sous-titre
                      const Text(
                        'Entrez le code à 6 chiffres',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email
                      _buildEmailChip(),
                      
                      const SizedBox(height: 30),
                      
                      // Message d'information
                      _buildInfoMessage(),
                      
                      const SizedBox(height: 24),
                      
                      // Champs de code
                      _buildCodeInputFields(),
                      
                      const SizedBox(height: 24),
                      
                      // Bouton Vérifier
                      _buildVerifyButton(),
                      
                      const SizedBox(height: 16),
                      
                      // Lien pour renvoyer le code
                      _buildResendCodeButton(),
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
      width: 80,
      height: 80,
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
        Icons.mark_email_read,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  /// Construit le chip affichant l'email de l'utilisateur
  Widget _buildEmailChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
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

  /// Construit le message d'information orange
  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.orange,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Un code à 6 chiffres vous a été envoyé par email',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les 6 champs de saisie du code
  Widget _buildCodeInputFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = ((constraints.maxWidth - 40) / 6).clamp(40, 50);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) => _buildCodeField(index, size)),
        );
      },
    );
  }

  /// Construit un champ de saisie individuel pour le code
  Widget _buildCodeField(int index, double size) {
    return Container(
      width: size,
      height: size + 10,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _codeControllers[index].text.isNotEmpty
              ? const Color(0xFF0288D1)
              : Colors.grey.shade300,
          width: _codeControllers[index].text.isNotEmpty ? 2 : 1,
        ),
      ),
      child: TextFormField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        enabled: !_isLoading,
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF01579B),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (v) => _onCodeChanged(index, v),
      ),
    );
  }

  /// Construit le bouton de vérification
  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0288D1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
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
                'VÉRIFIER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Construit le bouton pour renvoyer le code
  Widget _buildResendCodeButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Un nouveau code a été envoyé à ${widget.email}'),
                  backgroundColor: const Color(0xFF4CAF9F),
                ),
              );
            },
      child: const Text(
        'Renvoyer le code',
        style: TextStyle(
          color: Color(0xFF0288D1),
        ),
      ),
    );
  }
}