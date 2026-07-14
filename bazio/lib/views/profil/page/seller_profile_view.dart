import 'package:bazio/core/components/app_tab_bar.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/viewmodels/review/review_notifier.dart';
import 'package:bazio/viewmodels/listing/seller_provider.dart';
import 'package:bazio/views/profil/page/widget/listing_tab.dart';
import 'package:bazio/views/profil/page/widget/review_tab.dart';
import 'package:bazio/views/profil/page/widget/seller_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SellerProfileView extends ConsumerStatefulWidget {
  final String sellerId;
  final String sellerName;

  //listingId et listingTitle optionnels pour le bouton laisser un avis
  final String? listingId;
  final String? listingTitle;

  const SellerProfileView({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.listingId,
    this.listingTitle,
  });

  @override
  ConsumerState<SellerProfileView> createState() => _SellerProfileViewState();
}

class _SellerProfileViewState extends ConsumerState<SellerProfileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellerInfoAsync = ref.watch(sellerInfoProvider(widget.sellerId));
    final ratingAsync = ref.watch(sellerRatingProvider(widget.sellerId));

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: CustomAppBar(
                title: widget.listingTitle ?? widget.sellerName,
                subtitle: 'Profil',
                onBack: () => context.pop(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SellerHeader(
                sellerName: widget.sellerName,
                sellerInfoAsync: sellerInfoAsync,
                ratingAsync: ratingAsync,
              ),
            ),

            AppSpacing.vMedium,

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppTabBar(
                controller: _tabController,
                tabs: const ['Annonces', 'Avis'],
              ),
            ),

            AppSpacing.vMedium,

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  //disableSellerLink evite la boucle infinie depuis ce profil
                  SellerListingsTab(
                    sellerId: widget.sellerId,
                    disableSellerLink: true,
                  ),
                  SellerReviewsTab(sellerId: widget.sellerId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
