import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'student_dashboard_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  String? _childName;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (index) => FocusNode());
    _loadChildInfo();
  }

  Future<void> _loadChildInfo() async {
    final result = await ApiService.getChildInfo(widget.email);
    if (result['success'] && mounted) {
      setState(() {
        _childName = result['child']['fullName'];
      });
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
    
    final result = await ApiService.verifyEmail(
      email: widget.email,
      code: code,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // Le code parent a été envoyé par email, on ne l'affiche pas
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
      for (var c in _codeControllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ Compte vérifié !'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Un code à 10 chiffres a été envoyé à votre email',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Vous devrez communiquer ce code à vos parents.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Icon(
              Icons.mark_email_read,
              size: 50,
              color: Color(0xFF0288D1),
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

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    if (index == 5 && value.length == 1) {
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
                          Icons.mark_email_read,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Titre
                      const Text(
                        'Vérification email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email
                      Container(
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
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Champs de code
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double size = ((constraints.maxWidth - 40) / 6).clamp(40, 50);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) => Container(
                              width: size,
                              height: size + 10,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
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
                                onChanged: (v) => _onCodeChanged(index, v),
                              ),
                            )),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Bouton Vérifier
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
                                  'Vérifier',
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