import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager/data/project_store.dart';
import 'package:task_manager/models/project.dart';

void main() {
  // 1) Инициализируем Flutter binding для тестов
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2) Включаем мок для shared_preferences
  SharedPreferences.setMockInitialValues({});

  late ProjectStore store;

  setUp(() async {
    store = ProjectStore();
    await store.load(); // чтобы _items взялись из мок-хранилища
  });

  test('ProjectStore Добавление проекта увеличивает количество', () async {
    final p = const Project(id: '1', title: 'Test');
    await store.add(p);
    expect(store.items.length, 1);
    expect(store.items.first.title, 'Test');
  });

  test('ProjectStore Удаление проекта уменьшает количество', () async {
    final p = const Project(id: '1', title: 'Temp');
    await store.add(p);
    await store.remove('1');
    expect(store.items.isEmpty, true);
  });
}
