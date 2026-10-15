import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'food_detail.dart';

class FoodBrowser extends StatefulWidget {
  const FoodBrowser({super.key, required this.state, this.initialCuisineId,
    this.initialQuery = '', this.onlySaved = false});
  final AppState state;
  final String? initialCuisineId;
  final String initialQuery;
  final bool onlySaved;
  @override
  State<FoodBrowser> createState() => _FoodBrowserState();
}

class _FoodBrowserState extends State<FoodBrowser> {
  late final TextEditingController _query;
  String? _cuisineId;
  String? _initial;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    _cuisineId = widget.initialCuisineId;
  }

  @override
  void dispose() { _query.dispose(); super.dispose(); }

  void _clear() => setState(() {
    _query.clear(); _initial = null; _cuisineId = widget.initialCuisineId;
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, child) {
      final state = widget.state;
      final all = state.catalog.search(
        query: _query.text, cuisineId: _cuisineId,
        onlyIds: widget.onlySaved ? state.savedIds : null,
      );
      final foods = _initial == null ? all : all.where((f) => f.initial == _initial).toList();
      final noSaved = widget.onlySaved && state.savedIds.isEmpty;
      return PageWidth(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: TextField(
            key: Key(widget.onlySaved ? 'saved-search' : 'food-search'),
            controller: _query,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            onChanged: (_) => setState(() => _initial = null),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: widget.onlySaved ? 'Search saved foods' : 'Search foods and ingredients',
              hintText: 'Try “pho”, “dumplings”, or “saffron”',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.text.isEmpty ? null : IconButton(
                tooltip: 'Clear search', icon: const Icon(Icons.close),
                onPressed: () => setState(() { _query.clear(); _initial = null; })),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            const Icon(Icons.public, size: 20, color: GeColors.teal),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              key: const Key('cuisine-filter'),
              isExpanded: true, value: _cuisineId ?? '',
              items: [
                const DropdownMenuItem(value: '', child: Text('All cuisines')),
                ...state.catalog.cuisines.map((c) => DropdownMenuItem(
                  value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (value) => setState(() {
                _cuisineId = value == '' ? null : value;
                _initial = null;
              }),
            ))),
          ]),
        ),
        if (all.isNotEmpty) AlphabetFilter(
          available: all.map((f) => f.initial).toSet(), selected: _initial,
          onSelected: (value) => setState(() => _initial = value),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Align(alignment: Alignment.centerLeft,
            child: Text('${foods.length} ${foods.length == 1 ? 'entry' : 'entries'}'
                '${_query.text.trim().isEmpty ? ' · A–Z' : ' · Best matches first'}',
              style: const TextStyle(color: GeColors.muted, fontSize: 13))),
        ),
        const Divider(height: 1),
        Expanded(child: foods.isEmpty
          ? EmptyState(
              icon: noSaved ? Icons.bookmark_border : Icons.search_off,
              title: noSaved ? 'Your next great meal starts here.' : 'No matching foods',
              message: noSaved
                  ? 'Tap the bookmark beside any food to keep it here. Your saved list works offline.'
                  : 'Try a shorter spelling, another name, or a broader cuisine filter.',
              action: noSaved ? null : TextButton(onPressed: _clear, child: const Text('Clear search filters')),
            )
          : ListView.separated(
              key: PageStorageKey('food-list-${widget.onlySaved}-${widget.initialCuisineId}'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: foods.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (context, index) => FoodTile(food: foods[index], state: state,
                showCuisine: _cuisineId == null,
                onTap: () => openFood(context, state, foods[index])),
            )),
      ]));
    },
  );
}

class CuisinePage extends StatelessWidget {
  const CuisinePage({super.key, required this.state, required this.cuisineId});
  final AppState state;
  final String cuisineId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(state.catalog.cuisinesById[cuisineId]!.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
    body: FoodBrowser(state: state, initialCuisineId: cuisineId),
  );
}
