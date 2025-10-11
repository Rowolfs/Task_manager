import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/project_store.dart';
import '../models/project.dart';

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectStore()..load(),
      child: const _ManagerBody(),
    );
  }
}

class _ManagerBody extends StatefulWidget {
  const _ManagerBody();

  @override
  State<_ManagerBody> createState() => _ManagerBodyState();
}

class _ManagerBodyState extends State<_ManagerBody> {
  bool showList = true;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // "Меню" как на скрине
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => showList = true),
              child: const Text('Список проектов'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => setState(() => showList = false),
              child: const Text('Добавить проект'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(showList ? 'Список проектов' : 'Добавить проект',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),

        const SizedBox(height: 12),

        if (showList) ...[
          ElevatedButton(
            onPressed: () => setState(() => showList = false),
            child: const Text('Добавить новый проект'),
          ),
          const SizedBox(height: 12),
          _HeaderRow(),
          const Divider(height: 1),
          Expanded(
            child: store.items.isEmpty
                ? const Center(child: Text('Проектов пока нет.'))
                : ListView.builder(
                    itemCount: store.items.length,
                    itemBuilder: (_, i) =>
                        _ProjectRow(p: store.items[i]),
                  ),
          ),
        ] else ...[
          Expanded(
            child: _AddProjectForm(
              onSaved: (p) async {
                await context.read<ProjectStore>().add(p);
                if (!mounted) return;
                setState(() => showList = true);
              },
            ),
          ),
        ],
      ]),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Text styled(String s) =>
        Text(s, style: const TextStyle(fontWeight: FontWeight.bold));
    return Row(children: [
      Expanded(flex: 3, child: styled('Название')),
      Expanded(flex: 2, child: styled('Дедлайн')),
      Expanded(flex: 2, child: styled('Статус')),
      Expanded(flex: 2, child: styled('Приоритет')),
      Expanded(flex: 2, child: styled('Действия')),
    ]);
  }
}

class _ProjectRow extends StatelessWidget {
  final Project p;
  const _ProjectRow({required this.p});

  String _statusLabel(ProjectStatus s) => switch (s) {
        ProjectStatus.planned => 'План',
        ProjectStatus.inProgress => 'В работе',
        ProjectStatus.done => 'Готов',
      };

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final store = context.read<ProjectStore>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(p.title)),
        Expanded(flex: 2, child: Text(p.deadline == null ? '—' : _fmt(p.deadline!))),
        Expanded(
          flex: 2,
          child: DropdownButton<ProjectStatus>(
            value: p.status,
            items: ProjectStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s))))
                .toList(),
            onChanged: (s) => store.changeStatus(p.id, s!),
          ),
        ),
        Expanded(flex: 2, child: Text(p.priority.toString())),
        Expanded(
          flex: 2,
          child: Row(children: [
            IconButton(
              onPressed: () => _openEdit(context, p),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () => store.remove(p.id),
              icon: const Icon(Icons.delete),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _openEdit(BuildContext context, Project p) async {
    final edited = await showDialog<Project>(
      context: context,
      builder: (_) => _EditProjectDialog(project: p),
    );
    if (edited != null) {
      await context.read<ProjectStore>().update(edited);
    }
  }
}

/// Форма добавления (как "Добавить проект")
class _AddProjectForm extends StatefulWidget {
  final ValueChanged<Project> onSaved;
  const _AddProjectForm({required this.onSaved});

  @override
  State<_AddProjectForm> createState() => _AddProjectFormState();
}

class _AddProjectFormState extends State<_AddProjectForm> {
  final _title = TextEditingController();
  DateTime? _deadline;
  int _priority = 3;
  ProjectStatus _status = ProjectStatus.planned;
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(children: [
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: now.subtract(const Duration(days: 1)),
                  lastDate: DateTime(now.year + 5),
                  initialDate: _deadline ?? now,
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              child: Text(_deadline == null
                  ? 'Выбрать дедлайн'
                  : 'Дедлайн: ${_deadline!.day}.${_deadline!.month}.${_deadline!.year}'),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _priority,
            items: List.generate(5, (i) => i + 1)
                .map((v) => DropdownMenuItem(value: v, child: Text('Приоритет $v')))
                .toList(),
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(width: 12),
          DropdownButton<ProjectStatus>(
            value: _status,
            items: ProjectStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
        ]),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              widget.onSaved(Project(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _title.text.trim(),
                deadline: _deadline,
                priority: _priority,
                status: _status,
              ));
            },
            child: const Text('Сохранить'),
          ),
        ),
      ]),
    );
  }
}

class _EditProjectDialog extends StatefulWidget {
  final Project project;
  const _EditProjectDialog({required this.project});

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  late TextEditingController _title;
  DateTime? _deadline;
  int _priority = 3;
  ProjectStatus _status = ProjectStatus.planned;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.project.title);
    _deadline = widget.project.deadline;
    _priority = widget.project.priority;
    _status = widget.project.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать проект'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: DateTime(now.year + 5),
                    initialDate: _deadline ?? now,
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: Text(_deadline == null
                    ? 'Выбрать дедлайн'
                    : 'Дедлайн: ${_deadline!.day}.${_deadline!.month}.${_deadline!.year}'),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: _priority,
              items: List.generate(5, (i) => i + 1)
                  .map((v) => DropdownMenuItem(value: v, child: Text('Приоритет $v')))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(width: 12),
            DropdownButton<ProjectStatus>(
              value: _status,
              items: ProjectStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.project.copyWith(
                title: _title.text.trim(),
                deadline: _deadline,
                priority: _priority,
                status: _status,
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
