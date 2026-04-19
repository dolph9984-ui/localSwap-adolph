import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/views/search/filter/widget/filter_section_header.dart';
import 'package:flutter/material.dart';

class FilterDistanceSection extends StatelessWidget {
  final double? value; //null = pas de filtre distance
  final ValueChanged<double?> onChanged;
  final bool hasLocation;
  final VoidCallback onConfigureLocation;

  const FilterDistanceSection({
    super.key,
    required this.value,
    required this.onChanged,
    required this.hasLocation,
    required this.onConfigureLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'Distance'),
        const SizedBox(height: 12),
        //si pas de position on invite a configurer dans les parametres
        if (!hasLocation)
          GestureDetector(
            onTap: onConfigureLocation,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Renseignez votre position dans les paramètres pour filtrer par distance',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.primary, size: 18),
                ],
              ),
            ),
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value == null
                    ? 'Toutes distances'
                    : '${value!.toInt()} km',
                style: AppTextStyles.captionBold
                    .copyWith(color: AppColors.primary),
              ),
              if (value != null)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Text(
                    'Effacer',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grisNeutre),
                  ),
                ),
            ],
          ),
          Slider(
            value: value ?? 50,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.15),
            onChanged: (v) => onChanged(v),
          ),
        ],
      ],
    );
  }
}
