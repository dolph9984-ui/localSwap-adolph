import 'package:bazio/model/listing/listing_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bazio/services/listing/favorites_service.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';

class FavoritesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    //on recupere l'id de l'user sans passer par firebase direct
    final uid = ref.watch(authProvider)?.uid;
    if (uid == null) return [];

    ref.listen<AsyncValue<List<String>>>(
      _favoritesStreamProvider(uid),
      (_, next) {
        if (next is AsyncData<List<String>>) {
          state = next;
        }
      },
    );

    return await ref.read(_favoritesStreamProvider(uid).future);
  }

  Future<void> toggleFavorite(String listingId) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) return;

    final currentIds = state.value ?? [];
    final isFav = currentIds.contains(listingId);

    //maj optimiste pour que l'interface bouge sans attendre le serveur
    state = AsyncData(
      isFav
          ? currentIds.where((id) => id != listingId).toList()
          : [...currentIds, listingId],
    );

    try {
      await ref.read(favoritesServiceProvider).toggleFavorite(listingId);
    } catch (e) {
      //on annule le changement si l'appel reseau plante
      state = AsyncData(currentIds);
    }
  }
}

//on ecoute les changements en temps reel sur firestore
final _favoritesStreamProvider =
    StreamProvider.family<List<String>, String>((ref, uid) {
  return ref.read(favoritesServiceProvider).favoritesStream(uid);
});

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);

//on transforme les ids en objets complets pour l'affichage cote ui
final favoritesListingsProvider =
    FutureProvider<List<ListingModel>>((ref) async {
  final favIds = ref.watch(favoritesProvider).value;
  if (favIds == null || favIds.isEmpty) return [];
  return ref.read(listingServiceProvider).getListingsByIds(favIds);
});