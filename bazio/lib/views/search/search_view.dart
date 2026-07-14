import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/search/search_state.dart';
import 'package:bazio/viewmodels/search/search_history_notifier.dart';
import 'package:bazio/viewmodels/search/search_notifier.dart';
import 'package:bazio/views/search/widget/search_bar_widget.dart';
import 'package:bazio/views/search/widget/search_history_widget.dart';
import 'package:bazio/views/search/widget/search_results_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bazio/core/router/main_wrapper.dart';
import 'package:go_router/go_router.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
    _controller.addListener(_rebuild);
    // ecoute le trigger depuis la home pour activer le clavier
    ref.listenManual(searchFocusTriggerProvider, (_, __) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  //rebuild minimal pour mettre a jour l'affichage selon le focus et le texte
  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_rebuild);
    _controller.removeListener(_rebuild);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _doSearch(String query) {
    if (query.trim().isEmpty) return;
    //on sauvegarde dans l'historique avant de lancer la recherche
    ref.read(searchHistoryProvider.notifier).addSearch(query.trim());
    ref.read(searchNotifierProvider.notifier).search(query.trim());
    _focusNode.unfocus();
  }

  void _clear() {
    _controller.clear();
    ref.read(searchNotifierProvider.notifier).clearFilters();
  }

  void _openFilter() => context.push('/filters');

  void _openAllResults() {
    //on passe les resultats via extra pour rester dans GoRouter
    final state = ref.read(searchNotifierProvider);
    context.push('/search-results', extra: {
      'results': state.results,
      'query': state.query,
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final historyAsync = ref.watch(searchHistoryProvider);
    final hasActiveFilters = searchState.hasActiveFilters;
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.vLarge,
                  Text(
                    'Recherche',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.vLarge,

                  Stack(
                    children: [
                      SearchBarWidget(
                        controller: _controller,
                        focusNode: _focusNode,
                        onSubmitted: _doSearch,
                        onFilter: _openFilter,
                        onClear: _clear,
                      ),
                      //pastille rouge si des filtres sont actifs
                      if (hasActiveFilters)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.rouge,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),

                  AppSpacing.vSmall,

                  if (hasActiveFilters)
                    _ActiveFiltersRow(
                      state: searchState,
                      onClear: () => ref
                          .read(searchNotifierProvider.notifier)
                          .clearFilters(),
                    ),
                ],
              ),
            ),

            //header avec compteur de resultats et lien "tout voir"
            if (hasText &&
                !searchState.isLoading &&
                searchState.query == _controller.text.trim())
              _ResultsSectionHeader(
                count: searchState.results.length,
                query: searchState.query,
                onTapAll: searchState.results.isNotEmpty
                    ? _openAllResults
                    : null,
              ),

            Expanded(
              child: hasText
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SearchResultsGrid(
                        results: searchState.results,
                        isLoading: searchState.isLoading,
                        error: searchState.error,
                        query: searchState.query,
                      ),
                    )
                  : historyAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      //si le champ est vide on affiche l'historique
                      data: (history) => Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        child: SearchHistoryWidget(
                          history: history,
                          onTap: (q) {
                            _controller.text = q;
                            _doSearch(q);
                          },
                          onRemove: (q) => ref
                              .read(searchHistoryProvider.notifier)
                              .removeSearch(q),
                          onClear: () => ref
                              .read(searchHistoryProvider.notifier)
                              .clearHistory(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSectionHeader extends StatelessWidget {
  final int count;
  final String query;
  final VoidCallback? onTapAll;

  const _ResultsSectionHeader({
    required this.count,
    required this.query,
    this.onTapAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count résultat${count > 1 ? 's' : ''}',
                style: AppTextStyles.h3,
              ),
              if (query.isNotEmpty)
                Text(
                  'pour "$query"',
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
            ],
          ),
          if (onTapAll != null)
            GestureDetector(
              onTap: onTapAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tout voir',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//chips qui affichent les filtres actifs avec un bouton pour tout effacer
class _ActiveFiltersRow extends StatelessWidget {
  final SearchState state;
  final VoidCallback onClear;

  const _ActiveFiltersRow({required this.state, required this.onClear});

  String _fmt(double v) {
    return v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (state.category != null) chips.add(state.category!);
    if (state.condition != null) chips.add(state.condition!);
    if (state.minPrice != null || state.maxPrice != null) {
      final min = state.minPrice != null ? 'Ar ${_fmt(state.minPrice!)}' : '0';
      final max = state.maxPrice != null ? 'Ar ${_fmt(state.maxPrice!)}' : '∞';
      chips.add('$min – $max');
    }
    if (state.maxDistance != null) {
      chips.add('≤ ${state.maxDistance!.toInt()} km');
    }
    if (state.sortBy != SearchSortBy.recent) {
      const labels = {
        SearchSortBy.priceLow: 'Prix ↑',
        SearchSortBy.priceHigh: 'Prix ↓',
        SearchSortBy.distance: 'Distance',
      };
      chips.add(labels[state.sortBy] ?? '');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...chips.map(
            (c) => Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.rouge.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 12, color: AppColors.rouge),
                  SizedBox(width: 4),
                  Text(
                    'Effacer',
                    style: TextStyle(
                      color: AppColors.rouge,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}