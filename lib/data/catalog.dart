import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/food.dart';

class Catalog {
  Catalog({required List<Food> foods, required List<Cuisine> cuisines})
      : foods = List.unmodifiable(foods),
        cuisines = List.unmodifiable(cuisines) {
    for (final cuisine in cuisines) {
      if (cuisinesById.containsKey(cuisine.id)) {
        throw FormatException('Duplicate cuisine ${cuisine.id}');
      }
      cuisinesById[cuisine.id] = cuisine;
    }
    for (final food in foods) {
      if (foodsById.containsKey(food.id)) {
        throw FormatException('Duplicate food ${food.id}');
      }
      if (!cuisinesById.containsKey(food.cuisineId)) {
        throw FormatException('Unknown cuisine ${food.cuisineId}');
      }
      if (food.summary.isEmpty && food.description.isEmpty) {
        throw FormatException('Missing definition for ${food.id}');
      }
      foodsById[food.id] = food;
      counts.update(food.cuisineId, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  static Future<Catalog> load({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final data = await Future.wait([
      source.loadString('assets/data/foods.json'),
      source.loadString('assets/data/cuisines.json'),
    ]);
    final foodJson = jsonDecode(data[0]) as List<dynamic>;
    final cuisineJson = jsonDecode(data[1]) as List<dynamic>;
    return Catalog(
      foods: foodJson.map((f) => Food.fromJson(f as Map<String, dynamic>)).toList(),
      cuisines: cuisineJson
          .map((c) => Cuisine.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  final List<Food> foods;
  final List<Cuisine> cuisines;
  final Map<String, Food> foodsById = {};
  final Map<String, Cuisine> cuisinesById = {};
  final Map<String, int> counts = {};

  int get cuisineCount => cuisines.where((c) => !c.isReference).length;
  int get referenceCount => cuisines.where((c) => c.isReference).length;

  List<Food> search({
    String query = '',
    String? cuisineId,
    String? initial,
    Set<String>? onlyIds,
  }) {
    final key = normalizeSearch(query);
    final tokens = key.split(' ').where((s) => s.isNotEmpty).toList();
    final results = foods.where((food) {
      if (cuisineId != null && food.cuisineId != cuisineId) return false;
      if (initial != null && food.initial != initial) return false;
      if (onlyIds != null && !onlyIds.contains(food.id)) return false;
      return tokens.every(food.searchKey.contains);
    }).toList();
    results.sort((a, b) {
      final rank = a.relevance(key).compareTo(b.relevance(key));
      if (rank != 0) return rank;
      final name = a.nameKey.compareTo(b.nameKey);
      return name != 0 ? name : a.id.compareTo(b.id);
    });
    return results;
  }
}
