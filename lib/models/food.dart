import 'package:diacritic/diacritic.dart';

/// Keep non-Latin scripts searchable and fold common Latin accents.
String normalizeSearch(String value) {
  final folded = removeDiacritics(value.toLowerCase())
      .replaceAll('ß', 'ss')
      .replaceAll('æ', 'ae')
      .replaceAll('œ', 'oe')
      .replaceAll('đ', 'd')
      .replaceAll('ı', 'i')
      .replaceAll('ł', 'l')
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  return folded
      .replaceAll(RegExp(r'''[.,/()'’\-_:;!?"“”]+'''), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid $field');
  }
  return value;
}

class Cuisine {
  Cuisine({
    required this.id,
    required this.name,
    required this.region,
    required this.badge,
    required this.isReference,
    required this.isNew,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) => Cuisine(
        id: requiredString(json, 'id'),
        name: requiredString(json, 'name'),
        region: requiredString(json, 'region'),
        badge: requiredString(json, 'badge'),
        isReference: json['isReference'] == true,
        isNew: json['isNew'] == true,
      );

  final String id;
  final String name;
  final String region;
  final String badge;
  final bool isReference;
  final bool isNew;
}

class Food {
  Food({
    required this.id,
    required this.cuisineId,
    required this.name,
    required this.summary,
    this.aliases = const [],
    this.description = '',
    this.category = 'Food term',
    this.facts = '',
    this.provenance = 'expansion',
    this.originalName = '',
    this.sourceRow,
    this.referenceUrls = const [],
  }) {
    nameKey = normalizeSearch(name);
    aliasKeys = aliases.map(normalizeSearch).toList(growable: false);
    summaryKey = normalizeSearch(summary);
    searchKey = normalizeSearch([
      name, ...aliases, originalName, summary, description, category,
      cuisineId, facts,
    ].join(' '));
  }

  factory Food.fromJson(Map<String, dynamic> json) => Food(
        id: requiredString(json, 'id'),
        cuisineId: requiredString(json, 'cuisineId'),
        name: requiredString(json, 'name'),
        summary: json['summary'] as String? ?? '',
        aliases: List<String>.unmodifiable(
          (json['aliases'] as List<dynamic>? ?? []).cast<String>(),
        ),
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'Food term',
        facts: json['facts'] as String? ?? '',
        provenance: json['provenance'] as String? ?? 'expansion',
        originalName: json['originalName'] as String? ?? '',
        sourceRow: json['sourceRow'] as int?,
        referenceUrls: List<String>.unmodifiable(
          (json['referenceUrls'] as List<dynamic>? ?? []).cast<String>(),
        ),
      );

  final String id;
  final String cuisineId;
  final String name;
  final List<String> aliases;
  final String summary;
  final String description;
  final String category;
  final String facts;
  final String provenance;
  final String originalName;
  final int? sourceRow;
  final List<String> referenceUrls;
  late final String nameKey;
  late final List<String> aliasKeys;
  late final String summaryKey;
  late final String searchKey;

  bool get isLegacy => provenance == 'legacy';
  String get initial {
    if (nameKey.isEmpty) return '#';
    final first = nameKey[0].toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(first) ? first : '#';
  }

  bool matches(String query) {
    final normalized = normalizeSearch(query);
    return normalized.isEmpty ||
        normalized.split(' ').every(searchKey.contains);
  }

  int relevance(String normalized) {
    if (normalized.isEmpty) return 0;
    if (nameKey == normalized || aliasKeys.contains(normalized)) return 0;
    if (summaryKey == normalized) return 1;
    if (nameKey.startsWith(normalized)) return 2;
    if (aliasKeys.any((a) => a.startsWith(normalized))) return 3;
    if (summaryKey.startsWith(normalized)) return 4;
    if (nameKey.contains(normalized)) return 5;
    if (aliasKeys.any((a) => a.contains(normalized))) return 6;
    return 7;
  }
}
