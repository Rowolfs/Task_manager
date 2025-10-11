import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/defect.dart';

class DefectStore extends ChangeNotifier {
  static const _k = 'defects';
  List<Defect> _items = [];
  List<Defect> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    _items = raw == null ? [] : Defect.decodeList(raw);
    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, Defect.encodeList(_items));
  }

  Future<void> add(Defect d) async {
    _items.add(d);
    await _persist();
    notifyListeners();
  }

  Future<void> update(Defect d) async {
    final i = _items.indexWhere((e) => e.id == d.id);
    if (i >= 0) {
      _items[i] = d;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> changeStatus(String id, DefectStatus s) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(status: s);
      await _persist();
      notifyListeners();
    }
  }

  List<Defect> byProject(String? projectId) {
    if (projectId == null || projectId.isEmpty) return items;
    return items.where((d) => d.projectId == projectId).toList();
  }
}
