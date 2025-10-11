import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/project_store.dart';
import '../data/defect_store.dart';
import '../models/project.dart';
import '../models/defect.dart';

class ExecCustomerHome extends StatelessWidget {
  const ExecCustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectStore()..load()),
        ChangeNotifierProvider(create: (_) => DefectStore()..load()),
      ],
      child: const _ExecBody(),
    );
  }
}

class _ExecBody extends StatelessWidget {
  const _ExecBody();

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectStore>().items;
    final defects = context.watch<DefectStore>().items;

    final total = projects.length;
    final done = projects.where((p) => p.status == ProjectStatus.done).length;
    final inWork =
        projects.where((p) => p.status == ProjectStatus.inProgress).length;
    final planned =
        projects.where((p) => p.status == ProjectStatus.planned).length;


    final openDefects =
        defects.where((d) => d.status != DefectStatus.resolved).length;
    final closedDefects =
        defects.where((d) => d.status == DefectStatus.resolved).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Сводка по проектам',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // карточки с цифрами
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(title: 'Всего проектов', value: '$total', color: Colors.blueGrey),
            _StatCard(title: 'В работе', value: '$inWork', color: Colors.orange),
            _StatCard(title: 'Завершено', value: '$done', color: Colors.green),
            _StatCard(title: 'Запланировано', value: '$planned', color: Colors.teal),
            _StatCard(title: 'Открытых дефектов', value: '$openDefects', color: Colors.redAccent),
            _StatCard(title: 'Закрытых дефектов', value: '$closedDefects', color: Colors.lightGreen),
          ],
        ),

        const SizedBox(height: 24),
        const Text(
          'Детали по проектам',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _HeaderRow(),
        const Divider(height: 1),

        Expanded(
          child: projects.isEmpty
              ? const Center(child: Text('Проектов пока нет.'))
              : ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (_, i) {
                    final p = projects[i];
                    final stats = _defectStatsForProject(p, defects);
                    return _ProjectRow(p: p, stats: stats);
                  },
                ),
        ),
      ]),
    );
  }

  _DefectStats _defectStatsForProject(Project p, List<Defect> defects) {
    final related = defects.where((d) => d.projectId == p.id).toList();
    final open = related.where((d) => d.status != DefectStatus.resolved).length;
    final closed =
        related.where((d) => d.status == DefectStatus.resolved).length;
    return _DefectStats(total: related.length, open: open, closed: closed);
  }
}

class _DefectStats {
  final int total;
  final int open;
  final int closed;
  const _DefectStats({required this.total, required this.open, required this.closed});
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Text bold(String s) => Text(s,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
    return Row(children: [
      Expanded(flex: 3, child: bold('Название')),
      Expanded(flex: 2, child: bold('Дедлайн')),
      Expanded(flex: 2, child: bold('Статус')),
      Expanded(flex: 2, child: bold('Дефекты')),
    ]);
  }
}

class _ProjectRow extends StatelessWidget {
  final Project p;
  final _DefectStats stats;
  const _ProjectRow({required this.p, required this.stats});

  String _status(ProjectStatus s) => switch (s) {
        ProjectStatus.planned => 'План',
        ProjectStatus.inProgress => 'В работе',
        ProjectStatus.done => 'Готов',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(p.title)),
        Expanded(
            flex: 2,
            child: Text(p.deadline == null
                ? '—'
                : '${p.deadline!.day}.${p.deadline!.month}.${p.deadline!.year}')),
        Expanded(flex: 2, child: Text(_status(p.status))),
        Expanded(
          flex: 2,
          child: Text(
            stats.total == 0
                ? '—'
                : 'Всего: ${stats.total}, Откр: ${stats.open}, Закр: ${stats.closed}',
          ),
        ),
      ]),
    );
  }
}
