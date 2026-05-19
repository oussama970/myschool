class ExamGrade {
  final String studentId;
  final String studentName;
  final double grade;
  final String appreciation;
  final String? photoUrl;
  final DateTime submittedAt;

  ExamGrade({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.appreciation,
    this.photoUrl,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'grade': grade,
    'appreciation': appreciation,
    'photoUrl': photoUrl,
    'submittedAt': submittedAt.toIso8601String(),
  };

  factory ExamGrade.fromJson(Map<String, dynamic> json) => ExamGrade(
    studentId: json['studentId'],
    studentName: json['studentName'],
    grade: json['grade'].toDouble(),
    appreciation: json['appreciation'] ?? '',
    photoUrl: json['photoUrl'],
    submittedAt: DateTime.parse(json['submittedAt']),
  );
}