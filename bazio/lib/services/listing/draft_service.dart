import 'package:bazio/model/listing/draft_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DraftService {
  static const _boxName = 'drafts';

  Box<DraftModel> get _box => Hive.box<DraftModel>(_boxName);
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  //liste les brouillons du compte du plus recent au plus ancien
  List<DraftModel> getDrafts() {
    final uid = _uid;
    if (uid == null) return [];
    final drafts = _box.values.where((d) => d.uid == uid).toList();
    drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return drafts;
  }

  //calcule le prochain numero de brouillon automatiquement
  int _nextNumber() {
    final uid = _uid;
    if (uid == null) return 1;
    final nums = _box.values
        .where((d) => d.uid == uid)
        .map((d) => d.draftNumber)
        .toList();
    return nums.isEmpty ? 1 : nums.reduce((a, b) => a > b ? a : b) + 1;
  }

  //sauvegarde un nouveau brouillon en local
  Future<void> saveDraft({
    required String title,
    required String description,
    double? price,
    String? category,
    String? condition,
    String? city,
    String? brand,
    String? modelName,
    String? size,
    String? color,
    List<String> imagePaths = const [],
    double? latitude,
    double? longitude,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _box.add(DraftModel(
      uid: uid,
      draftNumber: _nextNumber(),
      title: title,
      description: description,
      price: price,
      category: category,
      condition: condition,
      city: city,
      brand: brand,
      modelName: modelName,
      size: size,
      color: color,
      imagePaths: imagePaths,
      latitude: latitude,
      longitude: longitude,
      savedAt: DateTime.now(),
    ));
  }

  //ecrase et met a jour un brouillon existant
  Future<void> updateDraft(
    DraftModel existing, {
    required String title,
    required String description,
    double? price,
    String? category,
    String? condition,
    String? city,
    String? brand,
    String? modelName,
    String? size,
    String? color,
    List<String> imagePaths = const [],
    double? latitude,
    double? longitude,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _box.put(
      existing.key,
      DraftModel(
        uid: uid,
        draftNumber: existing.draftNumber,
        title: title,
        description: description,
        price: price,
        category: category,
        condition: condition,
        city: city,
        brand: brand,
        modelName: modelName,
        size: size,
        color: color,
        imagePaths: imagePaths,
        latitude: latitude,
        longitude: longitude,
        savedAt: DateTime.now(),
      ),
    );
  }

  //supprime un brouillon specifique
  Future<void> deleteDraft(DraftModel draft) async => await draft.delete();

  //vide tous les brouillons de ce compte
  Future<void> clearAllDrafts() async {
    final uid = _uid;
    if (uid == null) return;
    for (final d in _box.values.where((d) => d.uid == uid).toList()) {
      await d.delete();
    }
  }
}