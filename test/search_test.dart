import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_eater/data/catalog.dart';
import 'package:global_eater/models/food.dart';
import 'fixtures.dart';

void main() {
  group('Search', () {
    final catalog = fixtureCatalog();
    test('folds Latin accents and keeps native scripts', () {
      expect(normalizeSearch('  Bún bò Huế '), 'bun bo hue');
      expect(normalizeSearch('Pão de queijo'), 'pao de queijo');
      expect(normalizeSearch('Käsespätzle'), 'kasespatzle');
      expect(normalizeSearch('Đậu'), 'dau');
      expect(normalizeSearch('叉烧'), '叉烧');
    });
    test('matches alternate spellings and original scripts', () {
      expect(catalog.search(query: 'pho').single.id, 'pho');
      expect(catalog.search(query: 'mapo tofu').single.id, 'mapo');
      expect(catalog.search(query: '麻婆豆腐').single.id, 'mapo');
    });
    test('uses all query words, regardless of their order', () {
      expect(catalog.search(query: 'meat spicy').single.id, 'mapo');
    });
    test('filters cuisine, saved IDs, and alphabet safely', () {
      expect(catalog.search(cuisineId: 'vietnamese'), hasLength(2));
      expect(catalog.search(onlyIds: <String>{}), isEmpty);
      expect(catalog.search(onlyIds: {'pho'}).single.id, 'pho');
      expect(catalog.search(initial: 'Z'), isEmpty);
      expect(catalog.search(initial: 'M').single.id, 'mapo');
    });
    test('has deterministic ranking', () {
      final ambiguous = Catalog(cuisines: catalog.cuisines, foods: [
        ...catalog.foods,
        Food(id: 'other', cuisineId: 'vietnamese', name: 'Another soup',
          summary: 'Unlike pho, this has a different broth.'),
      ]);
      expect(ambiguous.search(query: 'pho').first.id, 'pho');
    });
    test('empty and unmatched queries are safe', () {
      expect(catalog.search(), hasLength(4));
      expect(catalog.search(query: 'zzzzzz'), isEmpty);
    });
  });

  test('the complete shipped JSON catalog passes runtime validation', () {
    final foods = (jsonDecode(File('assets/data/foods.json').readAsStringSync()) as List)
        .map((f) => Food.fromJson(f as Map<String, dynamic>)).toList();
    final cuisines = (jsonDecode(File('assets/data/cuisines.json').readAsStringSync()) as List)
        .map((c) => Cuisine.fromJson(c as Map<String, dynamic>)).toList();
    final catalog = Catalog(foods: foods, cuisines: cuisines);
    final metadata = jsonDecode(File('assets/data/metadata.json').readAsStringSync()) as Map<String, dynamic>;
    expect(catalog.foods.length, metadata['totalEntries']);
    expect(catalog.foods.length, greaterThanOrEqualTo(1995));
    expect(catalog.cuisineCount, metadata['cuisineCount']);
    expect(catalog.referenceCount, 2);
    expect(catalog.search(query: 'pho').any((f) => f.id == 'v2-vietnamese-pho'), isTrue);
    expect(catalog.search(query: 'mapo tofu').first.id, 'legacy-0090');
  });
}
