import 'package:bazio/core/components/app_button.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/viewmodels/search/search_state.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/search/search_notifier.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:bazio/views/search/filter/widget/filter_category_section.dart';
import 'package:bazio/views/search/filter/widget/filter_condition_section.dart';
import 'package:bazio/views/search/filter/widget/filter_distance_section.dart';
import 'package:bazio/views/search/filter/widget/filter_price_section.dart';
import 'package:bazio/views/search/filter/widget/filter_sort_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FilterView extends ConsumerStatefulWidget {
  const FilterView({super.key});

  @override
  ConsumerState<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends ConsumerState<FilterView> {
  String? _category;
  String? _condition;
  RangeValues _priceRange = const RangeValues(0, FilterPriceSection.maxAr);
  double? _maxDistance;
  SearchSortBy _sortBy = SearchSortBy.recent;

  @override
  void initState() {
    super.initState();
    //on recopie l'etat actuel des filtres pour pre-remplir les champs
    final s = ref.read(searchNotifierProvider);
    _category = s.category;
    _condition = s.condition;
    _priceRange = RangeValues(
      s.minPrice ?? 0,
      s.maxPrice ?? FilterPriceSection.maxAr,
    );
    _maxDistance = s.maxDistance;
    _sortBy = s.sortBy;
  }

  //remet tout a zero sans fermer la page
  void _reset() {
    setState(() {
      _category = null;
      _condition = null;
      _priceRange = const RangeValues(0, FilterPriceSection.maxAr);
      _maxDistance = null;
      _sortBy = SearchSortBy.recent;
    });
  }

  //applique les filtres et ferme la page
  void _apply() {
    ref
        .read(searchNotifierProvider.notifier)
        .applyFilters(
          category: _category,
          condition: _condition,
          minPrice: _priceRange.start > 0 ? _priceRange.start : null,
          maxPrice: _priceRange.end < FilterPriceSection.maxAr
              ? _priceRange.end
              : null,
          maxDistance: _maxDistance,
          sortBy: _sortBy,
          clearCategory: _category == null,
          clearCondition: _condition == null,
          clearMinPrice: _priceRange.start == 0,
          clearMaxPrice: _priceRange.end == FilterPriceSection.maxAr,
          clearMaxDistance: _maxDistance == null,
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final hasLocation = locationAsync.when(
      data: (loc) => loc.hasAnyLocation,
      loading: () => false,
      error: (_, __) => false,
    );

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomAppBar(
                      title: 'Filtres',
                      subtitle: 'Affinez votre recherche',
                      onBack: () => context.pop(),
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: Text(
                      'Réinitialiser',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilterSortSection(
                      selected: _sortBy,
                      hasLocation: hasLocation,
                      onChanged: (v) => setState(() => _sortBy = v),
                    ),
                    AppSpacing.vLarge,
                    FilterCategorySection(
                      selected: _category,
                      onChanged: (v) => setState(() => _category = v),
                    ),
                    AppSpacing.vLarge,
                    FilterConditionSection(
                      selected: _condition,
                      onChanged: (v) => setState(() => _condition = v),
                    ),
                    AppSpacing.vLarge,
                    FilterPriceSection(
                      values: _priceRange,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                    AppSpacing.vLarge,
                    FilterDistanceSection(
                      value: _maxDistance,
                      hasLocation: hasLocation,
                      onChanged: (v) => setState(() => _maxDistance = v),
                      onConfigureLocation: () =>
                          context.push('/profile-settings'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      //bouton fixe en bas pour valider les filtres
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: AppButton(text: 'Appliquer les filtres', onPressed: _apply),
      ),
    );
  }
}
