import 'package:bazio/core/components/app_tab_bar.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MySalesView extends ConsumerStatefulWidget {
  const MySalesView({super.key});

  @override
  ConsumerState<MySalesView> createState() => _MySalesViewState();
}

class _MySalesViewState extends ConsumerState<MySalesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    //uid via Riverpod sans acceder directement a FirebaseAuth
    final uid = ref.watch(authProvider)?.uid;

    if (uid == null || uid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Utilisateur non identifié',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final salesAsync = ref.watch(myListingsProvider(uid));

    return salesAsync.when(
      skipLoadingOnReload: true,
      loading: () => _buildScaffold(
        context,
        activeCount: 0,
        soldCount: 0,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => _buildScaffold(
        context,
        activeCount: 0,
        soldCount: 0,
        child: _emptyState(context, isActive: true),
      ),
      data: (listings) {
        //on separe les annonces en cours des annonces vendues
        final active = listings.where((l) => !l.isSold).toList();
        final sold = listings.where((l) => l.isSold).toList();

        return _buildScaffold(
          context,
          activeCount: active.length,
          soldCount: sold.length,
          child: TabBarView(
            controller: _tabController,
            children: [
              active.isEmpty
                  ? _emptyState(context, isActive: true)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: active.length,
                      itemBuilder: (ctx, i) => ListingCard(listing: active[i]),
                    ),

              sold.isEmpty
                  ? _emptyState(context, isActive: false)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: sold.length,
                      itemBuilder: (ctx, i) => ListingCard(listing: sold[i]),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required int activeCount,
    required int soldCount,
    required Widget child,
  }) {
    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CustomAppBar(
                title: 'Mes ventes',
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppTabBar(
                controller: _tabController,
                tabs: [
                  activeCount > 0 ? 'En vente ($activeCount)' : 'En vente',
                  soldCount > 0 ? 'Vendus ($soldCount)' : 'Vendus',
                ],
              ),
            ),

            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, {required bool isActive}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.shopping_bag_outlined : Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            isActive ? 'Aucune annonce en vente' : 'Aucune vente conclue',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 10),
          Text(
            isActive
                ? 'Publiez vos premiers articles !'
                : 'Marquez une annonce comme vendue\npour la retrouver ici.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
          if (isActive) ...[
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/publish');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bleu,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Créer une annonce',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
