import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/about.dart';
import 'screens/explore.dart';
import 'screens/food_browser.dart';

class GlobalEaterApp extends StatelessWidget {
  const GlobalEaterApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Global Eater', debugShowCheckedModeBanner: false,
    theme: buildTheme(), home: AppShell(state: state),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  static const titles = ['Global Eater', 'Food dictionary', 'Saved foods', 'About Global Eater'];

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        if (_tab == 0) ...[
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/brand/original_icon.png', width: 32, height: 32,
              excludeFromSemantics: true)),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(titles[_tab], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
      ]),
    ),
    body: Column(children: [
      ListenableBuilder(listenable: widget.state, builder: (context, child) {
        if (widget.state.storageError == null) return const SizedBox.shrink();
        return MaterialBanner(
          content: const Text('There is a problem with local saved-item storage.'),
          actions: [TextButton(onPressed: () => _selectTab(3), child: const Text('Details'))],
        );
      }),
      Expanded(child: IndexedStack(index: _tab, children: [
        ExplorePage(state: widget.state, onSearch: () => _selectTab(1)),
        FoodBrowser(state: widget.state),
        FoodBrowser(state: widget.state, onlySaved: true),
        AboutPage(state: widget.state),
      ])),
    ]),
    bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: _selectTab,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.public), label: 'Explore'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
        NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
      ],
    ),
  );
}
