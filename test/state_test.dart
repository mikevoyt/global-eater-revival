import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_eater/state/app_state.dart';
import 'fixtures.dart';

class FailingStore implements UserStore {
  bool failRead = false;
  bool failWrite = true;
  String? value;
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('Read failed');
    return value;
  }
  @override
  Future<void> write(String next) async {
    if (failWrite) throw StateError('Write failed');
    value = next;
  }
}

void main() {
  test('saved foods and recent lookups survive a new app state', () async {
    final store = MemoryUserStore();
    final a = AppState(catalog: fixtureCatalog(), store: store);
    await a.load();
    await a.toggleSaved('pho');
    await a.markViewed('pho');
    final b = AppState(catalog: fixtureCatalog(), store: store);
    await b.load();
    expect(b.isSaved('pho'), isTrue);
    expect(b.recent.single.id, 'pho');
    a.dispose(); b.dispose();
  });
  test('serializes rapid writes and removes duplicate history', () async {
    final store = MemoryUserStore();
    final state = AppState(catalog: fixtureCatalog(), store: store);
    await state.load();
    await Future.wait([state.toggleSaved('pho'), state.toggleSaved('pho'), state.toggleSaved('mapo')]);
    await state.markViewed('pho'); await state.markViewed('mapo'); await state.markViewed('pho');
    final snapshot = jsonDecode(store.value!) as Map<String, dynamic>;
    expect(snapshot['saved'], ['mapo']);
    expect(state.recent.map((f) => f.id).toList(), ['pho', 'mapo']);
    await state.clearHistory();
    expect(state.recent, isEmpty);
    expect(state.isSaved('mapo'), isTrue);
    state.dispose();
  });
  test('write failure is visible and can be retried', () async {
    final store = FailingStore();
    final state = AppState(catalog: fixtureCatalog(), store: store);
    await state.load(); await state.toggleSaved('pho');
    expect(state.storageError, isNotNull);
    expect(state.isSaved('pho'), isTrue);
    store.failWrite = false;
    await state.retryStorage();
    expect(state.storageError, isNull);
    expect(store.value, contains('pho'));
    state.dispose();
  });
  test('corrupt storage is not overwritten', () async {
    final store = MemoryUserStore('not valid JSON');
    final state = AppState(catalog: fixtureCatalog(), store: store);
    await state.load(); await state.toggleSaved('pho');
    expect(state.storageError, isNotNull);
    expect(store.value, 'not valid JSON');
    expect(state.isSaved('pho'), isFalse);
    state.dispose();
  });
  test('missing catalog IDs are dropped without crashing', () async {
    final store = MemoryUserStore(jsonEncode({'schemaVersion':1,'saved':['missing','pho'],'recent':['missing','pho','pho']}));
    final state = AppState(catalog: fixtureCatalog(), store: store);
    await state.load();
    expect(state.savedIds, {'pho'});
    expect(state.recent, hasLength(1));
    state.dispose();
  });
}
