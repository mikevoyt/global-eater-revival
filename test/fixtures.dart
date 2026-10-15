import 'package:global_eater/data/catalog.dart';
import 'package:global_eater/models/food.dart';

Catalog fixtureCatalog() => Catalog(
  cuisines: [
    Cuisine(id: 'vietnamese', name: 'Vietnamese', region: 'Asia', badge: 'VN', isReference: false, isNew: true),
    Cuisine(id: 'chinese', name: 'Chinese', region: 'Asia', badge: 'CN', isReference: false, isNew: false),
    Cuisine(id: 'greek', name: 'Greek', region: 'Europe', badge: 'GR', isReference: false, isNew: true),
  ],
  foods: [
    Food(id: 'pho', cuisineId: 'vietnamese', name: 'Phở', aliases: ['pho'],
      summary: 'Rice noodles in aromatic beef or chicken broth.'),
    Food(id: 'bun', cuisineId: 'vietnamese', name: 'Bún bò Huế', aliases: ['bun bo hue'],
      summary: 'A spicy beef noodle soup.'),
    Food(id: 'mapo', cuisineId: 'chinese', name: 'Ma Poh dow fu', aliases: ['mapo tofu', '麻婆豆腐'],
      summary: 'Spicy tofu with minced meat.', provenance: 'legacy'),
    Food(id: 'souvlaki', cuisineId: 'greek', name: 'Souvlaki', summary: 'Grilled meat skewers.'),
  ],
);
