import '../../domain/entities/feline_event.dart';
import '../../domain/entities/profile_border.dart';

// fallback if firestore is offline, also seeds events
class LocalEventCatalog {
  LocalEventCatalog._();

  static final List<ProfileBorder> borders = ProfileBorder.defaultBorders();

  static ProfileBorder? findBorder(String borderId) {
    try {
      return borders.firstWhere((b) => b.id == borderId);
    } catch (_) {
      return null;
    }
  }

  static FelineEvent get activeFestival => FelineEvent.defaultFestival();

  static List<FelineEvent> get defaultActiveEvents => [
    FelineEvent.defaultFestival(),
    FelineEvent.defaultPartnershipEvent(),
  ];
}
