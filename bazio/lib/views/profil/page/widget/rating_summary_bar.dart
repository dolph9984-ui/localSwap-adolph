import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/review/review_model.dart';
import 'package:bazio/views/profil/page/widget/star_row.dart';
import 'package:flutter/material.dart';

//resume de note moyenne avec etoiles pour le profil vendeur
class RatingSummaryBar extends StatelessWidget {
  final UserRatingInfo info;
  const RatingSummaryBar({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Text(
            info.averageRating.toStringAsFixed(1),
            style: AppTextStyles.h1.copyWith(
              fontSize: 40,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.hMedium,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StarRow(rating: info.averageRating, size: 20),
              AppSpacing.vExtraSmall,
              Text(
                'Basé sur ${info.reviewCount} avis',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.grisNeutre),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
