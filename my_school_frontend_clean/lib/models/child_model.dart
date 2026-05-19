// lib/models/child_model.dart
class ChildModel {
  final String id;
  final String fullName;
  final String email;
  final String className;
  final String childCode;
  final String? parentCode;

  ChildModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.className,
    required this.childCode,
    this.parentCode,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
    id: json['_id'] ?? json['id'],
    fullName: json['fullName'] ?? 'Inconnu',
    email: json['email'] ?? '',
    className: json['className'] ?? 'Non assigné',
    childCode: json['childCode'] ?? '',
    parentCode: json['parentCode'],
  );
}