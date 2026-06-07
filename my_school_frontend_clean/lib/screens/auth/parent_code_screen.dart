import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/screens/student/student_dashboard_screen.dart';

/// Écran de saisie du code parent pour lier un enfant
/// Permet au parent de saisir le code à 10 chiffres de son enfant
/// pour accéder à son espace
class ParentCodeScreen extends StatefulWidget {
  final String parentEmail;
  final String parentName;
  final bool fromRegister;
  
  const ParentCodeScreen({
    super.key,
    required this.parentEmail,
    required this.parentName,
    this.fromRegister = false,
  });

  @override
  State<ParentCodeScreen> createState() => _ParentCodeScreenState();
}

class _ParentCodeScreenState extends State<ParentCodeScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final List<TextEditingController> _codeControllers = List.generate(
    10,
    (index) => TextEditingController(),
  );
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(10, (index) => FocusNode());
    
    // Afficher un message d'aide si l'écran vient de l'inscription
    if (widget.fromRegister) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer le code à 10 chiffres que votre enfant a reçu par email'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    for (var c in _codeControllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    super.dispose();
  }

  // ==================== VÉRIFICATION DU CODE ====================
  
  /// Vérifie le code saisi auprès du serveur
  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    
    String code = _codeControllers.map((c) => c.text).join();
    
    // Vérifier la longueur du code
    if (code.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer les 10 chiffres du code'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiService.verifyParentCode(
      parentCode: code,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final childData = result['data']['child'];
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Connecté à l\'espace de ${childData['fullName']}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Rediriger vers l'espace de l'enfant
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDashboardScreen(
            email: childData['email'],
            studentName: childData['fullName'],
            isParent: true,
            parentEmail: widget.parentEmail,
          ),
        ),
      );
    } else {
      // Afficher l'erreur et réinitialiser les champs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
      for (var c in _codeControllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  // ==================== GESTION DES CHAMPS ====================
  
  /// Gère la navigation automatique entre les champs de code
  void _onCodeChanged(int index, String value) {
    // Revenir au champ précédent quand on supprime
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    // Passer au champ suivant quand un chiffre est saisi
    else if (value.length == 1 && index < 9) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    // Vérification automatique quand les 10 chiffres sont saisis
    else if (index == 9 && value.length == 1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _verifyCode();
      });
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
              Color(0xFFFFB74D), // Orange clair
              Color(0xFFFFA726), // Orange foncé
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 650),
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
                      // Icône
                      _buildIcon(),
                      
                      const SizedBox(height: 16),
                      
                      // Titre
                      const Text(
                        'Lier votre enfant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email du parent
                      _buildEmailChip(),
                      
                      const SizedBox(height: 30),
                      
                      // Champs pour code à 10 chiffres
                      _buildCodeInputFields(),
                      
                      const SizedBox(height: 30),
                      
                      // Bouton Lier
                      _buildLinkButton(),
                      
                      const SizedBox(height: 16),
                      
                      // Bouton Retour (si non depuis l'inscription)
                      if (!widget.fromRegister) _buildBackButton(),
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
          colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.family_restroom,
        color: Colors.white,
        size: 35,
      ),
    );
  }

  /// Construit le chip affichant l'email du parent
  Widget _buildEmailChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.parentEmail,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFFFB74D),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Construit les 10 champs de saisie du code
  Widget _buildCodeInputFields() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(10, (index) => _buildCodeField(index)),
    );
  }

  /// Construit un champ de saisie individuel pour le code
  Widget _buildCodeField(int index) {
    double size = 45.0;
    return Container(
      width: size,
      height: size + 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
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
        onChanged: (value) => _onCodeChanged(index, value),
      ),
    );
  }

  /// Construit le bouton de liaison
  Widget _buildLinkButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
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
                'Lier et voir l\'espace',
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
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text(
        'Retour',
        style: TextStyle(
          color: Color(0xFFFFB74D),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}