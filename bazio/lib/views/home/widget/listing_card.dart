import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/utils/format_helpers.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/viewmodels/listing/favorites_notifier.dart';
import 'package:bazio/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

// ── Helpers badge condition ───────────────────────────────────────────────────

Color _badgeBg(String condition) {
  switch (condition.toLowerCase()) {
    case 'neuf':
      return AppColors.conditionNeufBg;
    case 'très bon état':
      return AppColors.conditionTresBonBg;
    case 'bon état':
      return AppColors.conditionBonBg;
    case 'état moyen':
      return AppColors.conditionMoyenBg;
    default:
      return Colors.grey.shade300;
  }
}

Color _badgeText(String condition) {
  switch (condition.toLowerCase()) {
    case 'neuf':
      return AppColors.conditionNeufText;
    case 'très bon état':
      return AppColors.conditionTresBonText;
    case 'bon état':
      return AppColors.conditionBonText;
    case 'état moyen':
      return AppColors.conditionMoyenText;
    default:
      return AppColors.blackB;
  }
}

// ── Widget principal ──────────────────────────────────────────────────────────

class ListingCard extends ConsumerWidget {
  final ListingModel listing;
  final bool isLoading;
  final bool disableSellerLink;

  const ListingCard({
    super.key,
    required this.listing,
    this.isLoading = false,
    this.disableSellerLink = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) return _buildSkeleton(context);

    final favAsync = ref.watch(favoritesProvider);
    
    //riverpod 3+ utilise .value directement
    final isFav = favAsync.value?.contains(listing.id) ?? false;

    return Semantics(
      label:
          '${listing.title}, ${listing.city}, Ar ${formatPrice(listing.price)}',
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: () => context.push(
          '/listing/${listing.id}'
          '${disableSellerLink ? '?disableSeller=true' : ''}',
        ),
        child: Container(
          width: MediaQuery.of(context).size.width / 2.3,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackOp.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: listing.imageUrls.isNotEmpty
                          ? listing.imageUrls[0]
                          : 'https://via.placeholder.com/160x140',
                      height: 140,
                      width: double.infinity,
                      memCacheWidth: 160,
                      cacheManager: AppImageCacheManager(),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        period: const Duration(milliseconds: 1500),
                        child: Container(height: 140, color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 140,
                        color: AppColors.bgOp,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.bleu,
                        ),
                      ),
                    ),
                    if (listing.condition.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _badgeBg(listing.condition),
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(12)),
                          ),
                          child: Text(
                            listing.condition,
                            style: AppTextStyles.captionBold.copyWith(
                              color: _badgeText(listing.condition),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleFavorite(listing.id);
                        },
                        child: AnimatedScale(
                          scale: isFav ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isFav
                                  ? AppColors.rouge
                                  : AppColors.grisNeutre,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.blackO),
                            ),
                          ),
                          AppSpacing.hSmall,
                          Text(
                            timeAgo(listing.createdAt),
                            style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.bleu, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ar ${formatPrice(listing.price)}',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 14, color: AppColors.bleu),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.bleu, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2.3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        period: const Duration(milliseconds: 1500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 140, color: Colors.white),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        height: 14,
                        color: Colors.white,
                        width: double.infinity),
                    const SizedBox(height: 6),
                    Container(height: 18, color: Colors.white, width: 80),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 14, height: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, color: Colors.white, width: 100),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}