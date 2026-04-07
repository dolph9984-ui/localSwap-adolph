import 'dart:io';
import 'package:bazio/core/model/listing_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  static const String _bucket = 'listings';
  static const int _maxImages = 8;
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  // ---------- LECTURE — Firestore ----------

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
    if (minPrice != null) {
      q = q.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      q = q.where('price', isLessThanOrEqualTo: maxPrice);
    }

    final snapshot = await q.get();
    final results =
        snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();

    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      return results
          .where((l) =>
              l.title.toLowerCase().contains(lower) ||
              l.description.toLowerCase().contains(lower))
          .toList();
    }

    return results;
  }

  // ---------- UPLOAD IMAGES — Supabase Storage ----------

  /// Valide et uploade jusqu'à [_maxImages] images.
  /// Règles : max 8 photos, 5 MB max/image, MIME : jpeg / png / webp.
  Future<List<String>> uploadImages(
      List<XFile> images, String sellerId) async {
    // 🔒 Auth Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Non authentifié');
    if (currentUser.uid != sellerId) throw Exception('Accès refusé');

    // ── Limite nombre d'images ──
    if (images.length > _maxImages) {
      throw Exception(
          'Vous pouvez ajouter au maximum $_maxImages photos par annonce.');
    }

    final List<String> urls = [];

    for (final xfile in images) {
      final bytes = await File(xfile.path).readAsBytes();

      // ── Taille max 5 MB ──
      if (bytes.length > _maxFileSizeBytes) {
        final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
        throw Exception(
            'L\'image "${xfile.name}" fait $mb MB. '
            'La taille maximale autorisée est de 5 MB.');
      }

      // ── MIME type ──
      final mime = _detectMimeType(bytes);
      if (!_allowedMimeTypes.contains(mime)) {
        throw Exception(
            'Format non supporté pour "${xfile.name}". '
            'Formats acceptés : JPEG, PNG, WebP.');
      }

      final ext = _mimeToExt(mime);
      final path = '$sellerId/${_uuid.v4()}.$ext';

      await _supabase.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mime,
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(path);
      urls.add(publicUrl);
    }

    return urls;
  }

  /// Détection MIME par magic bytes (sans dépendance externe).
  String _detectMimeType(List<int> bytes) {
    if (bytes.length < 4) return 'application/octet-stream';
    // JPEG : FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG : 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // WebP : 52 49 46 46 ?? ?? ?? ?? 57 45 42 50
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

  // ---------- ÉCRITURE — Firestore ----------

  Future<void> createListing(ListingModel listing) async {
    await _firestore.collection('listings').add(listing.toFirestore());
  }

  Future<void> markAsSold(String listingId) async {
    await _firestore
        .collection('listings')
        .doc(listingId)
        .update({'isSold': true});
  }

  Future<void> deleteListing(ListingModel listing) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Non authentifié');
    if (currentUser.uid != listing.sellerId) {
      throw Exception('Accès refusé : ce n\'est pas votre annonce');
    }

    for (final url in listing.imageUrls) {
      try {
        final uri = Uri.parse(url);
        final segments = uri.pathSegments;
        final bucketIndex = segments.indexOf(_bucket);
        if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
          final filePath = segments.sublist(bucketIndex + 1).join('/');
          await _supabase.storage.from(_bucket).remove([filePath]);
        }
      } catch (_) {}
    }

    await _firestore.collection('listings').doc(listing.id).delete();
  }
}