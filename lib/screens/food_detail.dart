import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

void openFood(BuildContext context, AppState state, Food food) {
  unawaited(state.markViewed(food.id));
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => FoodDetail(state: state, food: food),
  ));
}

class FoodDetail extends StatelessWidget {
  const FoodDetail({super.key, required this.state, required this.food});
  final AppState state;
  final Food food;

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuisine = state.catalog.cuisinesById[food.cuisineId]!;
    final textTheme = Theme.of(context).textTheme;
    final aliases = food.aliases.where((a) => a != food.originalName).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(cuisine.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          ListenableBuilder(listenable: state, builder: (context, child) => IconButton(
            key: const Key('detail-save'),
            tooltip: state.isSaved(food.id) ? 'Remove from saved' : 'Save food',
            onPressed: () => unawaited(state.toggleSaved(food.id)),
            icon: Icon(state.isSaved(food.id) ? Icons.bookmark : Icons.bookmark_border),
          )),
        ],
      ),
      body: PageWidth(maxWidth: 700, child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        children: [
          Row(children: [
            CuisineBadge(cuisine: cuisine),
            const SizedBox(width: 12),
            Expanded(child: Text('${cuisine.name}  ·  ${food.category}',
              style: const TextStyle(color: GeColors.teal, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 24),
          SelectableText(food.name, style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800, height: 1.1)),
          if (aliases.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(aliases.join('  ·  '),
              style: const TextStyle(color: GeColors.muted, height: 1.6, fontSize: 16)),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: GeColors.yellow.withValues(alpha: .30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SelectableText(food.summary.isEmpty ? food.description : food.summary,
              style: textTheme.titleLarge?.copyWith(height: 1.5, fontWeight: FontWeight.w600)),
          ),
          if (food.description.isNotEmpty && food.description != food.summary && food.summary.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('On the menu', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SelectableText(food.description, style: const TextStyle(fontSize: 17, height: 1.65)),
          ],
          if (food.facts.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('From the original notes', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SelectableText(food.facts, style: const TextStyle(fontSize: 16, height: 1.6)),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _copy(context, [
              '${food.name} — ${cuisine.name}', food.summary,
              if (food.description != food.summary) food.description,
              'Global Eater · ${food.id}',
            ].where((s) => s.isNotEmpty).join('\n\n')),
            icon: const Icon(Icons.copy), label: const Text('Copy definition'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(food.isLegacy ? 'ORIGINAL CATALOG · 2010' : 'STARTER EXPANSION · DRAFT',
            style: const TextStyle(color: GeColors.muted, fontSize: 12,
              fontWeight: FontWeight.w800, letterSpacing: .7)),
          const SizedBox(height: 8),
          Text(food.isLegacy
              ? 'Preserved from your original dictionary. This definition has not '
                'yet been rechecked for the new edition.'
              : 'A starter definition for the expanded catalog. Editorial review is still pending.',
            style: const TextStyle(color: GeColors.muted, height: 1.5)),
          const SizedBox(height: 12),
          const Text('Recipes vary. Ask the restaurant about ingredients and '
            'preparation; this dictionary does not determine allergy safety.',
            style: TextStyle(color: GeColors.muted, height: 1.5)),
          if (food.referenceUrls.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Further reading', style: textTheme.titleSmall),
            for (final url in food.referenceUrls) ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Uri.parse(url).host,
                style: const TextStyle(color: GeColors.teal)),
              subtitle: Text(Uri.parse(url).path, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(tooltip: 'Copy reference URL',
                icon: const Icon(Icons.copy), onPressed: () => _copy(context, url)),
            ),
          ],
          const SizedBox(height: 16),
          SelectableText('Entry ${food.id}${food.sourceRow == null ? '' : ' · Original sheet row ${food.sourceRow}'}',
            style: const TextStyle(color: GeColors.muted, fontSize: 12)),
        ],
      )),
    );
  }
}
