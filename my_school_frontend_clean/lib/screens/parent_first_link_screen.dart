import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'student_dashboard_screen.dart';
import 'login_screen.dart';

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
  final List<TextEditingController> _codeControllers = List.generate(
    10,
    (index) => TextEditingController(),
  );
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(10, (index) => FocusNode());
    
    // Vérifier le token au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkToken();
    });
  }

  Future<void> _checkToken() async {
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
    }
  }

  @override
  void dispose() {
    for (var c in _codeControllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    
    String code = _codeControllers.map((c) => c.text).join();
    print('📝 CODE SAISI: $code');
    
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

    print('🚀 ENVOI DE LA REQUÊTE verifyParentCode');
    final result = await ApiService.verifyParentCode(
      parentCode: code,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final childData = result['data']['child'];
      print('✅ SUCCÈS - Enfant lié: ${childData['fullName']}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Enfant lié avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      
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
      print('❌ ERREUR: ${result['message']}');
      
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
      for (var c in _codeControllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    } else if (value.length == 1 && index < 9) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (index == 9 && value.length == 1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _verifyCode();
      });
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
                          Icons.family_restroom,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                      
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
                      Container(
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
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Champs de code à 10 chiffres
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: List.generate(10, (index) {
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
                        }),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bouton Lier
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