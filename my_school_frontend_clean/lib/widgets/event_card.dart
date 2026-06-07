// lib/widgets/event_card.dart
/// Widget de carte d'événement pour afficher les informations d'un événement
/// Utilisé dans les listes d'événements avec statut, description et statistiques

import 'package:flutter/material.dart';
import 'package:my_school_frontend/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(event.status);
    final statusText = _getStatusText(event.status);
    final statusIcon = _getStatusIcon(event.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône, titre, date et statut
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${event.date.day}/${event.date.month}/${event.date.year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 11, color: statusColor),
                    ),
                  ),
                  
                  // Bouton de suppression (optionnel)
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: onDelete,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              
              const SizedBox(height: 8),
              
              // Statistiques des réponses
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.people,
                    count: event.studentResponses.length,
                    label: 'élèves',
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    icon: Icons.check_circle,
                    count: event.acceptedCount,
                    label: 'acceptés',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    icon: Icons.pending,
                    count: event.pendingCount,
                    label: 'attente',
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un élément de statistique avec icône, compte et label
  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[500]),
        ),
      ],
    );
  }

  /// Retourne la couleur associée au statut de l'événement
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Retourne le texte associé au statut de l'événement
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'approved': return 'Validé';
      case 'rejected': return 'Refusé';
      default: return 'Terminé';
    }
  }

  /// Retourne l'icône associée au statut de l'événement
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.done_all;
    }
  }
}