import 'package:bazio/model/listing/listing_model.dart';

enum SearchSortBy { recent, priceLow, priceHigh, distance }

class SearchState {
  final List<ListingModel> results;
  final bool isLoading;
  final String? error;
  final String query;
  final String? category;
  final String? condition;
  final double? minPrice;
  final double? maxPrice;
  final double? maxDistance;
  final SearchSortBy sortBy;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.category,
    this.condition,
    this.minPrice,
    this.maxPrice,
    this.maxDistance,
    this.sortBy = SearchSortBy.recent,
  });

  bool get hasActiveFilters =>
      category != null ||
      condition != null ||
      minPrice != null ||
      maxPrice != null ||
      maxDistance != null ||
      sortBy != SearchSortBy.recent;

  SearchState copyWith({
    List<ListingModel>? results,
    bool? isLoading,
    String? error,
    String? query,
    String? category,
    String? condition,
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    SearchSortBy? sortBy,
    bool clearError = false,
    bool clearCategory = false,
    bool clearCondition = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMaxDistance = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      category: clearCategory ? null : category ?? this.category,
      condition: clearCondition ? null : condition ?? this.condition,
      minPrice: clearMinPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearMaxPrice ? null : maxPrice ?? this.maxPrice,
      maxDistance: clearMaxDistance ? null : maxDistance ?? this.maxDistance,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
