import 'package:bazio/services/user/user_service.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/location/location_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class UserLocationNotifier extends AsyncNotifier<UserLocationState> {
  late final UserService _userService;

  @override
  Future<UserLocationState> build() async {
    _userService = ref.read(userServiceProvider);
    final uid = ref.read(authProvider)?.uid;
    
    if (uid == null) {
      return const UserLocationState();
    }

    try {
      //on recupere les donnees stockees au lancement
      final data = await _userService.getLocation(uid);
      return UserLocationState(
        latitude: (data['locationLat'] as num?)?.toDouble(),
        longitude: (data['locationLng'] as num?)?.toDouble(),
        city: data['locationCity'] as String?,
      );
    } catch (_) {
      return const UserLocationState();
    }
  }

  //juste pour avoir un apercu des coordonnees sans tout mettre a jour
  Future<({double latitude, double longitude})?> fetchLocationPreview() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      //nouvelle facon de demander la precision gps
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }

  //on enregistre la ville et le gps dans la db
  Future<void> saveAll({
    required String city,
    double? latitude,
    double? longitude,
    bool clearGps = false,
  }) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) {
      return;
    }

    final resolvedCity = city.trim().isNotEmpty ? city.trim() : null;
    final lat = clearGps ? null : latitude;
    final lng = clearGps ? null : longitude;

    final updates = <String, dynamic>{
      if (resolvedCity != null)
        'locationCity': resolvedCity
      else
        'locationCity': FieldValue.delete(),
      if (lat != null && lng != null) ...{
        'locationLat': lat,
        'locationLng': lng,
      } else ...{
        'locationLat': FieldValue.delete(),
        'locationLng': FieldValue.delete(),
      },
    };

    await _userService.saveLocation(uid, updates);

    state = AsyncData(UserLocationState(
      latitude: lat,
      longitude: lng,
      city: resolvedCity,
    ));
  }

  //on nettoie tout si l'user veut supprimer sa loc
  Future<void> clearLocation() async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) {
      return;
    }

    await _userService.saveLocation(uid, {
      'locationLat': FieldValue.delete(),
      'locationLng': FieldValue.delete(),
      'locationCity': FieldValue.delete(),
    });

    state = const AsyncData(UserLocationState());
  }

  //on remet l'ancienne valeur si jamais il annule ses modifs
  void restoreState(UserLocationState original) {
    state = AsyncData(original);
  }
}

final userLocationProvider =
    AsyncNotifierProvider<UserLocationNotifier, UserLocationState>(
  UserLocationNotifier.new,
);