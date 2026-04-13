import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatsScreen extends StatefulWidget {
  final String adminEmail;

  const AdminStatsScreen({super.key, required this.adminEmail});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _selectedPeriod = 'Mois';
  final List<String> _periods = ['Semaine', 'Mois', 'Année'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

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

  int get totalUsers {
    return (_stats['totalTeachers'] ?? 0) + 
           (_stats['totalParents'] ?? 0) + 
           (_stats['totalStudents'] ?? 0);
  }

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
                    // En-tête avec sélecteur de période
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📊 STATISTIQUES',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.3)),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            underline: const SizedBox(),
                            items: _periods.map((period) {
                              return DropdownMenuItem(
                                value: period,
                                child: Text(period),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Cartes de statistiques avec icônes
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          title: 'Enseignants',
                          value: '${_stats['totalTeachers'] ?? 0}',
                          icon: Icons.people,
                          color: const Color(0xFF0288D1),
                          trend: '+12%',
                          trendUp: true,
                        ),
                        _buildStatCard(
                          title: 'Parents',
                          value: '${_stats['totalParents'] ?? 0}',
                          icon: Icons.family_restroom,
                          color: const Color(0xFF4CAF9F),
                          trend: '+8%',
                          trendUp: true,
                        ),
                        _buildStatCard(
                          title: 'Élèves',
                          value: '${_stats['totalStudents'] ?? 0}',
                          icon: Icons.school,
                          color: const Color(0xFFFF9800),
                          trend: '+15%',
                          trendUp: true,
                        ),
                        _buildStatCard(
                          title: 'Classes',
                          value: '${_stats['totalClasses'] ?? 0}',
                          icon: Icons.class_,
                          color: const Color(0xFF9C27B0),
                          trend: '2',
                          trendUp: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Graphique circulaire - Répartition
                    Container(
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
                            '📈 RÉPARTITION DES UTILISATEURS',
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
                                    title: 'Élèves',
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
                              _buildLegend('Élèves', const Color(0xFFFF9800)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Graphique à barres - Taux de remplissage des classes (CORRIGÉ)
                    Container(
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
                                '🏫 TAUX DE REMPLISSAGE DES CLASSES',
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
                          // Version simplifiée sans overflow - Barres horizontales
                          ..._buildClassProgressBars(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Détails par classe
                    Container(
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
                            '📋 DÉTAIL PAR CLASSE',
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
                                DataColumn(label: Text('Capacité', style: TextStyle(fontWeight: FontWeight.bold))),
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
                    ),

                    const SizedBox(height: 20),

                    // Statistiques enfants par parent
                    Container(
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
                            '👨‍👩‍👧 ENFANTS PAR PARENT',
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
                            progress: (_stats['parentsStats']?['oneChild'] ?? 0) / totalUsers,
                            color: const Color(0xFF4CAF9F),
                          ),
                          _buildStatRow(
                            '2 enfants',
                            '${_stats['parentsStats']?['twoChildren'] ?? 0} parents',
                            progress: (_stats['parentsStats']?['twoChildren'] ?? 0) / totalUsers,
                            color: const Color(0xFFFF9800),
                          ),
                          _buildStatRow(
                            '3 enfants ou plus',
                            '${_stats['parentsStats']?['threePlusChildren'] ?? 0} parents',
                            progress: (_stats['parentsStats']?['threePlusChildren'] ?? 0) / totalUsers,
                            color: const Color(0xFF9C27B0),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareStats(),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('PARTAGER'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0288D1),
                              side: const BorderSide(color: Color(0xFF0288D1)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendUp ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: trendUp ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        color: trendUp ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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

  List<BarChartGroupData> _buildBarGroups() {
    final classes = _stats['classes'] as List? ?? [];
    return classes.asMap().entries.map((entry) {
      int students = entry.value['studentCount'] ?? 0;
      int capacity = entry.value['capacity'] ?? 30;
      double taux = (students / capacity) * 100;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: taux,
            color: taux >= 80 ? Colors.red : (taux >= 50 ? Colors.orange : const Color(0xFF0288D1)),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

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

  void _exportPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Export PDF en cours de développement...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareStats() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Partage en cours de développement...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }
}