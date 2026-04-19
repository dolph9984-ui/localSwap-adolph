import 'package:bazio/model/listing/draft_model.dart';
import 'package:bazio/services/listing/draft_service.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final draftServiceProvider = Provider<DraftService>((_) => DraftService());

class DraftNotifier extends Notifier<List<DraftModel>> {
  late DraftService _service;

  @override
  List<DraftModel> build() {
    _service = ref.read(draftServiceProvider);

    //on rafraichit la liste des qu'un user se connecte ou se deconnecte
    final uid = ref.watch(authProvider)?.uid;
    if (uid == null) return [];
    return _service.getDrafts();
  }

  void _reload() {
    state = _service.getDrafts();
  }

  //creation d'un nouveau brouillon en local
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
    await _service.saveDraft(
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
    );
    _reload();
  }

  //mise a jour d'un brouillon qui existe deja
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
    await _service.updateDraft(
      existing,
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
    );
    _reload();
  }

  Future<void> deleteDraft(DraftModel draft) async {
    await _service.deleteDraft(draft);
    _reload();
  }

  Future<void> clearAllDrafts() async {
    await _service.clearAllDrafts();
    _reload();
  }
}

final draftProvider =
    NotifierProvider<DraftNotifier, List<DraftModel>>(DraftNotifier.new);