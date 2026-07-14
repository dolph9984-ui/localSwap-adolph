import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/components/confirm_dialog.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/viewmodels/listing/favorites_notifier.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_detail_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/publish/publish_notifier.dart';
import 'package:bazio/views/detail/widget/listing_bottom_bar.dart';
import 'package:bazio/views/detail/widget/listing_description.dart';
import 'package:bazio/views/detail/widget/listing_header_info.dart';
import 'package:bazio/views/detail/widget/listing_image_gallery.dart';
import 'package:bazio/views/detail/widget/listing_security_warning.dart';
import 'package:bazio/views/detail/widget/listing_seller_card.dart';
import 'package:bazio/views/detail/widget/listing_specs_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ListingDetailView extends ConsumerStatefulWidget {
  final String listingId;
  final bool disableSellerLink;
  const ListingDetailView({
    super.key,
    required this.listingId,
    this.disableSellerLink = false,
  });

  @override
  ConsumerState<ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends ConsumerState<ListingDetailView> {
  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

    return listingAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgB,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bgB,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.grisNeutre.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  humanizeError(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grisNeutre, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (listing) => _buildDetail(context, listing),
    );
  }

  Widget _buildDetail(BuildContext context, ListingModel listing) {
    final favAsync = ref.watch(favoritesProvider);
    final isFav = favAsync.asData?.value.contains(listing.id) ?? false;
    final currentUid = ref.watch(authProvider)?.uid;
    //on compare l'uid pour savoir si c'est le proprietaire de l'annonce
    final isOwner = currentUid != null && currentUid == listing.sellerId;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, listing, isFav, isOwner),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ListingGallery(imageUrls: listing.imageUrls),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    transform: Matrix4.translationValues(0, -20, 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListingHeaderCard(listing: listing),

                          //badge vendu visible seulement si l'annonce est archivee
                          if (listing.isSold)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Vendu / Trouvé',
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          AppSpacing.vMedium,
                          const Divider(color: AppColors.cardBg, thickness: 1),
                          AppSpacing.vMedium,

                          ListingSpecsTable(listing: listing),

                          if (listing.description.trim().isNotEmpty) ...[
                            AppSpacing.vMedium,
                            const Divider(
                              color: AppColors.cardBg,
                              thickness: 1,
                            ),
                            AppSpacing.vMedium,
                            ListingDescription(
                              description: listing.description,
                            ),
                          ],

                          AppSpacing.vMedium,

                          //carte vendeur masquee pour le proprietaire et depuis son propre profil
                          if (!isOwner && !widget.disableSellerLink)
                            ListingSellerCard(
                              sellerId: listing.sellerId,
                              sellerName: listing.sellerName,
                              onTap: () => context.push(
                                '/seller/${listing.sellerId}'
                                '?sellerName=${Uri.encodeComponent(listing.sellerName)}'
                                '&listingId=${listing.id}'
                                '&listingTitle=${Uri.encodeComponent(listing.title)}',
                              ),
                            ),

                          AppSpacing.vMedium,
                          const ListingSafetyBanner(),
                          AppSpacing.vLarge,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          //barre du bas masquee si c'est le proprietaire
          if (!isOwner) ListingBottomBar(listing: listing),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    ListingModel listing,
    bool isFav,
    bool isOwner,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgO.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      actions: [
        //bouton partage visible pour tous
        GestureDetector(
          onTap: () {
            /* share */
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.bgO.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share_outlined,
              size: 18,
              color: AppColors.blackB,
            ),
          ),
        ),

        if (isOwner)
          _OwnerMenu(listing: listing)
        else
          //bouton favori pour les autres utilisateurs
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(favoritesProvider.notifier).toggleFavorite(listing.id);
            },
            child: AnimatedScale(
              scale: isFav ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgO.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFav ? AppColors.rouge : AppColors.grisNeutre,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OwnerMenu extends ConsumerWidget {
  final ListingModel listing;
  const _OwnerMenu({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.bgO.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<_OwnerAction>(
        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.blackB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (action) async {
          switch (action) {
            case _OwnerAction.edit:
              context.pop();
              //petit delai pour laisser le pop se terminer avant la navigation
              await Future.delayed(const Duration(milliseconds: 100));
              if (context.mounted) {
                ref.read(publishProvider.notifier).loadFromListing(listing);
                context.push('/publish/edit', extra: listing);
              }
              break;
            case _OwnerAction.markSold:
              final confirm = await ConfirmDialog.show(
                context,
                title: listing.isSold
                    ? 'Remettre en vente ?'
                    : 'Marquer comme vendu ?',
                message: listing.isSold
                    ? 'L\'annonce sera de nouveau visible.'
                    : 'L\'annonce sera archivée et ne sera plus visible dans les recherches.',
                confirmLabel: listing.isSold
                    ? 'Remettre en vente'
                    : 'Marquer vendu',
                cancelLabel: 'Annuler',
                icon: listing.isSold
                    ? Icons.refresh
                    : Icons.check_circle_outline,
                confirmColor: Colors.green,
              );
              if (confirm && context.mounted) {
                final newSoldState = !listing.isSold;
                await ref
                    .read(listingDetailNotifierProvider.notifier)
                    .toggleSoldStatus(
                      listing.id,
                      newSoldState,
                      sellerId: ref.read(authProvider)?.uid ?? '',
                    );
                //pas de pop car le stream met a jour la vue automatiquement
              }
              break;
            case _OwnerAction.delete:
              final confirm = await ConfirmDialog.show(
                context,
                title: 'Supprimer cette annonce ?',
                message:
                    'Cette action est irréversible. Les photos seront également supprimées.',
                confirmLabel: 'Supprimer',
                cancelLabel: 'Annuler',
                icon: Icons.delete_outline,
                confirmColor: AppColors.rouge,
              );
              if (confirm && context.mounted) {
                //on pop avant de supprimer pour eviter "annonce introuvable"
                context.pop();
                try {
                  await ref
                      .read(listingDetailNotifierProvider.notifier)
                      .deleteListing(listing);
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.showError(context, e);
                  }
                }
              }
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _OwnerAction.markSold,
            child: Row(
              children: [
                Icon(
                  listing.isSold ? Icons.refresh_rounded : Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  listing.isSold ? 'Remettre en vente' : 'Marquer comme vendu',
                  style: AppTextStyles.body.copyWith(color: AppColors.blackB),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: _OwnerAction.edit,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, color: AppColors.bleu, size: 20),
                const SizedBox(width: 12),
                Text('Modifier', style: AppTextStyles.body.copyWith(color: AppColors.blackB)),
              ],
            ),
          ),
          PopupMenuItem(
            value: _OwnerAction.delete,
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: AppColors.rouge, size: 20),
                const SizedBox(width: 12),
                Text('Supprimer', style: AppTextStyles.body.copyWith(color: AppColors.rouge)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _OwnerAction { edit, markSold, delete }