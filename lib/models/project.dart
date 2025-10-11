import 'dart:convert';

enum ProjectStatus { planned, inProgress, done }

class Project {
  final String id;
  final String title;
  final DateTime? deadline;
  final ProjectStatus status;
  final int priority; // 1..5

  const Project({
    required this.id,
    required this.title,
    this.deadline,
    this.status = ProjectStatus.planned,
    this.priority = 3,
  });

  Project copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    ProjectStatus? status,
    int? priority,
  }) => Project(
        id: id ?? this.id,
        title: title ?? this.title,
        deadline: deadline ?? this.deadline,
        status: status ?? this.status,
        priority: priority ?? this.priority,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'deadline': deadline?.millisecondsSinceEpoch,
        'status': status.index,
        'priority': priority,
      };

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'] as String,
        title: j['title'] as String,
        deadline: j['deadline'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['deadline'] as int),
        status: ProjectStatus.values[(j['status'] as int?) ?? 0],
        priority: (j['priority'] as int?) ?? 3,
      );

  static String encodeList(List<Project> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<Project> decodeList(String s) =>
      (jsonDecode(s) as List).map((e) => Project.fromJson(e)).toList();
}
