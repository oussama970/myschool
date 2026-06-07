import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/screens/parent/parent_dashboard_screen.dart';
import 'login_screen.dart';

/// Écran de première liaison parent-enfant
/// Permet au parent de saisir le code à 10 chiffres de son enfant
/// pour lier son compte à celui de l'enfant
class ParentFirstLinkScreen extends StatefulWidget {
  final String parentEmail;
  final String parentName;
  
  const ParentFirstLinkScreen({
    super.key,
    required this.parentEmail,
    required this.parentName,
  });

  @override
  State<ParentFirstLinkScreen> createState() => _ParentFirstLinkScreenState();
}

class _ParentFirstLinkScreenState extends State<ParentFirstLinkScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final List<TextEditingController> _codeControllers = List.generate(
    10,
    (index) => TextEditingController(),
  );
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  String? _parentId;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(10, (index) => FocusNode());
    
    // Vérifier le token au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenAndLoadParent();
    });
  }

  @override
  void dispose() {
    for (var c in _codeControllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    super.dispose();
  }

  // ==================== VÉRIFICATION DU TOKEN ====================
  
  /// Vérifie que le token est valide et charge l'ID du parent
  Future<void> _checkTokenAndLoadParent() async {
    print('🔍 VÉRIFICATION TOKEN AU CHARGEMENT');
    final token = await ApiService.getToken();
    print('🔑 RÉSULTAT: ${token != null}');
    
    if (token == null && mounted) {
      print('❌ PAS DE TOKEN - Redirection vers login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée. Veuillez vous reconnecter.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }
    
    // Récupérer l'ID du parent
    await _loadParentId();
  }

  /// Charge l'ID du parent (utilisation de l'email comme identifiant)
  Future<void> _loadParentId() async {
    try {
      final result = await ApiService.getParentChildren(widget.parentEmail);
      if (result['success'] && result['children'] != null) {
        setState(() {
          _parentId = widget.parentEmail; // Utiliser l'email comme identifiant
        });
      }
    } catch (e) {
      print('Erreur chargement parent ID: $e');
      setState(() {
        _parentId = widget.parentEmail;
      });
    }
  }

  // ==================== VÉRIFICATION DU CODE ====================
  
  /// Vérifie le code saisi auprès du serveur et lie l'enfant
  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    
    String code = _codeControllers.map((c) => c.text).join();
    print('📝 CODE SAISI: $code');
    
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

    print('🚀 ENVOI DE LA REQUÊTE linkChildToParent');
    
    final result = await ApiService.linkChildToParent(
      parentCode: code,
      parentId: widget.parentEmail, // Utiliser l'email comme identifiant
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final childData = result['child'];
      print('✅ SUCCÈS - Enfant lié: ${childData['fullName']}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Enfant lié avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Rediriger vers le dashboard parent
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParentDashboardScreen(
            parentEmail: widget.parentEmail,
            parentName: widget.parentName,
          ),
        ),
      );
    } else {
      print('❌ ERREUR: ${result['message']}');
      
      // Gestion de session expirée
      if (result['message'].contains('Session expirée')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
      // Réinitialiser les champs
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
                      
                      const SizedBox(height: 16),
                      
                      // Message d'information
                      _buildInfoMessage(),
                      
                      const SizedBox(height: 24),
                      
                      // Champs de code à 10 chiffres
                      _buildCodeInputFields(),
                      
                      const SizedBox(height: 24),
                      
                      // Bouton Lier
                      _buildLinkButton(),
                      
                      const SizedBox(height: 16),
                      
                      // Lien retour
                      _buildBackButton(),
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
        color: const Color(0xFF0288D1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.parentEmail,
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
          Icon(Icons.info_outline, size: 20, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Entrez le code à 10 chiffres que votre enfant a reçu par email',
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
                'Lier mon enfant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Construit le bouton de retour à la connexion
  Widget _buildBackButton() {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
      child: const Text(
        'Retour à la connexion',
        style: TextStyle(
          color: Color(0xFF0288D1),
        ),
      ),
    );
  }
}