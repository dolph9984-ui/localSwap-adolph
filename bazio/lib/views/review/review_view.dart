import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/review/review_model.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/review/review_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyReviewsView extends ConsumerWidget {
  const MyReviewsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //uid via Riverpod sans acceder directement a FirebaseAuth
    final uid = ref.watch(authProvider)?.uid ?? '';
    final reviewsAsync = ref.watch(sellerReviewsProvider(uid));
    final ratingAsync = ref.watch(sellerRatingProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: CustomAppBar(
                title: 'Mes avis',
                subtitle: 'Ce que les acheteurs pensent de vous',
                onBack: () => Navigator.pop(context),
              ),
            ),

            //resume des etoiles en haut seulement si des donnees sont disponibles
            ratingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (info) => _RatingSummary(info: info),
            ),

            Expanded(
              child: reviewsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) {
                  //on affiche le snackbar apres le build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      AppSnackBar.show(
                        context,
                        message: 'Impossible de charger les avis',
                        type: SnackType.error,
                      );
                    }
                  });
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline_rounded,
                            size: 64,
                            color: AppColors.grisNeutre.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.grisNeutre),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vérifiez votre connexion et réessayez.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.grisNeutre),
                        ),
                      ],
                    ),
                  );
                },
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_outline_rounded,
                              size: 64,
                              color: AppColors.grisNeutre.withOpacity(0.4)),
                          AppSpacing.vMedium,
                          Text(
                            'Aucun avis pour l\'instant',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.grisNeutre),
                          ),
                          AppSpacing.vSmall,
                          Text(
                            'Vos avis apparaîtront ici\naprès vos premières ventes.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grisNeutre),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => AppSpacing.vMedium,
                    itemBuilder: (context, i) =>
                        _ReviewCard(review: reviews[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final UserRatingInfo info;
  const _RatingSummary({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            info.averageRating.toStringAsFixed(1),
            style: AppTextStyles.h1.copyWith(
              fontSize: 48,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.hMedium,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StarRow(rating: info.averageRating, size: 22),
              AppSpacing.vExtraSmall,
              Text(
                '${info.reviewCount} avis',
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

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final initials = review.authorName.isNotEmpty
        ? review.authorName
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
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
                radius: 20,
                backgroundColor: AppColors.bleu.withOpacity(0.15),
                backgroundImage: review.authorPhotoUrl != null
                    ? NetworkImage(review.authorPhotoUrl!)
                    : null,
                child: review.authorPhotoUrl == null
                    ? Text(initials,
                        style: AppTextStyles.captionBold
                            .copyWith(color: AppColors.bleu))
                    : null,
              ),
              AppSpacing.hSmall,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.authorName,
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.blackO)),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grisNeutre),
                    ),
                  ],
                ),
              ),
              _StarRow(rating: review.rating.toDouble(), size: 14),
            ],
          ),

          AppSpacing.vSmall,

          //tag de l'annonce associee a cet avis
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review.listingTitle,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary),
            ),
          ),

          AppSpacing.vSmall,

          Text(
            review.comment,
            style:
                AppTextStyles.body.copyWith(color: AppColors.blackO),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

//rangee d'etoiles locale a cette vue
class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: const Color(0xFFFACC15),
          size: size,
        );
      }),
    );
  }
}
