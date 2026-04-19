class UserLocationState {
  final double? latitude;
  final double? longitude;
  final String? city;

  const UserLocationState({
    this.latitude,
    this.longitude,
    this.city,
  });

  //on check si on a les coordonnees gps
  bool get hasPosition => latitude != null && longitude != null;
  //on verifie si on a au moins une info de localisation
  bool get hasAnyLocation => hasPosition || city != null;

  UserLocationState copyWith({
    double? latitude,
    double? longitude,
    String? city,
    bool clearPosition = false,
    bool clearCity = false,
  }) {
    return UserLocationState(
      latitude: clearPosition ? null : latitude ?? this.latitude,
      longitude: clearPosition ? null : longitude ?? this.longitude,
      city: clearCity ? null : city ?? this.city,
    );
  }
}