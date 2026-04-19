import 'package:bazio/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//bouton pour laisser un avis sur un vendeur apres un achat
class SellerLeaveReviewButton extends StatelessWidget {
  final String sellerId;
  final String sellerName;
  final String listingId;
  final String listingTitle;

  const SellerLeaveReviewButton({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push(
          '/leave-review/$sellerId'
          '?sellerName=${Uri.encodeComponent(sellerName)}'
          '&listingId=$listingId'
          '&listingTitle=${Uri.encodeComponent(listingTitle)}',
        ),
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: const Text('Laisser un avis'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
