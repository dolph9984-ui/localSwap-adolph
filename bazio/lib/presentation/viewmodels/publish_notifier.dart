import 'package:bazio/core/model/listing_model.dart';
import 'package:bazio/core/services/listing_service.dart';
import 'package:bazio/presentation/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/presentation/viewmodels/listing_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class PublishState {
  final List<XFile> images;
  final bool isLoading;
  final Position? position;
  final String? city;

  const PublishState({
    this.images = const [],
    this.isLoading = false,
    this.position,
    this.city,
  });

  PublishState copyWith({
    List<XFile>? images,
    bool? isLoading,
    Position? position,
    String? city,
    bool clearPosition = false,
  }) {
    return PublishState(
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      position: clearPosition ? null : position ?? this.position,
      city: city ?? this.city,
    );
  }
}

class PublishNotifier extends Notifier<PublishState> {
  late final ListingService _service;
  final ImagePicker _picker = ImagePicker();

  // on limite a 8 photos de 5mo max chacune
  static const int _maxImages = 8;
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  @override
  PublishState build() {
    _service = ref.read(listingServiceProvider);
    return const PublishState();
  }

  // selection des photos avec check du poids et du nombre
  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;

    final valid = <XFile>[];

    for (final file in picked) {
      if (valid.length + state.images.length >= _maxImages) break;

      final bytes = await file.length();
      if (bytes > _maxFileSizeBytes) {
        throw '"${file.name}" > 5MB';
      }

      valid.add(file);
    }

    state = state.copyWith(images: [...state.images, ...valid]);
  }

  void removeImage(int index) {
    final updated = [...state.images]..removeAt(index);
    state = state.copyWith(images: updated);
  }

  void setCity(String city) {
    state = state.copyWith(city: city);
  }

  // recupere les coordonnees gps apres verif des permissions
  Future<void> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw 'Localisation désactivée';

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permission refusée';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Active la localisation dans les paramètres';
    }

    final pos = await Geolocator.getCurrentPosition();
    state = state.copyWith(position: pos);
  }

  void clearLocation() {
    state = state.copyWith(clearPosition: true);
  }

  // envoie l annonce complete sur firestore et storage
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

    state = state.copyWith(isLoading: true);

    try {
      final user = ref.read(authProvider);
      if (user == null) throw 'Non connecté';

      // upload des images d abord pour avoir les liens
      List<String> imageUrls = [];
      if (state.images.isNotEmpty) {
        imageUrls = await _service.uploadImages(state.images, user.uid);
      }

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
        imageUrls: imageUrls,
        location: state.position != null
            ? GeoPoint(
                state.position!.latitude,
                state.position!.longitude,
              )
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

      // reset de l ecran apres succes
      state = const PublishState();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final publishProvider =
    NotifierProvider<PublishNotifier, PublishState>(PublishNotifier.new);