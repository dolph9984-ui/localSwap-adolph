import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:flutter/material.dart';

//titre de section en majuscules espacees pour les filtres
class FilterSectionHeader extends StatelessWidget {
  final String title;
  const FilterSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.captionBold.copyWith(
        color: Colors.grey[500],
        letterSpacing: 1.1,
      ),
    );
  }
}
