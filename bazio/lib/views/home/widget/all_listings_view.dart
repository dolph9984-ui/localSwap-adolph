import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/listing/pagination_notifiers.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ListingSort { recent, nearby }

class AllListingsView extends ConsumerStatefulWidget {
  final ListingSort sort;

  const AllListingsView({super.key, this.sort = ListingSort.recent});

  factory AllListingsView.fromSort(String? sortParam) {
    final s = sortParam == 'nearby' ? ListingSort.nearby : ListingSort.recent;
    return AllListingsView(sort: s);
  }

  @override
  ConsumerState<AllListingsView> createState() => _AllListingsViewState();
}

class _AllListingsViewState extends ConsumerState<AllListingsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    //on remet a zero la pagination quand on ouvre la vue
    if (widget.sort == ListingSort.recent) {
      Future.microtask(() => ref.invalidate(recentPaginatedProvider));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //charge la page suivante quand on approche du bas
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (widget.sort == ListingSort.recent) {
        ref.read(recentPaginatedProvider.notifier).loadMore();
      }
    }
  }

  String get _title =>
      widget.sort == ListingSort.nearby ? 'Près de vous' : 'Récentes';

  Future<void> _onRefresh() async {
    if (widget.sort == ListingSort.recent) {
      ref.invalidate(recentPaginatedProvider);
      await ref.read(recentPaginatedProvider.notifier).loadFirst();
    }
  }

  @override
  Widget build(BuildContext context) {
    //nearby utilise un stream en temps reel
    if (widget.sort == ListingSort.nearby) {
      final listingsAsync = ref.watch(nearbyListingsProvider);
      return listingsAsync.when(
        skipLoadingOnReload: true,
        loading: () => _buildLayout(
          title: _title,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, __) =>
            _buildLayout(title: _title, child: _buildEmptyState()),
        data: (listings) => _buildLayout(
          title: _title,
          child: listings.isEmpty
              ? _buildEmptyState()
              : _buildGrid(listings, hasMore: false),
        ),
      );
    }

    //recent utilise la pagination manuelle
    final state = ref.watch(recentPaginatedProvider);

    if (state.isLoading) {
      return _buildLayout(
        title: _title,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return _buildLayout(
      title: _title,
      child: state.listings.isEmpty
          ? _buildEmptyState()
          : _buildGrid(
              state.listings,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
            ),
    );
  }

  Widget _buildLayout({required String title, required Widget child}) {
    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CustomAppBar(
                title: title,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<ListingModel> listings, {
    required bool hasMore,
    bool isLoadingMore = false,
  }) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _onRefresh,
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: listings.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          //indicateur de chargement en bas de liste
          if (i == listings.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          return ListingCard(listing: listings[i]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isNearby = widget.sort == ListingSort.nearby;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNearby ? Icons.location_off_outlined : Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            isNearby
                ? 'Aucune annonce près de vous'
                : 'Aucune annonce pour l\'instant',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 10),
          Text(
            isNearby
                ? 'Essayez d\'élargir votre zone de recherche.'
                : 'Revenez bientôt, de nouvelles annonces arrivent !',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
