import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerListingsTab extends ConsumerWidget {
  final String sellerId;

  //quand true les cards n'affichent pas le lien vers le profil vendeur
  //utilise depuis SellerProfileView pour eviter la boucle infinie
  final bool disableSellerLink;

  const SellerListingsTab({
    super.key,
    required this.sellerId,
    this.disableSellerLink = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider(sellerId));

    return listingsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) {
        debugPrint('🔴 Erreur listings vendeur : $error');
        return _buildEmpty();
      },
      data: (listings) {
        //on affiche seulement les annonces non vendues
        final active = listings.where((l) => !l.isSold).toList();
        if (active.isEmpty) return _buildEmpty();

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            mainAxisSpacing: 8,
            crossAxisSpacing: 0,
          ),
          itemCount: active.length,
          itemBuilder: (ctx, i) => ListingCard(
            listing: active[i],
            disableSellerLink: disableSellerLink,
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 56,
            color: AppColors.grisNeutre.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune annonce active',
            style: AppTextStyles.body.copyWith(color: AppColors.grisNeutre),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce vendeur n\'a pas encore\npublié d\'annonce.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.grisNeutre),
          ),
        ],
      ),
    );
  }
}
