import 'package:bazio/viewmodels/listing/paginated_state.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentPaginatedNotifier extends Notifier<PaginatedState> {
  static const int _pageSize = 10;

  @override
  PaginatedState build() {
    //on lance le premier chargement direct au demarrage
    Future.microtask(() => loadFirst());
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, clearLastDoc: true);
    final result = await ref
        .read(listingServiceProvider)
        .getRecentListingsPaged(limit: _pageSize);
    state = PaginatedState(
      listings: result.listings,
      isLoading: false,
      hasMore: result.listings.length == _pageSize,
      lastDoc: result.lastDoc,
    );
  }

  Future<void> loadMore() async {
    //on evite de charger si c'est deja en cours ou s'il n'y a plus rien
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final result = await ref
        .read(listingServiceProvider)
        .getRecentListingsPaged(startAfter: state.lastDoc, limit: _pageSize);
    state = state.copyWith(
      listings: [...state.listings, ...result.listings],
      isLoadingMore: false,
      hasMore: result.listings.length == _pageSize,
      lastDoc: result.lastDoc,
    );
  }
}

final recentPaginatedProvider =
    NotifierProvider<RecentPaginatedNotifier, PaginatedState>(
      RecentPaginatedNotifier.new,
    );

class CategoryPaginatedNotifier extends Notifier<PaginatedState> {
  CategoryPaginatedNotifier(this.category);
  final String category;
  static const int _pageSize = 10;

  @override
  PaginatedState build() {
    Future.microtask(() => loadFirst());
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, clearLastDoc: true);
    final result = await ref
        .read(listingServiceProvider)
        .getCategoryListingsPaged(category: category, limit: _pageSize);
    state = PaginatedState(
      listings: result.listings,
      isLoading: false,
      hasMore: result.listings.length == _pageSize,
      lastDoc: result.lastDoc,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final result = await ref
        .read(listingServiceProvider)
        .getCategoryListingsPaged(
          category: category,
          startAfter: state.lastDoc,
          limit: _pageSize,
        );
    //on ajoute les nouveaux resultats a la suite de la liste actuelle
    state = state.copyWith(
      listings: [...state.listings, ...result.listings],
      isLoadingMore: false,
      hasMore: result.listings.length == _pageSize,
      lastDoc: result.lastDoc,
    );
  }
}

final categoryPaginatedProvider =
    NotifierProvider.family<CategoryPaginatedNotifier, PaginatedState, String>(
      CategoryPaginatedNotifier.new,
    );