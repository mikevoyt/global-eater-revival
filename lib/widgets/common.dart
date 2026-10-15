import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.maxWidth = 900});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
  );
}

class CuisineBadge extends StatelessWidget {
  const CuisineBadge({super.key, required this.cuisine, this.size = 44});
  final Cuisine cuisine;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: GeColors.yellow.withValues(alpha: .36),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(cuisine.badge,
          maxLines: 1, style: const TextStyle(
            fontWeight: FontWeight.w900, fontSize: 16, color: GeColors.ink,
          ))),
      ),
    ),
  );
}

class FoodTile extends StatelessWidget {
  const FoodTile({super.key, required this.food, required this.state,
    required this.onTap, this.showCuisine = true});
  final Food food;
  final AppState state;
  final VoidCallback onTap;
  final bool showCuisine;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('food-${food.id}'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    title: Text(food.name, maxLines: 2, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(food.summary.isEmpty ? food.description : food.summary,
          maxLines: 2, overflow: TextOverflow.ellipsis),
        if (showCuisine) Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(state.catalog.cuisinesById[food.cuisineId]!.name,
            style: const TextStyle(color: GeColors.teal, fontSize: 12,
              fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
    trailing: ListenableBuilder(
      listenable: state,
      builder: (context, child) => IconButton(
        tooltip: state.isSaved(food.id) ? 'Remove ${food.name} from saved' : 'Save ${food.name}',
        onPressed: () => unawaited(state.toggleSaved(food.id)),
        icon: Icon(state.isSaved(food.id) ? Icons.bookmark : Icons.bookmark_border,
          color: state.isSaved(food.id) ? GeColors.teal : GeColors.muted),
      ),
    ),
    onTap: onTap,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message,
    this.icon = Icons.search_off, this.action});
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 44, color: GeColors.teal),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: GeColors.muted, height: 1.5)),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    ),
  );
}

/// Filtering by an available initial avoids unsafe scroll indices entirely.
class AlphabetFilter extends StatelessWidget {
  const AlphabetFilter({super.key, required this.available,
    required this.selected, required this.onSelected});
  final Set<String> available;
  final String? selected;
  final ValueChanged<String?> onSelected;
  @override
  Widget build(BuildContext context) {
    final letters = available.toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
          label: const Text('A–Z'), selected: selected == null,
          onSelected: (_) => onSelected(null))),
        for (final letter in letters)
          Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
            label: Text(letter), selected: selected == letter,
            onSelected: (_) => onSelected(selected == letter ? null : letter))),
      ]),
    );
  }
}
