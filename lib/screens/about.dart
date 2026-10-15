import 'dart:async';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.state});
  final AppState state;

  Future<void> _clearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Clear recent lookups?'),
      content: const Text('Your saved foods will not be removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear history')),
      ],
    ));
    if (confirmed == true) await state.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = state.catalog;
    final legacy = catalog.foods.where((f) => f.isLegacy).length;
    return PageWidth(maxWidth: 700, child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        Center(child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Image.asset('assets/brand/original_splash.png', width: 240,
            semanticLabel: 'The original 2009 Global Eater splash screen'))),
        const SizedBox(height: 26),
        Text('Same curious appetite.\nA new chapter.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        const Text('Created by Mike Voytovich and Harry Kwan.\n'
          'Original icon and splash artwork by Elliot Ling.',
          style: TextStyle(fontSize: 16, height: 1.7)),
        const SizedBox(height: 24),
        _Section(title: 'The dictionary', text:
          '${catalog.foods.length} entries across ${catalog.cuisineCount} cuisines, '
          'plus ${catalog.referenceCount} reference sections. '
          '$legacy entries were recovered from the original 2010 spreadsheet. '
          '${catalog.foods.length - legacy} starter entries extend the collection.'),
        const _Section(title: 'A catalog worth reviewing', text:
          'Original definitions are preserved, including historical spellings and '
          'possible errors. New definitions are drafts. Cuisine labels help browsing; '
          'they are not exclusive claims about where a food belongs. '
          'Recipes vary, and this is not an allergy-safety guide.'),
        const _Section(title: 'Works wherever you eat', text:
          'All definitions and artwork are included in the app. No login, '
          'subscription, advertising, analytics, or cloud service is used. '
          'Saved foods and recent lookups use local device storage.'),
        ListenableBuilder(listenable: state, builder: (context, child) {
          if (state.storageError == null) return const SizedBox.shrink();
          return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state.storageError!),
              const SizedBox(height: 8),
              TextButton(onPressed: () => unawaited(state.retryStorage()),
                child: const Text('Retry storage')),
            ])));
        }),
        ListTile(contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history), title: const Text('Clear recent lookups'),
          subtitle: const Text('Keeps your saved foods'), onTap: () => _clearHistory(context)),
        ListTile(contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.code), title: const Text('Open-source licenses'),
          onTap: () => showLicensePage(context: context,
            applicationName: 'Global Eater', applicationVersion: '0.1.0',
            applicationLegalese: 'Original artwork and catalog retain their original rights.')),
        const SizedBox(height: 20),
        const Text('GLOBAL EATER 0.1.0 · ANDROID-FIRST REVIVAL',
          style: TextStyle(fontSize: 11, color: GeColors.muted, letterSpacing: .6)),
      ],
    ));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(text, style: const TextStyle(fontSize: 15, height: 1.65, color: GeColors.muted)),
    ]),
  );
}
