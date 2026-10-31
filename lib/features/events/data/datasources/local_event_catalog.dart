import '../../domain/entities/feline_event.dart';
import '../../domain/entities/profile_border.dart';

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
