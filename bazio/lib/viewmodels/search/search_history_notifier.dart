import 'package:bazio/services/search/search_history_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  late final SearchHistoryService _service;

  @override
  Future<List<String>> build() async {
    _service = ref.read(searchHistoryServiceProvider);
    return _service.getHistory();
  }

  Future<void> addSearch(String query) async {
    final current = state.asData?.value ?? [];
    //on met la nouvelle recherche en haut et on garde max 10 entrées
    final updated = [query, ...current.where((q) => q != query)]
        .take(10)
        .toList();
    state = AsyncData(updated);
    //sync firestore en arrière-plan pour pas bloquer
    await _service.addSearch(query);
  }

  Future<void> removeSearch(String query) async {
    //on supprime direct de la liste locale
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((q) => q != query).toList());
    //suppression côté serveur
    await _service.removeSearch(query);
  }

  Future<void> clearHistory() async {
    //on vide tout l'affichage d'un coup
    state = const AsyncData([]);
    //on clean la base de données
    await _service.clearHistory();
  }
}

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
        SearchHistoryNotifier.new);

        