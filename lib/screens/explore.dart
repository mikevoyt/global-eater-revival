import 'dart:math';
import 'package:flutter/material.dart';
import '../models/food.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'food_browser.dart';
import 'food_detail.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.state, required this.onSearch});
  final AppState state;
  final VoidCallback onSearch;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _region = 'All';
  static const regions = ['All', 'Asia', 'Europe', 'Americas', 'Africa', 'West Asia', 'Reference'];

  @override
  Widget build(BuildContext context) {
    final catalog = widget.state.catalog;
    final cuisines = catalog.cuisines.where((c) => _region == 'All' || c.region == _region).toList();
    return PageWidth(child: ListView(
      key: const PageStorageKey('explore'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFFEC77), GeColors.yellow, Color(0xFFFFB832)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: LayoutBuilder(builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/brand/original_splash.png',
                    width: constraints.maxWidth < 310 ? 76 : 98,
                    semanticLabel: 'Original Global Eater artwork by Elliot Ling')),
                const SizedBox(width: 18),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('THE WORLD,\nON YOUR MENU.',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21, height: 1.1)),
                  const SizedBox(height: 12),
                  const Text('Your reference guide to foods around the world.',
                    style: TextStyle(fontSize: 14, height: 1.45)),
                  const SizedBox(height: 14),
                  Text('${catalog.foods.length} entries · ${catalog.cuisineCount} cuisines',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ])),
              ],
            )),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            key: const Key('explore-search'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white, padding: const EdgeInsets.all(18),
              alignment: Alignment.centerLeft, side: const BorderSide(color: GeColors.line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: widget.onSearch,
            icon: const Icon(Icons.search, color: GeColors.teal),
            label: const Text('What’s on the menu?', style: TextStyle(color: GeColors.muted)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 18, 6),
          child: Row(children: [
            Expanded(child: Text('Explore cuisines', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800))),
            IconButton(
              tooltip: 'Surprise me with a food',
              onPressed: () => openFood(context, widget.state,
                catalog.foods[Random().nextInt(catalog.foods.length)]),
              icon: const Icon(Icons.shuffle, color: GeColors.teal),
            ),
          ]),
        ),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: regions.map((region) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(region), selected: _region == region,
              onSelected: (_) => setState(() => _region = region)),
          )).toList())),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 720 ? 3 : 2;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(spacing: 12, runSpacing: 12, children: cuisines.map((cuisine) => SizedBox(
              width: width,
              child: _CuisineCard(cuisine: cuisine, count: catalog.counts[cuisine.id] ?? 0,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => CuisinePage(state: widget.state, cuisineId: cuisine.id)))),
            )).toList());
          }),
        ),
        ListenableBuilder(listenable: widget.state, builder: (context, child) {
          final recent = widget.state.recent.take(3).toList();
          if (recent.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
              child: Text('Recently explored', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800))),
            for (final food in recent)
              FoodTile(food: food, state: widget.state,
                onTap: () => openFood(context, widget.state, food)),
          ]);
        }),
        const Padding(padding: EdgeInsets.fromLTRB(22, 20, 22, 8),
          child: Row(children: [
            Icon(Icons.offline_pin, size: 18, color: GeColors.teal),
            SizedBox(width: 8),
            Expanded(child: Text('Packed for travel. Every definition works offline.',
              style: TextStyle(color: GeColors.muted, fontSize: 12, height: 1.5))),
          ])),
      ],
    ));
  }
}

class _CuisineCard extends StatelessWidget {
  const _CuisineCard({required this.cuisine, required this.count, required this.onTap});
  final Cuisine cuisine;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: GeColors.line)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('cuisine-${cuisine.id}'),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CuisineBadge(cuisine: cuisine, size: 36),
          const SizedBox(height: 12),
          Text(cuisine.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('$count entries${cuisine.isNew ? ' · New' : ''}',
            style: const TextStyle(fontSize: 12, color: GeColors.muted)),
        ])),
    ),
  );
}
