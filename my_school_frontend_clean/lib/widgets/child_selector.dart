// lib/widgets/child_selector.dart
import 'package:flutter/material.dart';
import '../models/child_model.dart';

class ChildSelector extends StatelessWidget {
  final List<ChildModel> children;
  final ChildModel? selectedChild;
  final Function(ChildModel) onChildSelected;

  const ChildSelector({
    super.key,
    required this.children,
    required this.selectedChild,
    required this.onChildSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (children.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChildModel>(
          value: selectedChild,
          isExpanded: true,
          icon: const Icon(Icons.swap_horiz, color: Color(0xFF4CAF9F)),
          items: children.map((child) {
            return DropdownMenuItem(
              value: child,
              child: Row(
                children: [
                  const Icon(Icons.child_care, size: 18, color: Color(0xFF4CAF9F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(child.className, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChildSelected(value);
          },
        ),
      ),
    );
  }
}