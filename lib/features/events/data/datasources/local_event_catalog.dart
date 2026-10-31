import '../../domain/entities/feline_event.dart';
import '../../domain/entities/profile_border.dart';

/// Offline fallback catalog and seeding source for events and profile borders.
///
/// Live events and active border rewards synchronize with the Firestore 'events'
/// collection. This catalog guarantees instant offline access and initial collection defaults.
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
}
