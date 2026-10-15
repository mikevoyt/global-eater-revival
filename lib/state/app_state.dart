import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catalog.dart';
import '../models/food.dart';

abstract class UserStore {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesUserStore implements UserStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const key = 'global_eater.user_state.v1';

  @override
  Future<String?> read() => _prefs.getString(key);

  @override
  Future<void> write(String value) => _prefs.setString(key, value);
}

/// The same implementation is used in widget tests without platform channels.
class MemoryUserStore implements UserStore {
  MemoryUserStore([this.value]);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String next) async { value = next; }
}

class AppState extends ChangeNotifier {
  AppState({required this.catalog, required UserStore store}) : _store = store;

  final Catalog catalog;
  final UserStore _store;
  final Set<String> _saved = {};
  final List<String> _recent = [];
  Future<void> _writes = Future<void>.value();
  bool _readFailed = false;
  bool _disposed = false;
  String? storageError;

  Set<String> get savedIds => Set.unmodifiable(_saved);
  List<Food> get recent => _recent
      .map((id) => catalog.foodsById[id]).whereType<Food>().toList();
  bool isSaved(String id) => _saved.contains(id);

  Future<void> load() async {
    try {
      final encoded = await _store.read();
      final json = encoded == null
          ? <String, dynamic>{}
          : jsonDecode(encoded) as Map<String, dynamic>;
      if (json['schemaVersion'] != null && json['schemaVersion'] != 1) {
        throw const FormatException('Unsupported user state version');
      }
      final saved = (json['saved'] as List<dynamic>? ?? []).cast<String>();
      final recent = (json['recent'] as List<dynamic>? ?? []).cast<String>();
      _saved
        ..clear()
        ..addAll(saved.where(catalog.foodsById.containsKey));
      _recent
        ..clear()
        ..addAll(recent.where(catalog.foodsById.containsKey).toSet().take(25));
      _readFailed = false;
      storageError = null;
    } catch (_) {
      // Never overwrite unreadable storage with an empty favorites list.
      _readFailed = true;
      storageError = 'Saved items could not be loaded. Your stored data has not '
          'been changed. Retry storage in About.';
    }
    _notify();
  }

  Future<void> toggleSaved(String id) async {
    if (!catalog.foodsById.containsKey(id)) return;
    if (_readFailed) { _notify(); return; }
    if (!_saved.remove(id)) _saved.add(id);
    _notify();
    await _persist();
  }

  Future<void> markViewed(String id) async {
    if (!catalog.foodsById.containsKey(id) || _readFailed) return;
    _recent.remove(id);
    _recent.insert(0, id);
    if (_recent.length > 25) _recent.removeRange(25, _recent.length);
    _notify();
    await _persist();
  }

  Future<void> clearHistory() async {
    if (_readFailed) return;
    _recent.clear();
    _notify();
    await _persist();
  }

  Future<void> retryStorage() => _readFailed ? load() : _persist();

  Future<void> _persist() {
    if (_readFailed) return Future<void>.value();
    final snapshot = jsonEncode({
      'schemaVersion': 1, 'saved': _saved.toList()..sort(), 'recent': _recent,
    });
    // Serialize writes so fast taps cannot let an old snapshot win.
    _writes = _writes.then((_) async {
      try {
        await _store.write(snapshot);
        if (storageError != null) { storageError = null; _notify(); }
      } catch (_) {
        storageError = 'Your latest changes are only saved for this session. '
            'Retry storage in About before closing the app.';
        _notify();
      }
    });
    return _writes;
  }

  void _notify() { if (!_disposed) notifyListeners(); }

  @override
  void dispose() { _disposed = true; super.dispose(); }
}
