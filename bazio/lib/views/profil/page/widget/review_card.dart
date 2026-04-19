import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/review/review_model.dart';
import 'package:bazio/views/profil/page/widget/star_row.dart';
import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const ReviewCard({super.key, required this.review});

  //initiales du nom de l'auteur sur deux mots max
  String get _initials => review.authorName.isNotEmpty
      ? review.authorName
          .trim()
          .split(' ')
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join()
      : '?';

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.bleu.withOpacity(0.12),
                backgroundImage: review.authorPhotoUrl != null
                    ? NetworkImage(review.authorPhotoUrl!)
                    : null,
                child: review.authorPhotoUrl == null
                    ? Text(_initials,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.bleu))
                    : null,
              ),
              AppSpacing.hSmall,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.authorName,
                        style: AppTextStyles.captionBold
                            .copyWith(color: AppColors.blackO)),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grisNeutre),
                    ),
                  ],
                ),
              ),
              StarRow(rating: review.rating.toDouble(), size: 13),
            ],
          ),
          AppSpacing.vSmall,
          //tag de l'annonce concernee par cet avis
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              review.listingTitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
          AppSpacing.vSmall,
          Text(
            review.comment,
            style: AppTextStyles.body.copyWith(color: AppColors.blackO),
          ),
        ],
      ),
    );
  }
}
