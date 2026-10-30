class UserLocation {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? accuracy;
  final double? speed;
  final double? altitude;
  final DateTime timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.accuracy,
    this.speed,
    this.altitude,
    required this.timestamp,
  });

  factory UserLocation.fallback() {
    return UserLocation(
      latitude: 10.3140,
      longitude: 123.9720,
      heading: 0.0,
      accuracy: 5.0,
      speed: 0.0,
      altitude: 0.0,
      timestamp: DateTime.now(),
    );
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? accuracy,
    double? speed,
    double? altitude,
    DateTime? timestamp,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          heading == other.heading &&
          accuracy == other.accuracy &&
          speed == other.speed &&
          altitude == other.altitude;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, heading, accuracy, speed, altitude);
}
