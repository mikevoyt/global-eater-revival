import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'data/catalog.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});
  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  AppState? _state;
  bool _failed = false;

  @override
  void initState() { super.initState(); unawaited(_load()); }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final catalog = await Catalog.load();
      final state = AppState(catalog: catalog, store: PreferencesUserStore());
      await state.load();
      if (!mounted) { state.dispose(); return; }
      setState(() => _state = state);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() { _state?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_state != null) return GlobalEaterApp(state: _state!);
    return MaterialApp(
      debugShowCheckedModeBanner: false, theme: buildTheme(),
      home: Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 260),
            child: Image.asset('assets/brand/original_splash.png')),
          const SizedBox(height: 24),
          if (!_failed) const CircularProgressIndicator()
          else ...[
            const Text('The offline dictionary could not be loaded.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Try again')),
          ],
        ]),
      )))),
    );
  }
}
