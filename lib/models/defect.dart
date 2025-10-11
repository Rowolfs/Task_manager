import 'dart:convert';

enum DefectStatus { open, inProgress, resolved }

class Defect {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final DefectStatus status;
  final int priority; // 1..5
  final DateTime createdAt;

  Defect({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    this.status = DefectStatus.open,
    this.priority = 3,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Defect copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    DefectStatus? status,
    int? priority,
    DateTime? createdAt,
  }) => Defect(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status.index,
        'priority': priority,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Defect.fromJson(Map<String, dynamic> j) => Defect(
        id: j['id'] as String,
        projectId: j['projectId'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        status: DefectStatus.values[(j['status'] as int?) ?? 0],
        priority: (j['priority'] as int?) ?? 3,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (j['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );

  static String encodeList(List<Defect> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<Defect> decodeList(String s) =>
      (jsonDecode(s) as List).map((e) => Defect.fromJson(e)).toList();
}
