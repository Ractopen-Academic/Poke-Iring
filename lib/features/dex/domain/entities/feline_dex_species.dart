enum FelineRarityTier { common, uncommon, rare, veryRare, mythic }

extension FelineRarityTierX on FelineRarityTier {
  String get displayName {
    switch (this) {
      case FelineRarityTier.common:
        return 'Common';
      case FelineRarityTier.uncommon:
        return 'Uncommon';
      case FelineRarityTier.rare:
        return 'Rare';
      case FelineRarityTier.veryRare:
        return 'Very Rare';
      case FelineRarityTier.mythic:
        return 'Mythic';
    }
  }

  double get defaultMultiplier {
    switch (this) {
      case FelineRarityTier.common:
        return 1.1;
      case FelineRarityTier.uncommon:
        return 1.3;
      case FelineRarityTier.rare:
        return 1.6;
      case FelineRarityTier.veryRare:
        return 1.8;
      case FelineRarityTier.mythic:
        return 2.0;
    }
  }
}

class FelineDexSpecies {
  final String id;
  final int dexNumber;
  final String name;
  final String commonName;
  final String coatPattern;
  final FelineRarityTier rarity;
  final String description;
  final String habitat;
  final String defaultSeed;

  const FelineDexSpecies({
    required this.id,
    required this.dexNumber,
    required this.name,
    required this.commonName,
    required this.coatPattern,
    required this.rarity,
    required this.description,
    required this.habitat,
    required this.defaultSeed,
  });

  String get formattedNumber => '#${dexNumber.toString().padLeft(3, '0')}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dexNumber': dexNumber,
      'name': name,
      'commonName': commonName,
      'coatPattern': coatPattern,
      'rarity': rarity.name,
      'description': description,
      'habitat': habitat,
      'defaultSeed': defaultSeed,
    };
  }

  factory FelineDexSpecies.fromMap(Map<String, dynamic> map) {
    return FelineDexSpecies(
      id: map['id'] as String? ?? 'dex_001',
      dexNumber: (map['dexNumber'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? 'Domestic Shorthair',
      commonName: map['commonName'] as String? ?? 'Classic Tabby Puspin',
      coatPattern: map['coatPattern'] as String? ?? 'Tabby',
      rarity: _parseRarity(map['rarity'] as String?),
      description: map['description'] as String? ?? '',
      habitat: map['habitat'] as String? ?? '',
      defaultSeed: map['defaultSeed'] as String? ?? 'Tabby Puspin 1',
    );
  }

  static FelineRarityTier _parseRarity(String? raw) {
    if (raw == null) return FelineRarityTier.common;
    for (final tier in FelineRarityTier.values) {
      if (tier.name.toLowerCase() == raw.toLowerCase()) {
        return tier;
      }
    }
    return FelineRarityTier.common;
  }

  FelineDexSpecies copyWith({
    String? id,
    int? dexNumber,
    String? name,
    String? commonName,
    String? coatPattern,
    FelineRarityTier? rarity,
    String? description,
    String? habitat,
    String? defaultSeed,
  }) {
    return FelineDexSpecies(
      id: id ?? this.id,
      dexNumber: dexNumber ?? this.dexNumber,
      name: name ?? this.name,
      commonName: commonName ?? this.commonName,
      coatPattern: coatPattern ?? this.coatPattern,
      rarity: rarity ?? this.rarity,
      description: description ?? this.description,
      habitat: habitat ?? this.habitat,
      defaultSeed: defaultSeed ?? this.defaultSeed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FelineDexSpecies &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  static const List<FelineDexSpecies> canonicalSpecies = [
    FelineDexSpecies(
      id: 'dex_001',
      dexNumber: 1,
      name: 'Domestic Shorthair',
      commonName: 'Classic Tabby Puspin',
      coatPattern: 'Tabby',
      rarity: FelineRarityTier.common,
      description: 'The iconic neighborhood explorer with agile reflexes and stripes suited for island sun.',
      habitat: 'Residential fences, sari-sari store porches',
      defaultSeed: 'Tabby Puspin 1',
    ),
    FelineDexSpecies(
      id: 'dex_002',
      dexNumber: 2,
      name: 'Puspin Calico',
      commonName: 'Tricolor Fortune Cat',
      coatPattern: 'Calico',
      rarity: FelineRarityTier.uncommon,
      description: 'Celebrated for vibrant tri-colored patches believed to bring good fortune to homeowners.',
      habitat: 'Awnings, flowerpots, rooftop edges',
      defaultSeed: 'Calico Puspin 2',
    ),
    FelineDexSpecies(
      id: 'dex_003',
      dexNumber: 3,
      name: 'Puspin Tortoiseshell',
      commonName: 'Tortie Guardian',
      coatPattern: 'Tortoiseshell',
      rarity: FelineRarityTier.uncommon,
      description: 'Spirited feline with rich mottled amber, gold, and dark patches and bold personality.',
      habitat: 'Garden thickets, mango tree bases',
      defaultSeed: 'Tortoiseshell 3',
    ),
    FelineDexSpecies(
      id: 'dex_004',
      dexNumber: 4,
      name: 'Puspin Tuxedo',
      commonName: 'Dapper Night Patrol',
      coatPattern: 'Tuxedo',
      rarity: FelineRarityTier.common,
      description: 'Crisp black coat with white chest bib and white mittens, always dressed for patrol duty.',
      habitat: 'Sports complexes, barangay halls',
      defaultSeed: 'Tuxedo 4',
    ),
    FelineDexSpecies(
      id: 'dex_005',
      dexNumber: 5,
      name: 'Ginger Puspin',
      commonName: 'Marmalade Sunbasker',
      coatPattern: 'Orange Tabby',
      rarity: FelineRarityTier.common,
      description: 'Playful orange feline with a single shared thought and exceptional midday loafing skills.',
      habitat: 'Warm tricycle seats, tin roofs',
      defaultSeed: 'Ginger Puspin 5',
    ),
    FelineDexSpecies(
      id: 'dex_006',
      dexNumber: 6,
      name: 'Midnight Puspin',
      commonName: 'Solid Black Shadow',
      coatPattern: 'Solid Black',
      rarity: FelineRarityTier.common,
      description: 'Sleek ebony coat with gleaming green or copper eyes, master of neighborhood stealth.',
      habitat: 'Quiet alleyways, vehicle shade',
      defaultSeed: 'Midnight Shadow 6',
    ),
    FelineDexSpecies(
      id: 'dex_007',
      dexNumber: 7,
      name: 'Cloud Puspin',
      commonName: 'Solid White Ghost',
      coatPattern: 'Solid White',
      rarity: FelineRarityTier.rare,
      description: 'Striking pure white feline often gifted with heterochromia odd-eyes.',
      habitat: 'Sunlit verandas, tiled doorways',
      defaultSeed: 'Cloud Puspin 7',
    ),
    FelineDexSpecies(
      id: 'dex_008',
      dexNumber: 8,
      name: 'Siamese',
      commonName: 'Wichien Maat Point',
      coatPattern: 'Colorpoint',
      rarity: FelineRarityTier.rare,
      description: 'Elegant ancient breed characterized by vivid blue almond eyes and deep espresso color points.',
      habitat: 'Gated courtyards, quiet balconies',
      defaultSeed: 'Siamese 8',
    ),
    FelineDexSpecies(
      id: 'dex_009',
      dexNumber: 9,
      name: 'Persian',
      commonName: 'Fluff Monarch',
      coatPattern: 'Longhair Solid',
      rarity: FelineRarityTier.veryRare,
      description: 'Luxurious long coat and calm dignified demeanor, rarely venturing into rough streets.',
      habitat: 'Indoor window perches, manicured lawns',
      defaultSeed: 'Persian 9',
    ),
    FelineDexSpecies(
      id: 'dex_010',
      dexNumber: 10,
      name: 'British Shorthair',
      commonName: 'Cheshire Round Loaf',
      coatPattern: 'Solid Blue',
      rarity: FelineRarityTier.rare,
      description: 'Dense plush blue-gray coat and chubby cheeks with distinctive calm curiosity.',
      habitat: 'Cozy cafes, indoor verandas',
      defaultSeed: 'British Shorthair 10',
    ),
    FelineDexSpecies(
      id: 'dex_011',
      dexNumber: 11,
      name: 'Bengal',
      commonName: 'Miniature Leopard',
      coatPattern: 'Rosetted',
      rarity: FelineRarityTier.mythic,
      description: 'Exotic wild-patterned coat with rosettes and high energy, an extraordinary neighborhood encounter.',
      habitat: 'Tree branches, secured perimeters',
      defaultSeed: 'Bengal Leopard 11',
    ),
    FelineDexSpecies(
      id: 'dex_012',
      dexNumber: 12,
      name: 'Scottish Fold',
      commonName: 'Owl-Eared Sweetheart',
      coatPattern: 'Folded Tabby',
      rarity: FelineRarityTier.veryRare,
      description: 'Charming forward-folded ears and large expressive owl eyes that capture hearts immediately.',
      habitat: 'Soft cushions, open doorways',
      defaultSeed: 'Scottish Fold 12',
    ),
    FelineDexSpecies(
      id: 'dex_013',
      dexNumber: 13,
      name: 'Ragdoll',
      commonName: 'Sapphire Ragdoll',
      coatPattern: 'Mitted Point',
      rarity: FelineRarityTier.veryRare,
      description: 'Docile, placid cat known for going limp in gentle arms and piercing sapphire gaze.',
      habitat: 'Quiet living rooms, garden gazebos',
      defaultSeed: 'Ragdoll 13',
    ),
    FelineDexSpecies(
      id: 'dex_014',
      dexNumber: 14,
      name: 'Russian Blue',
      commonName: 'Emerald Gaze Blue',
      coatPattern: 'Silvery Slate',
      rarity: FelineRarityTier.rare,
      description: 'Silvery shimmer across a dense double coat accented by vivid emerald green eyes.',
      habitat: 'Quiet shady lanes, high vantage walls',
      defaultSeed: 'Russian Blue 14',
    ),
    FelineDexSpecies(
      id: 'dex_015',
      dexNumber: 15,
      name: 'Maine Coon',
      commonName: 'Gentle Island Giant',
      coatPattern: 'Tufted Shag',
      rarity: FelineRarityTier.mythic,
      description: 'Majestic feline with lynx ear tufts, lion ruff mane, and enormous gentle presence.',
      habitat: 'Spacious gardens, sea breeze perches',
      defaultSeed: 'Maine Coon 15',
    ),
    FelineDexSpecies(
      id: 'dex_016',
      dexNumber: 16,
      name: 'Sphynx',
      commonName: 'Sunstone Guardian',
      coatPattern: 'Hairless Chamois',
      rarity: FelineRarityTier.mythic,
      description: 'Warm chamois suede-like skin and big bat ears, warmth-seeking companion found in shaded spots.',
      habitat: 'Heated indoor mats, shaded sun spots',
      defaultSeed: 'Sphynx 16',
    ),
  ];
}
