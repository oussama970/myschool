// lib/screens/student/student_events_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class StudentEventsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentClass;

  const StudentEventsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
  });

  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends State<StudentEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getParentEvents(widget.studentId);
      
      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(result['events'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Vérifie si la date limite de réponse est dépassée
  bool _isResponseDeadlinePassed(String? deadlineString) {
    if (deadlineString == null || deadlineString.isEmpty) return false;
    try {
      final deadline = DateTime.parse(deadlineString);
      return deadline.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Détermine si un événement doit être dans l'historique
  bool _isEventInHistory(Map<String, dynamic> event) {
    final myResponse = event['myResponse'] ?? 'pending';
    final responseDeadline = event['responseDeadline'];
    final isDeadlinePassed = _isResponseDeadlinePassed(responseDeadline);
    
    // Un événement va dans l'historique si:
    // 1. Les parents ont déjà répondu (myResponse != 'pending')
    // OU
    // 2. La date limite de réponse est dépassée
    return myResponse != 'pending' || isDeadlinePassed;
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les événements:
    // - À venir: événements en attente ET date limite non dépassée
    // - Historique: événements avec réponse OU date limite dépassée
    final pendingEvents = _events.where((e) => !_isEventInHistory(e)).toList();
    final historyEvents = _events.where((e) => _isEventInHistory(e)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Événements - ${widget.studentName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      _buildTab('📅 À venir (${pendingEvents.length})', pendingEvents.length, 0),
                      _buildTab('📜 Historique (${historyEvents.length})', historyEvents.length, 1),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventsList(pendingEvents, true),
                      _buildEventsList(historyEvents, false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTab(String text, int count, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            _tabController.animateTo(index);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Map<String, dynamic>> events, bool isPending) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.event_available : Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'Aucun événement à venir' : 'Aucun événement dans l\'historique',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final date = DateTime.parse(event['date']);
          final myResponse = event['myResponse'] ?? 'pending';
          final responseDeadline = event['responseDeadline'];
          final isDeadlinePassed = _isResponseDeadlinePassed(responseDeadline);
          
          // Déterminer le statut affiché
          Color statusColor;
          IconData statusIcon;
          String statusText;
          
          if (myResponse == 'accepted') {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = '✅ Participation acceptée';
          } else if (myResponse == 'rejected') {
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            statusText = '❌ Participation refusée';
          } else if (isDeadlinePassed) {
            // Date limite dépassée sans réponse
            statusColor = Colors.grey;
            statusIcon = Icons.timer_off;
            statusText = '⏰ Délai de réponse dépassé';
          } else {
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            statusText = '⏳ En attente de réponse';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] ?? 'Sans titre',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(date),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            // Afficher la date limite si elle existe
                            if (responseDeadline != null && 
                                responseDeadline.toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 10, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Date limite: ${_formatDate(DateTime.parse(responseDeadline.toString()))}',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (event['description'] != null && event['description'].isNotEmpty) ...[
                    Text(
                      event['description'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}