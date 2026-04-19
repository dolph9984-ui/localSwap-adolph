import 'package:bazio/core/utils/error_helpers.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/services/listing/listing_service.dart';
import 'package:bazio/viewmodels/search/search_state.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:bazio/core/utils/geo_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchNotifier extends Notifier<SearchState> {
  late final ListingService _service;

  @override
  SearchState build() {
    _service = ref.read(listingServiceProvider);
    return const SearchState();
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, query: query, clearError: true);
    try {
      //appel au service avec tous les filtres actifs
      var results = await _service.searchListings(
        query: query,
        category: state.category,
        condition: state.condition,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );
      results = _applyDistanceAndSort(results);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      //on affiche l'erreur propre à l'utilisateur
      state = state.copyWith(
        isLoading: false,
        error: humanizeError(e),
      );
    }
  }

  List<ListingModel> _applyDistanceAndSort(List<ListingModel> listings) {
    final location = ref.read(userLocationProvider).asData?.value;
    final hasGps = location?.hasPosition ?? false;
    var filtered = listings;

    //filtrage par rayon kilométrique si le gps est ok
    if (hasGps && state.maxDistance != null) {
      filtered = filtered.where((l) {
        if (l.location == null) return false;
        final dist = haversineKm(
          location!.latitude!,
          location.longitude!,
          l.location!.latitude,
          l.location!.longitude,
        );
        return dist <= state.maxDistance!;
      }).toList();
    }

    //tri selon le choix de l'user (prix, date ou distance)
    switch (state.sortBy) {
      case SearchSortBy.priceLow:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SearchSortBy.priceHigh:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SearchSortBy.distance:
        if (hasGps) {
          filtered.sort((a, b) {
            final dA = a.location == null
                ? double.infinity
                : haversineKm(
                    location!.latitude!,
                    location.longitude!,
                    a.location!.latitude,
                    a.location!.longitude,
                  );
            final dB = b.location == null
                ? double.infinity
                : haversineKm(
                    location!.latitude!,
                    location.longitude!,
                    b.location!.latitude,
                    b.location!.longitude,
                  );
            return dA.compareTo(dB);
          });
        }
        break;
      case SearchSortBy.recent:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return filtered;
  }

  void applyFilters({
    String? category,
    String? condition,
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    SearchSortBy? sortBy,
    bool clearCategory = false,
    bool clearCondition = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMaxDistance = false,
  }) {
    state = state.copyWith(
      category: category,
      condition: condition,
      minPrice: minPrice,
      maxPrice: maxPrice,
      maxDistance: maxDistance,
      sortBy: sortBy,
      clearCategory: clearCategory,
      clearCondition: clearCondition,
      clearMinPrice: clearMinPrice,
      clearMaxPrice: clearMaxPrice,
      clearMaxDistance: clearMaxDistance,
    );
    //on relance la recherche dès qu'un filtre change
    if (state.query.isNotEmpty) search(state.query);
  }

  void clearFilters() {
    //reset complet du state sauf la barre de recherche
    final q = state.query;
    state = SearchState(query: q);
    if (q.isNotEmpty) search(q);
  }
}

final searchNotifierProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);