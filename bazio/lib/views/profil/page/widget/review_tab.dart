import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/review/review_notifier.dart';
import 'package:bazio/views/profil/page/widget/rating_summary_bar.dart';
import 'package:bazio/views/profil/page/widget/review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bazio/core/components/app_snack_bar.dart';

class SellerReviewsTab extends ConsumerWidget {
  final String sellerId;
  const SellerReviewsTab({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(sellerReviewsProvider(sellerId));
    final ratingAsync = ref.watch(sellerRatingProvider(sellerId));

    return reviewsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => AppErrorWidget(message: humanizeError(e)),
      data: (reviews) {
        if (reviews.isEmpty) return _buildEmpty();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            //resume global en haut de la liste
            ratingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (info) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RatingSummaryBar(info: info),
              ),
            ),
            ...reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReviewCard(review: r),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded,
              size: 56, color: AppColors.grisNeutre.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Aucun avis',
              style: AppTextStyles.body.copyWith(color: AppColors.grisNeutre)),
          const SizedBox(height: 8),
          Text(
            'Ce vendeur n\'a pas encore\nreçu d\'avis.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.grisNeutre),
          ),
        ],
      ),
    );
  }
}
