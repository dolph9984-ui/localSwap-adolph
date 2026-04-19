import 'dart:async';
import 'dart:io';
import 'package:bazio/core/constants/listing_constants.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/services/listing/listing_service.dart';
import 'package:bazio/viewmodels/publish/publish_state.dart';
import 'package:bazio/core/utils/error_helpers.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class PublishNotifier extends Notifier<PublishState> {
  late final ListingService _service;
  final ImagePicker _picker = ImagePicker();

  @override
  PublishState build() {
    _service = ref.read(listingServiceProvider);
    return const PublishState();
  }

  //on remplit le state avec les infos d'une annonce pour la modif
  void loadFromListing(ListingModel listing) {
    state = PublishState(
      imageItems: const [],
      existingImageUrls: List<String>.from(listing.imageUrls),
      city: listing.city,
      editingListingId: listing.id,
      position: listing.location != null
          ? _geoPointToPosition(listing.location!)
          : null,
    );
  }

  Position _geoPointToPosition(GeoPoint geo) {
    return Position(
      latitude: geo.latitude,
      longitude: geo.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  void removeExistingImage(int index) {
    final updated = [...state.existingImageUrls]..removeAt(index);
    state = state.copyWith(existingImageUrls: updated);
  }

  //selection de plusieurs images avec limite de nombre et de poids
  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;

    final totalExisting =
        state.existingImageUrls.length + state.imageItems.length;
    final valid = <XFile>[];

    for (final file in picked) {
      if (valid.length + totalExisting >= ListingConstants.maxImages) break;
      final bytes = await file.length();
      if (bytes > ListingConstants.maxFileSizeBytes) throw '"${file.name}" dépasse 5 MB';
      valid.add(file);
    }

    final newItems = valid
        .map((f) => ImageUploadItem(file: f, status: ImageUploadStatus.pending))
        .toList();

    state = state.copyWith(imageItems: [...state.imageItems, ...newItems]);
  }

  void removeImage(int index) {
    final updated = [...state.imageItems]..removeAt(index);
    state = state.copyWith(imageItems: updated);
  }

  void setCity(String city) => state = state.copyWith(city: city);

  //on recupere les coordonnees gps actuelles
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLocating: true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw 'Localisation désactivée';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission refusée';
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Active la localisation dans les paramètres';
      }

      final pos = await Geolocator.getCurrentPosition();
      state = state.copyWith(position: pos, isLocating: false);
    } catch (e) {
      state = state.copyWith(isLocating: false);
      rethrow;
    }
  }

  void clearLocation() => state = state.copyWith(clearPosition: true);

  //permet de reprendre la ou on s'etait arrete avec un brouillon
  void restoreFromDraft({
    required List<String> imagePaths,
    double? latitude,
    double? longitude,
    String? city,
  }) {
    final items = imagePaths
        .map(
          (path) => ImageUploadItem(
            file: XFile(path),
            status: ImageUploadStatus.pending,
          ),
        )
        .toList();

    Position? pos;
    if (latitude != null && longitude != null) {
      pos = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    state = state.copyWith(imageItems: items, position: pos, city: city);
  }

  //gere l'upload des images et la creation/maj de l'annonce
  Future<void> publishListing({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    String? brand,
    String? modelName,
    String? reference,
    String? size,
    String? color,
    String? material,
    double? weight,
  }) async {
    if (title.isEmpty) throw 'Titre requis';
    if (price <= 0) throw 'Prix invalide';
    if (state.city == null) throw 'Choisis une ville';

    //on check la connexion avant de lancer l'upload
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        throw 'Pas de connexion Internet. Vérifiez votre réseau et réessayez.';
      }
    } on SocketException {
      throw 'Pas de connexion Internet. Vérifiez votre réseau et réessayez.';
    } on TimeoutException {
      throw 'Connexion trop lente. Vérifiez votre réseau et réessayez.';
    }

    state = state.copyWith(isLoading: true);

    try {
      final user = ref.read(authProvider);
      if (user == null) throw 'Non connecté';

      List<String> newUrls = [];

      if (state.imageItems.isNotEmpty) {
        state = state.copyWith(isUploading: true);

        //upload des images avec maj de la barre de progression
        newUrls = await _service.uploadImagesWithProgress(
          state.imageItems.map((e) => e.file).toList(),
          user.uid,
          onImageUploading: (index) {
            final updated = state.imageItems.asMap().entries.map((e) {
              if (e.key < index) {
                return e.value.copyWith(status: ImageUploadStatus.done);
              } else if (e.key == index) {
                return e.value.copyWith(status: ImageUploadStatus.uploading);
              }
              return e.value;
            }).toList();
            state = state.copyWith(imageItems: updated);
          },
          onImageDone: (index) {
            final updated = state.imageItems.asMap().entries.map((e) {
              if (e.key <= index) {
                return e.value.copyWith(status: ImageUploadStatus.done);
              }
              return e.value;
            }).toList();
            state = state.copyWith(imageItems: updated);
          },
          onCancelled: () => false,
        );
      }

      final allImageUrls = [...state.existingImageUrls, ...newUrls];

      if (state.isEditing) {
        await _service.updateListing(
          listingId: state.editingListingId!,
          title: title,
          description: description,
          price: price,
          category: category,
          condition: condition,
          city: state.city!,
          imageUrls: allImageUrls,
          location: state.position != null
              ? GeoPoint(state.position!.latitude, state.position!.longitude)
              : null,
          brand: brand,
          modelName: modelName,
          reference: reference,
          size: size,
          color: color,
          material: material,
          weight: weight,
        );
      } else {
        final listing = ListingModel(
          id: '',
          sellerId: user.uid,
          sellerName: user.displayName ?? 'Inconnu',
          title: title,
          description: description,
          price: price,
          category: category,
          condition: condition,
          city: state.city!,
          imageUrls: allImageUrls,
          location: state.position != null
              ? GeoPoint(state.position!.latitude, state.position!.longitude)
              : null,
          createdAt: DateTime.now(),
          brand: brand,
          modelName: modelName,
          reference: reference,
          size: size,
          color: color,
          material: material,
          weight: weight,
        );
        await _service.createListing(listing);
      }

    } catch (e) {
      state = state.copyWith(isLoading: false, isUploading: false);
      throw humanizeError(e);
    }
  }
}

final publishProvider =
    NotifierProvider.autoDispose<PublishNotifier, PublishState>(
      PublishNotifier.new,
    );