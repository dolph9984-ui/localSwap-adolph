import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/listing_constants.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/listing/pagination_notifiers.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllListingsByCategoryView extends ConsumerStatefulWidget {
  final String categoryValue;
  final String categoryLabel;
  final IconData categoryIcon;

  const AllListingsByCategoryView({
    super.key,
    required this.categoryValue,
    required this.categoryLabel,
    required this.categoryIcon,
  });

  factory AllListingsByCategoryView.fromParams(String value) {
    final cat = ListingConstants.categories.firstWhere(
      (c) => c['value'] == value,
      orElse: () => {'value': value, 'label': value, 'icon': Icons.category},
    );
    return AllListingsByCategoryView(
      categoryValue: value,
      categoryLabel: cat['label'] as String,
      categoryIcon: cat['icon'] as IconData,
    );
  }

  @override
  ConsumerState<AllListingsByCategoryView> createState() =>
      _AllListingsByCategoryViewState();
}

class _AllListingsByCategoryViewState
    extends ConsumerState<AllListingsByCategoryView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    //on remet a zero le provider de categorie a l'ouverture
    Future.microtask(
      () => ref.invalidate(categoryPaginatedProvider(widget.categoryValue)),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //charge plus d'annonces quand on approche du bas
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref
          .read(categoryPaginatedProvider(widget.categoryValue).notifier)
          .loadMore();
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(categoryPaginatedProvider(widget.categoryValue));
    await ref
        .read(categoryPaginatedProvider(widget.categoryValue).notifier)
        .loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryPaginatedProvider(widget.categoryValue));

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CustomAppBar(
                title: widget.categoryLabel,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : state.listings.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //compteur d'annonces avec indicateur "+" si il y en a encore
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            '${state.listings.length}${state.hasMore ? '+' : ''} annonce${state.listings.length > 1 ? 's' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _onRefresh,
                            child: GridView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                100,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                  ),
                              itemCount:
                                  state.listings.length +
                                  (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i == state.listings.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                }
                                return ListingCard(listing: state.listings[i]);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.categoryIcon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Aucune annonce en ${widget.categoryLabel}',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 10),
          Text(
            'Revenez bientôt, de nouvelles annonces arrivent !',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
