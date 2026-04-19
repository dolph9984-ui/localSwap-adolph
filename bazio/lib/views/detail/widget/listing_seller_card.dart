import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/review/review_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListingSellerCard extends ConsumerWidget {
  final String sellerId;
  final String sellerName;
  final VoidCallback onTap;

  const ListingSellerCard({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(sellerRatingProvider(sellerId));

    //initiales extraites des deux premiers mots du nom
    final initials = sellerName.isNotEmpty
        ? sellerName
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.bleu,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            AppSpacing.hMedium,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.blackO),
                  ),
                  AppSpacing.vExtraSmall,
                  //note moyenne chargee de facon asynchrone
                  ratingAsync.when(
                    loading: () => const SizedBox(height: 14),
                    error: (_, __) => const SizedBox(height: 14),
                    data: (info) => Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < info.averageRating.floor();
                          final half =
                              !filled && i < info.averageRating;
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : half
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded,
                            size: 14,
                            color: info.reviewCount > 0
                                ? const Color(0xFFFACC15)
                                : AppColors.grisNeutre,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          info.reviewCount > 0
                              ? '${info.reviewCount} avis'
                              : 'Aucun avis',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.bleu),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.bleu, size: 22),
          ],
        ),
      ),
    );
  }
}
