import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Écran des statistiques pour l'administrateur
/// Affiche des graphiques et indicateurs sur l'établissement
/// Permet d'exporter les données en PDF
class AdminStatsScreen extends StatefulWidget {
  final String adminEmail;

  const AdminStatsScreen({super.key, required this.adminEmail});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // ==================== VARIABLES D'ÉTAT ====================
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge les statistiques depuis l'API
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getDashboardStats();
      
      if (result['success']) {
        setState(() {
          _stats = result['stats'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ==================== GETTERS ====================
  
  /// Nombre total d'utilisateurs
  int get totalUsers {
    return (_stats['totalTeachers'] ?? 0) + 
           (_stats['totalParents'] ?? 0) + 
           (_stats['totalStudents'] ?? 0);
  }

  /// Taux moyen de remplissage des classes
  double get classOccupationRate {
    final classes = _stats['classes'] as List? ?? [];
    if (classes.isEmpty) return 0;
    double total = 0;
    for (var c in classes) {
      int capacity = c['capacity'] ?? 30;
      int students = c['studentCount'] ?? 0;
      total += (students / capacity);
    }
    return total / classes.length;
  }

  // ==================== EXPORT PDF ====================
  
  /// Exporte les statistiques en format PDF
  Future<void> _exportPDF(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.ListView(
              children: [
                _buildPDFHeader(),
                pw.SizedBox(height: 20),
                _buildPDFStatsSection(),
                pw.SizedBox(height: 20),
                _buildPDFChartSection(),
                pw.SizedBox(height: 20),
                _buildPDFClassesSection(),
                pw.SizedBox(height: 20),
                _buildPDFParentsSection(),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/statistiques_my_school.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) Navigator.pop(context);
      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exporte avec succes !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== COMPOSANTS PDF ====================
  
  /// En-tête du PDF
  pw.Widget _buildPDFHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'My School - Rapport Statistique',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
        ),
        pw.Divider(),
      ],
    );
  }

  /// Section des statistiques générales du PDF
  pw.Widget _buildPDFStatsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Statistiques Generales',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildPDFStatCard('Enseignants', '${_stats['totalTeachers'] ?? 0}', PdfColors.blue),
            _buildPDFStatCard('Parents', '${_stats['totalParents'] ?? 0}', PdfColors.green),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildPDFStatCard('Eleves', '${_stats['totalStudents'] ?? 0}', PdfColors.orange),
            _buildPDFStatCard('Classes', '${_stats['totalClasses'] ?? 0}', PdfColors.purple),
          ],
        ),
      ],
    );
  }

  /// Carte de statistique pour le PDF
  pw.Widget _buildPDFStatCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: pw.EdgeInsets.all(8),
        padding: pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color),
            ),
            pw.SizedBox(height: 4),
            pw.Text(title, style: pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// Section du graphique de répartition dans le PDF
  pw.Widget _buildPDFChartSection() {
    final totalTeachers = (_stats['totalTeachers'] ?? 0).toDouble();
    final totalParents = (_stats['totalParents'] ?? 0).toDouble();
    final totalStudents = (_stats['totalStudents'] ?? 0).toDouble();
    final total = totalTeachers + totalParents + totalStudents;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Repartition des Utilisateurs',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildPDFLegendItem('Enseignants', PdfColors.blue),
            pw.SizedBox(width: 16),
            _buildPDFLegendItem('Parents', PdfColors.green),
            pw.SizedBox(width: 16),
            _buildPDFLegendItem('Eleves', PdfColors.orange),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Enseignants: ${(totalTeachers / total * 100).toStringAsFixed(1)}%',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Parents: ${(totalParents / total * 100).toStringAsFixed(1)}%',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Eleves: ${(totalStudents / total * 100).toStringAsFixed(1)}%',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Légende pour le graphique PDF
  pw.Widget _buildPDFLegendItem(String label, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  /// Section des classes dans le PDF
  pw.Widget _buildPDFClassesSection() {
    final classes = _stats['classes'] as List? ?? [];
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detail des Classes',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        if (classes.isEmpty)
          pw.Text('Aucune classe disponible', style: pw.TextStyle(fontSize: 12))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Classe', 'Effectif', 'Capacite', 'Taux'],
            data: classes.map< List<String> >((c) {
              int students = c['studentCount'] ?? 0;
              int capacity = c['capacity'] ?? 30;
              double taux = (students / capacity) * 100;
              return [
                c['name'] ?? '-',
                students.toString(),
                capacity.toString(),
                '${taux.toInt()}%'
              ];
            }).toList(),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
      ],
    );
  }

  /// Section des statistiques parents dans le PDF
  pw.Widget _buildPDFParentsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Statistiques Parents',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        _buildPDFStatRow('1 enfant', '${_stats['parentsStats']?['oneChild'] ?? 0} parents'),
        pw.SizedBox(height: 8),
        _buildPDFStatRow('2 enfants', '${_stats['parentsStats']?['twoChildren'] ?? 0} parents'),
        pw.SizedBox(height: 8),
        _buildPDFStatRow('3 enfants ou plus', '${_stats['parentsStats']?['threePlusChildren'] ?? 0} parents'),
      ],
    );
  }

  /// Ligne de statistique pour le PDF
  pw.Widget _buildPDFStatRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('  $label: ', style: pw.TextStyle(fontSize: 12)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  /// Pied de page du PDF
  pw.Widget _buildPDFFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'My School - Application de gestion scolaire',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Document genere automatiquement',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ],
    );
  }

  // ==================== UI FLUTTER ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    const Text(
                      'STATISTIQUES',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF01579B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grille des statistiques
                    _buildStatsGrid(),

                    const SizedBox(height: 20),

                    // Graphique en camembert
                    _buildPieChart(),

                    const SizedBox(height: 20),

                    // Taux de remplissage des classes
                    _buildClassOccupation(),

                    const SizedBox(height: 20),

                    // Tableau détaillé des classes
                    _buildClassesTable(),

                    const SizedBox(height: 20),

                    // Statistiques parents
                    _buildParentsStats(),

                    const SizedBox(height: 20),

                    // Bouton d'export PDF
                    ElevatedButton.icon(
                      onPressed: () => _exportPDF(context),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('EXPORTER EN PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  /// Grille des 4 cartes de statistiques
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCardUI(
          title: 'Enseignants',
          value: '${_stats['totalTeachers'] ?? 0}',
          icon: Icons.people,
          color: const Color(0xFF0288D1),
        ),
        _buildStatCardUI(
          title: 'Parents',
          value: '${_stats['totalParents'] ?? 0}',
          icon: Icons.family_restroom,
          color: const Color(0xFF4CAF9F),
        ),
        _buildStatCardUI(
          title: 'Eleves',
          value: '${_stats['totalStudents'] ?? 0}',
          icon: Icons.school,
          color: const Color(0xFFFF9800),
        ),
        _buildStatCardUI(
          title: 'Classes',
          value: '${_stats['totalClasses'] ?? 0}',
          icon: Icons.class_,
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  /// Carte de statistique pour l'interface Flutter
  Widget _buildStatCardUI({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Graphique en camembert de répartition des utilisateurs
  Widget _buildPieChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPARTITION DES UTILISATEURS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: (_stats['totalTeachers'] ?? 0).toDouble(),
                    title: 'Enseignants',
                    color: const Color(0xFF0288D1),
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (_stats['totalParents'] ?? 0).toDouble(),
                    title: 'Parents',
                    color: const Color(0xFF4CAF9F),
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (_stats['totalStudents'] ?? 0).toDouble(),
                    title: 'Eleves',
                    color: const Color(0xFFFF9800),
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildLegend('Enseignants', const Color(0xFF0288D1)),
              _buildLegend('Parents', const Color(0xFF4CAF9F)),
              _buildLegend('Eleves', const Color(0xFFFF9800)),
            ],
          ),
        ],
      ),
    );
  }

  /// Section du taux de remplissage des classes
  Widget _buildClassOccupation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TAUX DE REMPLISSAGE DES CLASSES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF01579B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (classOccupationRate * 100).toInt() >= 80
                      ? Colors.red.withOpacity(0.1)
                      : (classOccupationRate * 100).toInt() >= 50
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(classOccupationRate * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (classOccupationRate * 100).toInt() >= 80
                        ? Colors.red
                        : (classOccupationRate * 100).toInt() >= 50
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildClassProgressBars(),
        ],
      ),
    );
  }

  /// Barres de progression pour chaque classe
  List<Widget> _buildClassProgressBars() {
    final classes = _stats['classes'] as List? ?? [];
    if (classes.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Aucune classe disponible'),
          ),
        ),
      ];
    }
    
    return classes.map((c) {
      String name = c['name'] ?? 'Classe';
      int students = c['studentCount'] ?? 0;
      int capacity = c['capacity'] ?? 30;
      double taux = (students / capacity) * 100;
      Color barColor = taux >= 80 ? Colors.red : (taux >= 50 ? Colors.orange : const Color(0xFF0288D1));
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$students/$capacity',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: taux / 100,
              backgroundColor: Colors.grey.shade200,
              color: barColor,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${taux.toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Tableau détaillé des classes
  Widget _buildClassesTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAIL PAR CLASSE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF0288D1).withOpacity(0.1),
              ),
              columns: const [
                DataColumn(label: Text('Classe', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Effectif', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Capacite', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Taux', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: (_stats['classes'] as List? ?? []).map<DataRow>((c) {
                int students = c['studentCount'] ?? 0;
                int capacity = c['capacity'] ?? 30;
                double taux = (students / capacity) * 100;
                return DataRow(
                  cells: [
                    DataCell(Text(c['name'] ?? '-')),
                    DataCell(Text('$students')),
                    DataCell(Text('$capacity')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: taux >= 80
                              ? Colors.red.withOpacity(0.1)
                              : taux >= 50
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${taux.toInt()}%',
                          style: TextStyle(
                            color: taux >= 80
                                ? Colors.red
                                : taux >= 50
                                    ? Colors.orange
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Statistiques sur le nombre d'enfants par parent
  Widget _buildParentsStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENFANTS PAR PARENT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            '1 enfant',
            '${_stats['parentsStats']?['oneChild'] ?? 0} parents',
            progress: totalUsers > 0 ? (_stats['parentsStats']?['oneChild'] ?? 0) / totalUsers : 0,
            color: const Color(0xFF4CAF9F),
          ),
          _buildStatRow(
            '2 enfants',
            '${_stats['parentsStats']?['twoChildren'] ?? 0} parents',
            progress: totalUsers > 0 ? (_stats['parentsStats']?['twoChildren'] ?? 0) / totalUsers : 0,
            color: const Color(0xFFFF9800),
          ),
          _buildStatRow(
            '3 enfants ou plus',
            '${_stats['parentsStats']?['threePlusChildren'] ?? 0} parents',
            progress: totalUsers > 0 ? (_stats['parentsStats']?['threePlusChildren'] ?? 0) / totalUsers : 0,
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  /// Légende pour le graphique
  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Ligne de statistique avec barre de progression
  Widget _buildStatRow(String label, String value, {double progress = 0, Color color = const Color(0xFF0288D1)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}