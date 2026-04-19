import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/listing/favorites_notifier.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bazio/core/components/app_snack_bar.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //provider deplace dans favorites_notifier pour une meilleure organisation
    final listingsAsync = ref.watch(favoritesListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CustomAppBar(
                title: 'Mes favoris',
                onBack: () => Navigator.of(context).pop(),
              ),
            ),

            Expanded(
              child: listingsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => AppErrorWidget(message: humanizeError(e)),
                data: (listings) {
                  if (listings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border_rounded,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun favori pour l\'instant',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Appuyez sur ♡ sur une annonce\npour l\'ajouter à vos favoris.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey.shade400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (ctx, i) => ListingCard(listing: listings[i]),
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
