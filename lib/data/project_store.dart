import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';


class ProjectStore extends ChangeNotifier {
  static const _k = 'projects';
  List<Project> _items = [];
  List<Project> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    _items = raw == null ? [] : Project.decodeList(raw);
    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, Project.encodeList(_items));
  }

  Future<void> add(Project p) async {
    _items.add(p);
    await _persist();
    notifyListeners();
  }

  Future<void> update(Project p) async {
    final i = _items.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      _items[i] = p;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> changeStatus(String id, ProjectStatus s) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(status: s);
      await _persist();
      notifyListeners();
    }
  }
}
