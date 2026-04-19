import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:flutter/material.dart';

class ListingDescription extends StatelessWidget {
  final String description;

  const ListingDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Description',
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.blackB,
              fontSize: 17,
            ),
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cardBg.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.blackB.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
