// listing_header_info.dart
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:flutter/material.dart';

class ListingHeaderCard extends StatelessWidget {
  final ListingModel listing;
  const ListingHeaderCard({super.key, required this.listing});

  String _formatPrice(double price) {
    final int p = price.toInt();
    return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}mn';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.blackO,
            height: 1.25,
          ),
        ),

        const SizedBox(height: 12),

        //prix et date sur la meme ligne
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Ar',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatPrice(listing.price),
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: AppColors.grisNeutre),
                const SizedBox(width: 5),
                Text(
                  _timeAgo(listing.createdAt),
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.grisNeutre,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
