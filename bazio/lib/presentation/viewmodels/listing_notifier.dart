import 'package:bazio/core/model/listing_model.dart';
import 'package:bazio/core/services/listing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listingServiceProvider =
    Provider<ListingService>((_) => ListingService());

// recupere les dernieres annonces en direct de firestore
final recentListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  return ref.watch(listingServiceProvider).getRecentListings();
});

// filtre les annonces par vendeur pour la partie profil
final myListingsProvider =
    StreamProvider.family<List<ListingModel>, String>((ref, sellerId) {
  return ref.watch(listingServiceProvider).getMyListings(sellerId);
});

class SearchState {
  final List<ListingModel> results;
  final bool isLoading;
  final String? error;
  final String query;
  final String? category;
  final String? condition;
  final double? minPrice;
  final double? maxPrice;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.category,
    this.condition,
    this.minPrice,
    this.maxPrice,
  });

  // sert a mettre a jour l etat sans tout reecrire
  SearchState copyWith({
    List<ListingModel>? results,
    bool? isLoading,
    String? error,
    String? query,
    String? category,
    String? condition,
    double? minPrice,
    double? maxPrice,
    bool clearError = false,
    bool clearCategory = false,
    bool clearCondition = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      category: clearCategory ? null : category ?? this.category,
      condition: clearCondition ? null : condition ?? this.condition,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  late final ListingService _service;

  @override
  SearchState build() {
    _service = ref.read(listingServiceProvider);
    return const SearchState();
  }

  // lance la recherche avec les filtres actuels
  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, query: query, clearError: true);
    try {
      final results = await _service.searchListings(
        query: query,
        category: state.category,
        condition: state.condition,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la recherche',
      );
    }
  }

  // applique les filtres et relance la recherche si besoin
  void applyFilter({
    String? category,
    String? condition,
    double? minPrice,
    double? maxPrice,
    bool clearCategory = false,
    bool clearCondition = false,
  }) {
    state = state.copyWith(
      category: category,
      condition: condition,
      minPrice: minPrice,
      maxPrice: maxPrice,
      clearCategory: clearCategory,
      clearCondition: clearCondition,
    );
    if (state.query.isNotEmpty) search(state.query);
  }

  // remise a zero de tout le formulaire de recherche
  void clearFilters() {
    state = const SearchState(query: '');
  }
}

final searchNotifierProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);