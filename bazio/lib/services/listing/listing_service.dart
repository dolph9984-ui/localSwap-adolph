import 'dart:io';
import 'package:bazio/core/constants/listing_constants.dart';
import 'package:bazio/core/utils/error_helpers.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  static const String _folder = 'listings';

  //check des bytes pour le format d'image
  String _detectMimeType(List<int> bytes) {
    if (bytes.length < 4) return 'application/octet-stream';
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'application/octet-stream';
  }

  String _mimeToExt(String mime) {
    switch (mime) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'bin';
    }
  }

  Stream<List<ListingModel>> getRecentListings() {
    return _firestore
        .collection('listings')
        .where('isSold', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  Stream<List<ListingModel>> getListingsByCategory(String category) {
    return _firestore
        .collection('listings')
        .where('isSold', isEqualTo: false)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) {
      final listings =
          snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }

  Stream<List<ListingModel>> getMyListings(String sellerId) {
    return _firestore
        .collection('listings')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  Future<List<ListingModel>> searchListings({
    required String query,
    String? category,
    String? condition,
    String? city,
    double? minPrice,
    double? maxPrice,
  }) async {
    Query q =
        _firestore.collection('listings').where('isSold', isEqualTo: false);

    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (condition != null && condition.isNotEmpty) {
      q = q.where('condition', isEqualTo: condition);
    }
    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }

    final snapshot = await q.get();
    var results =
        snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();

    if (minPrice != null) {
      results = results.where((l) => l.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      results = results.where((l) => l.price <= maxPrice).toList();
    }

    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      results = results
          .where((l) =>
              l.title.toLowerCase().contains(lower) ||
              l.description.toLowerCase().contains(lower))
          .toList();
    }

    return results;
  }

  //upload avec progression pour l'ui
  Future<List<String>> uploadImagesWithProgress(
    List<XFile> images,
    String sellerId, {
    void Function(int index)? onImageUploading,
    void Function(int index)? onImageDone,
    bool Function()? onCancelled,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Non authentifié');
    if (currentUser.uid != sellerId) throw Exception('Accès refusé');

    if (images.length > ListingConstants.maxImages) {
      throw Exception('Maximum ${ListingConstants.maxImages} photos par annonce.');
    }

    final List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      if (onCancelled?.call() == true) return [];

      onImageUploading?.call(i);

      final xfile = images[i];
      final bytes = await File(xfile.path).readAsBytes();

      if (bytes.length > ListingConstants.maxFileSizeBytes) {
        final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
        throw Exception(
            'L\'image "${xfile.name}" fait $mb MB. Maximum : 5 MB.');
      }

      final mime = _detectMimeType(bytes);
      if (!ListingConstants.allowedMimeTypes.contains(mime)) {
        throw Exception(
            'Format non supporté pour "${xfile.name}". Acceptés : JPEG, PNG, WebP.');
      }

      final ext = _mimeToExt(mime);
      final path = '$_folder/$sellerId/${_uuid.v4()}.$ext';
      final ref = _storage.ref(path);
      final task = ref.putData(bytes, SettableMetadata(contentType: mime));

      try {
        await task.snapshotEvents.forEach((_) {
          if (onCancelled?.call() == true) task.cancel();
        });
      } on FirebaseException catch (e) {
        if (e.code == 'storage/canceled') return [];
        throw Exception(humanizeError(e));
      } on SocketException {
        throw Exception(
            'Pas de connexion Internet. Vérifiez votre réseau et réessayez.');
      }

      if (onCancelled?.call() == true) return [];

      final url = await ref.getDownloadURL();
      urls.add(url);

      onImageDone?.call(i);
    }

    return urls;
  }

  Future<void> createListing(ListingModel listing) async {
    await _firestore.collection('listings').add(listing.toFirestore());
  }

  Future<void> updateListing({
    required String listingId,
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String city,
    required List<String> imageUrls,
    GeoPoint? location,
    String? brand,
    String? modelName,
    String? reference,
    String? size,
    String? color,
    String? material,
    double? weight,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Non authentifié');

    final updates = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'city': city,
      'imageUrls': imageUrls,
      'location': location,
      'brand': ?brand,
      'modelName': ?modelName,
      'reference': ?reference,
      'size': ?size,
      'color': ?color,
      'material': ?material,
      'weight': ?weight,
    };

    await _firestore
        .collection('listings')
        .doc(listingId)
        .update(updates);
  }

  Future<void> toggleSoldStatus(String listingId, bool isSold) async {
    await _firestore
        .collection('listings')
        .doc(listingId)
        .update({'isSold': isSold});
  }

  Future<void> deleteListing(ListingModel listing) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Non authentifié');
    if (currentUser.uid != listing.sellerId) {
      throw Exception('Accès refusé : ce n\'est pas votre annonce');
    }

    for (final url in listing.imageUrls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (_) {}
    }

    await _firestore.collection('listings').doc(listing.id).delete();
  }

  Stream<ListingModel> getListingById(String id) {
    return _firestore.collection('listings').doc(id).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Annonce introuvable');
      return ListingModel.fromFirestore(doc);
    });
  }

  Future<({List<ListingModel> listings, DocumentSnapshot? lastDoc})>
      getRecentListingsPaged({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    Query q = _firestore
        .collection('listings')
        .where('isSold', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    final listings =
        snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

    return (listings: listings, lastDoc: lastDoc);
  }

  Future<({List<ListingModel> listings, DocumentSnapshot? lastDoc})>
      getCategoryListingsPaged({
    required String category,
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    Query q = _firestore
        .collection('listings')
        .where('isSold', isEqualTo: false)
        .where('category', isEqualTo: category)
        .limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    final listings =
        snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
    listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

    return (listings: listings, lastDoc: lastDoc);
  }

  Future<ListingModel?> getListingOnce(String listingId) async {
    final doc =
        await _firestore.collection('listings').doc(listingId).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  //on coupe en 30 car firebase limite les whereIn
  Future<List<ListingModel>> getListingsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final List<ListingModel> results = [];
    const chunkSize = 30;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk =
          ids.sublist(i, i + chunkSize > ids.length ? ids.length : i + chunkSize);
      final snap = await _firestore
          .collection('listings')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map((doc) => ListingModel.fromFirestore(doc)));
    }
    return results;
  }
}