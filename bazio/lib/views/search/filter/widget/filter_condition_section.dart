import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/views/search/filter/widget/filter_section_header.dart';
import 'package:flutter/material.dart';

class FilterConditionSection extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _conditions = [
    'Neuf',
    'Très bon état',
    'Bon état',
    'État moyen',
  ];

  const FilterConditionSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'État'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _conditions.map((cond) {
            final isSelected = selected == cond;
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : cond),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cond,
                  style: AppTextStyles.captionBold.copyWith(
                    color:
                        isSelected ? Colors.white : AppColors.blackOp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
