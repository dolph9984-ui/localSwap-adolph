import 'dart:io';
import 'package:bazio/services/user/user_service.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSettingsState {
  final bool isSaving;
  final bool isSaved;
  final String? phone;
  final bool isLoadingPhone;

  const ProfileSettingsState({
    this.isSaving = false,
    this.isSaved = false,
    this.phone,
    this.isLoadingPhone = false,
  });

  ProfileSettingsState copyWith({
    bool? isSaving,
    bool? isSaved,
    String? phone,
    bool? isLoadingPhone,
  }) {
    return ProfileSettingsState(
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      phone: phone ?? this.phone,
      isLoadingPhone: isLoadingPhone ?? this.isLoadingPhone,
    );
  }
}

class ProfileSettingsNotifier extends Notifier<ProfileSettingsState> {
  late final UserService _userService;

  @override
  ProfileSettingsState build() {
    _userService = ref.read(userServiceProvider);
    return const ProfileSettingsState();
  }

  //recupere le tel stocké dans la base
  Future<void> loadPhone() async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) return;
    state = state.copyWith(isLoadingPhone: true);
    try {
      final data = await _userService.getUserProfile(uid);
      state = state.copyWith(
        phone: data['phone'] as String? ?? '',
        isLoadingPhone: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingPhone: false);
    }
  }

  //envoie toutes les modifs du profil d'un coup (nom tel photo loc)
  Future<void> saveProfile({
    required String name,
    required String phone,
    File? pickedImage,
    required String city,
    double? pendingLat,
    double? pendingLng,
    required bool gpsCleared,
  }) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) throw Exception('Non authentifié');
    if (name.trim().isEmpty) throw Exception('Le nom est requis');

    state = state.copyWith(isSaving: true);

    try {
      String? photoUrl;

      //on upload l'image si l'user en a choisi une nouvelle
      if (pickedImage != null) {
        photoUrl = await _userService.uploadAvatar(uid: uid, file: pickedImage);
      }

      await _userService.updateProfile(
        uid: uid,
        name: name.trim(),
        phone: phone.trim(),
        photoUrl: photoUrl,
      );

      //maj de la localisation en parallele
      await ref.read(userLocationProvider.notifier).saveAll(
            city: city,
            latitude: pendingLat,
            longitude: pendingLng,
            clearGps: gpsCleared,
          );

      state = state.copyWith(isSaving: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

final profileSettingsProvider =
    NotifierProvider.autoDispose<ProfileSettingsNotifier, ProfileSettingsState>(
  ProfileSettingsNotifier.new,
);

//on recupere la date d'inscription via le service
final userCreatedAtProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  final uid = ref.watch(authProvider)?.uid;
  if (uid == null) return null;
  return ref.read(userServiceProvider).getCreatedAt(uid);
});

//on recupere l'email proprement meme si firebase auth galere a se refresh
final userEmailProvider = FutureProvider.autoDispose<String?>((ref) async {
  final uid = ref.watch(authProvider)?.uid;
  if (uid == null) return null;
  
  final firebaseEmail = ref.read(authProvider)?.email;
  if (firebaseEmail != null && firebaseEmail.isNotEmpty) return firebaseEmail;

  //si pas d'email dans auth on check la collection users
  final data = await ref.read(userServiceProvider).getUserProfile(uid);
  return data['email'] as String?;
});