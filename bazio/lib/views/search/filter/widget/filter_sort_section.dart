import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/search/search_state.dart';
import 'package:bazio/views/search/filter/widget/filter_section_header.dart';
import 'package:flutter/material.dart';

class FilterSortSection extends StatelessWidget {
  final SearchSortBy selected;
  final bool hasLocation;
  final ValueChanged<SearchSortBy> onChanged;

  const FilterSortSection({
    super.key,
    required this.selected,
    required this.hasLocation,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (SearchSortBy.recent, 'Plus récent', Icons.access_time_rounded),
      (SearchSortBy.priceLow, 'Prix croissant', Icons.arrow_upward_rounded),
      (SearchSortBy.priceHigh, 'Prix décroissant', Icons.arrow_downward_rounded),
      //option distance seulement si la localisation est configuree
      if (hasLocation)
        (SearchSortBy.distance, 'Distance', Icons.near_me_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'Trier par'),
        const SizedBox(height: 12),
        ...options.map((opt) {
          final (sort, label, icon) = opt;
          final isSelected = selected == sort;
          return GestureDetector(
            onTap: () => onChanged(sort),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.08)
                    : AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.grisNeutre),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.blackOp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  //coche visible seulement sur l'option selectionnee
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
