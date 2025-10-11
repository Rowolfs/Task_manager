import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/project_store.dart';
import '../data/defect_store.dart';
import '../models/project.dart';
import '../models/defect.dart';

class EngineerHome extends StatelessWidget {
  const EngineerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectStore()..load()),
        ChangeNotifierProvider(create: (_) => DefectStore()..load()),
      ],
      child: const _EngineerBody(),
    );
  }
}

class _EngineerBody extends StatefulWidget {
  const _EngineerBody();

  @override
  State<_EngineerBody> createState() => _EngineerBodyState();
}

class _EngineerBodyState extends State<_EngineerBody> {
  bool showList = true;
  String? filterProjectId;

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectStore>().items;
    final defects = context.watch<DefectStore>().byProject(filterProjectId);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => showList = true),
              child: const Text('Дефекты'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => setState(() => showList = false),
              child: const Text('Зарегистрировать дефект'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (showList) ...[
          Row(children: [
            const Text('Список дефектов', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const Spacer(),
            DropdownButton<String?>(
              value: filterProjectId,
              hint: const Text('Фильтр: проект'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Все')),
                ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))),
              ],
              onChanged: (v) => setState(() => filterProjectId = v),
            ),
          ]),
          const SizedBox(height: 12),
          _HeaderRow(),
          const Divider(height: 1),
          Expanded(
            child: defects.isEmpty
                ? const Center(child: Text('Дефектов пока нет.'))
                : ListView.builder(
                    itemCount: defects.length,
                    itemBuilder: (_, i) => _DefectRow(
                      d: defects[i],
                      projectTitle: projects.firstWhere(
                        (p) => p.id == defects[i].projectId,
                        orElse: () => Project(id: '', title: '—'),
                      ).title,
                    ),
                  ),
          ),
        ] else ...[
          Expanded(child: _AddDefectForm()),
        ],
      ]),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Text s(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold));
    return Row(children: [
      Expanded(flex: 2, child: s('Проект')),
      Expanded(flex: 3, child: s('Заголовок')),
      Expanded(flex: 3, child: s('Описание')),
      Expanded(flex: 2, child: s('Статус')),
      Expanded(flex: 1, child: s('Приор.')),
      Expanded(flex: 2, child: s('Действия')),
    ]);
  }
}

class _DefectRow extends StatelessWidget {
  final Defect d;
  final String projectTitle;
  const _DefectRow({required this.d, required this.projectTitle});

  String _statusLabel(DefectStatus s) => switch (s) {
        DefectStatus.open => 'Открыт',
        DefectStatus.inProgress => 'В работе',
        DefectStatus.resolved => 'Закрыт',
      };

  @override
  Widget build(BuildContext context) {
    final store = context.read<DefectStore>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(flex: 2, child: Text(projectTitle)),
        Expanded(flex: 3, child: Text(d.title)),
        Expanded(flex: 3, child: Text(d.description, maxLines: 2, overflow: TextOverflow.ellipsis)),
        Expanded(
          flex: 2,
          child: DropdownButton<DefectStatus>(
            value: d.status,
            items: DefectStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s))))
                .toList(),
            onChanged: (s) => store.changeStatus(d.id, s!),
          ),
        ),
        Expanded(flex: 1, child: Text(d.priority.toString())),
        Expanded(
          flex: 2,
          child: Row(children: [
            IconButton(
              onPressed: () => _openEdit(context, d),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () => store.remove(d.id),
              icon: const Icon(Icons.delete),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _openEdit(BuildContext context, Defect d) async {
    final edited = await showDialog<Defect>(
      context: context,
      builder: (_) => _EditDefectDialog(defect: d),
    );
    if (edited != null) {
      await context.read<DefectStore>().update(edited);
    }
  }
}

class _AddDefectForm extends StatefulWidget {
  @override
  State<_AddDefectForm> createState() => _AddDefectFormState();
}

class _AddDefectFormState extends State<_AddDefectForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _priority = 3;
  DefectStatus _status = DefectStatus.open;
  String? _projectId;

  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectStore>().items;

    return Form(
      key: _form,
      child: Column(children: [
        DropdownButtonFormField<String>(
          value: _projectId,
          decoration: const InputDecoration(
            labelText: 'Проект',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Выберите проект' : null,
          items: projects
              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
              .toList(),
          onChanged: (v) => setState(() => _projectId = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите заголовок' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _desc,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Row(children: [
          DropdownButton<int>(
            value: _priority,
            items: List.generate(5, (i) => i + 1)
                .map((v) => DropdownMenuItem(value: v, child: Text('Приоритет $v')))
                .toList(),
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(width: 12),
          DropdownButton<DefectStatus>(
            value: _status,
            items: DefectStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              context.read<DefectStore>().add(Defect(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    projectId: _projectId!,
                    title: _title.text.trim(),
                    description: _desc.text.trim(),
                    priority: _priority,
                    status: _status,
                  ));
              // очистка и возврат к списку
              _title.clear(); _desc.clear(); setState(() { _projectId = null; _priority = 3; _status = DefectStatus.open; });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Дефект зарегистрирован')));
            },
            child: const Text('Сохранить'),
          ),
        ]),
      ]),
    );
  }
}

class _EditDefectDialog extends StatefulWidget {
  final Defect defect;
  const _EditDefectDialog({required this.defect});

  @override
  State<_EditDefectDialog> createState() => _EditDefectDialogState();
}

class _EditDefectDialogState extends State<_EditDefectDialog> {
  late TextEditingController _title;
  late TextEditingController _desc;
  int _priority = 3;
  DefectStatus _status = DefectStatus.open;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.defect.title);
    _desc  = TextEditingController(text: widget.defect.description);
    _priority = widget.defect.priority;
    _status = widget.defect.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать дефект'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Заголовок')),
          const SizedBox(height: 12),
          TextField(controller: _desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Описание')),
          const SizedBox(height: 12),
          Row(children: [
            DropdownButton<int>(
              value: _priority,
              items: List.generate(5, (i) => i + 1)
                  .map((v) => DropdownMenuItem(value: v, child: Text('Приоритет $v')))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(width: 12),
            DropdownButton<DefectStatus>(
              value: _status,
              items: DefectStatus.values
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
              widget.defect.copyWith(
                title: _title.text.trim(),
                description: _desc.text.trim(),
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
