# Validation and first-device checklist

## Checks that do not need Flutter

From the project root:

```bash
python3 tool/validate_catalog.py
python3 -m unittest discover -s tool -p 'test_*.py' -v
bash -n scripts/bootstrap.sh scripts/android.sh START_ANDROID.command SETUP_MAC.command
python3 -m compileall -q tool
```

These validate data and scripting only. The Python search-normalization checks do not execute the Dart search code.

## Flutter tests — 16 passed on the Mac

```bash
bash scripts/bootstrap.sh
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

`test/search_test.dart`: accent folding and Chinese characters, aliases, multiword matching, relevance, cuisine/saved/initial filters, empty queries, real catalog validation.

`test/state_test.dart`: persistent snapshots, rapid serialized writes, MRU order, storage failures and retry, unreadable storage protection, missing-ID cleanup.

`test/widget_test.dart`: browse/search/save/detail navigation, alphabet reset, empty and unmatched search states, narrow screen and large text.

The integration test passed on the Pixel 9 Pro. To repeat it after resolving Android setup:

```bash
flutter devices
flutter test integration_test/app_test.dart -d YOUR_PIXEL_SERIAL
```

The integration test loads the real catalog and preferences and searches for Phở. Manual persistence and offline tests below are still necessary.

## First Pixel acceptance pass

1. Launch from the home-screen icon with USB disconnected; inspect the original art and all four tabs.
2. Browse Chinese; search `mapo tofu`, `xiao long bao`, `dan tat`, and `叉烧`. Check the matching aliases and definitions. Search globally for `pho`, `bun bo hue`, `pao de queijo`, and `kasespatzle`.
3. Search an unknown word; clear the search and recover a nonempty list. Pick an A–Z letter, then change the query and confirm the initial filter resets.
4. Bookmark two entries, remove one, force-close and relaunch. Confirm the remaining saved entry persists. This is the first actual OS-backed persistence check.
5. Open several entries; repeat one; verify history is newest-first with no duplicate IDs. Clear history in About and confirm bookmarks remain.
6. Switch to airplane mode and relaunch. Browse definitions, search, bookmark and copy a definition with no network.
7. Test system Back/predictive Back, keyboard dismissal, gesture navigation insets, rotation, large font/display size, and TalkBack labels. Inspect text in several scripts.
8. Rebuild on the same Mac and install using the script. Confirm existing bookmarks survive the update.

Do not certify a release until these pass. The debug build includes development tooling; use a signed release build for production performance, security and distribution checks.

## Known content and product limits

Historical definitions may contain errors. Eight duplicate-name groups are retained for review. The starter expansion contains 180 draft definitions, with selected reference URLs rather than full entry-by-entry sourcing. No allergen classification, food-safety determination, editorial override migration, bookmark export, cloud sync, photographs or pronunciation audio is implemented.
