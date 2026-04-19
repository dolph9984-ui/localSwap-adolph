import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/views/search/filter/widget/filter_section_header.dart';
import 'package:flutter/material.dart';

class FilterPriceSection extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  //plafond en ariary pour le slider de prix
  static const double maxAr = 5000000;

  const FilterPriceSection({
    super.key,
    required this.values,
    required this.onChanged,
  });

  String _fmt(double v) {
    final i = v.toInt();
    return i.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'Prix (Ar)'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ar ${_fmt(values.start)}',
                style: AppTextStyles.captionBold
                    .copyWith(color: AppColors.primary)),
            Text('Ar ${_fmt(values.end)}',
                style: AppTextStyles.captionBold
                    .copyWith(color: AppColors.primary)),
          ],
        ),
        RangeSlider(
          values: values,
          min: 0,
          max: maxAr,
          divisions: 100,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primary.withOpacity(0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
