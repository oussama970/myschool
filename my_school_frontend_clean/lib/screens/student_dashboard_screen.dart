import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'login_screen.dart';
import 'parent_first_link_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  final String email;
  final String studentName;
  final bool isParent;
  final String? parentEmail;
  
  const StudentDashboardScreen({
    super.key,
    required this.email,
    required this.studentName,
    this.isParent = false,
    this.parentEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isParent ? 'Espace de $studentName' : 'Mon espace'),
        backgroundColor: isParent ? const Color(0xFF4CAF9F) : const Color(0xFF0288D1),
        actions: [
          if (isParent)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'switch',
                  child: ListTile(
                    leading: Icon(Icons.swap_horiz),
                    title: Text('Lier un autre enfant'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Déconnexion'),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'switch') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentFirstLinkScreen(
                        parentEmail: parentEmail!,
                        parentName: 'Parent',
                      ),
                    ),
                  );
                } else if (value == 'logout') {
                  ApiService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ApiService.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isParent ? const Color(0xFF4CAF9F) : const Color(0xFF0288D1)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isParent ? Icons.family_restroom : Icons.school,
                size: 80,
                color: isParent ? const Color(0xFF4CAF9F) : const Color(0xFF0288D1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isParent ? 'Espace de $studentName' : 'Bienvenue $studentName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            if (isParent) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                ),
                child: const Text(
                  '👪 Mode parent - Consultation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}