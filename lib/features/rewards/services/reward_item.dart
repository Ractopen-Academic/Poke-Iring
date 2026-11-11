enum RewardType { catFood, welfareDonation, accessory }

class RewardItem {
  final String id;
  final String title;
  final String description;
  final int costPawPoints;
  final RewardType type;
  final String imageUrl;
  final String partnerName;
  final String badgeText;

  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.costPawPoints,
    required this.type,
    required this.imageUrl,
    required this.partnerName,
    required this.badgeText,
  });

  static const List<RewardItem> catalog = [
    RewardItem(
      id: 'catfood-pouch-1',
      title: 'Whiskas Wet Cat Food Pouch (85g)',
      description: 'Real mackerel & salmon wet pouch redeemable at participating partner pet hubs or delivered.',
      costPawPoints: 200,
      type: RewardType.catFood,
      imageUrl: 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=600&auto=format&fit=crop&q=80',
      partnerName: 'PetExpress PH / Local Hub',
      badgeText: 'Cat Food',
    ),
    RewardItem(
      id: 'catfood-kibble-1',
      title: 'Powercat Kitten & Adult Kibble (500g)',
      description: 'Organic Halal-certified premium dry cat food rich in natural taurine for street and shelter cats.',
      costPawPoints: 450,
      type: RewardType.catFood,
      imageUrl: 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?w=600&auto=format&fit=crop&q=80',
      partnerName: 'Bow & Wow Partner Store',
      badgeText: 'Dry Food',
    ),
    RewardItem(
      id: 'welfare-donation-caraph',
      title: 'CARA Welfare Philippines Feeding Meal',
      description: 'Funds 1 full hearty meal and clean hydration for rescued street puspins in CARA sanctuary.',
      costPawPoints: 150,
      type: RewardType.welfareDonation,
      imageUrl: 'https://images.unsplash.com/photo-1574158622682-e40e69881006?w=600&auto=format&fit=crop&q=80',
      partnerName: 'CARA Welfare PH',
      badgeText: 'Welfare Partner',
    ),
    RewardItem(
      id: 'welfare-donation-paws',
      title: 'PAWS Animal Rehabilitation Pledge',
      description: 'Direct sanctuary aid contribution supporting medical triage and puspin spay/neuter operations.',
      costPawPoints: 350,
      type: RewardType.welfareDonation,
      imageUrl: 'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=600&auto=format&fit=crop&q=80',
      partnerName: 'PAWS Philippines',
      badgeText: 'Rescue Support',
    ),
    RewardItem(
      id: 'welfare-donation-cebu',
      title: 'Cebu Stray Sanctuary Shelter Blanket & Care',
      description: 'Provides warm bedding and shelter protection for community cats across Central Visayas.',
      costPawPoints: 300,
      type: RewardType.welfareDonation,
      imageUrl: 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=600&auto=format&fit=crop&q=80',
      partnerName: 'Island Rescue 101 Cebu',
      badgeText: 'Local Shelter',
    ),
  ];
}

class RewardRedemption {
  final String id;
  final String userId;
  final String itemId;
  final String title;
  final int costPawPoints;
  final RewardType type;
  final DateTime timestamp;
  final String status;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.title,
    required this.costPawPoints,
    required this.type,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'itemId': itemId,
        'title': title,
        'costPawPoints': costPawPoints,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory RewardRedemption.fromJson(Map<String, dynamic> json) =>
      RewardRedemption(
        id: json['id'] as String,
        userId: json['userId'] as String,
        itemId: json['itemId'] as String,
        title: json['title'] as String,
        costPawPoints: json['costPawPoints'] as int,
        type: RewardType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => RewardType.catFood,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: json['status'] as String,
      );
}
