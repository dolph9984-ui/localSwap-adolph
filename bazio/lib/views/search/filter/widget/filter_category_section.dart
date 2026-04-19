import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/listing_constants.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/views/search/filter/widget/filter_section_header.dart';
import 'package:flutter/material.dart';

class FilterCategorySection extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const FilterCategorySection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'Catégorie'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ListingConstants.categories.map((cat) {
            final label = cat['label'] as String;
            final icon = cat['icon'] as IconData;
            final isSelected = selected == label;
            return GestureDetector(
              //un tap sur une categorie deja selectionnee la deselectionne
              onTap: () => onChanged(isSelected ? null : label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.grisNeutre),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppTextStyles.captionBold.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.blackOp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
