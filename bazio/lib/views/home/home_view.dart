import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/listing_constants.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/router/main_wrapper.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/notification/notification_notifier.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:bazio/views/home/widget/section_helper.dart';
import 'package:bazio/views/search/widget/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';


class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const _HomeHeader(),
            const _SearchBarSliver(),
            SectionHeader(title: 'Catégories', onTapAll: null),
            _buildCategoriesGrid(context),
            const _RecentSectionHeader(),
            const _RecentListSliver(),
            const _NearbySectionHeader(),
            const _NearbySliver(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 110,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 150,
          ),
          itemCount: ListingConstants.categories.length,
          itemBuilder: (context, index) {
            final cat = ListingConstants.categories[index];
            final value = cat['value'] as String;
            final label = cat['label'] as String;
            final icon = cat['icon'] as IconData;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBg),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/category/$value'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: AppColors.bleu),
                    AppSpacing.hSmall,
                    Text(
                      label,
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.blackB,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Header avec badge notification ───────────────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifs = ref.watch(unreadNotifCountProvider);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BAZIO',
              style: AppTextStyles.logo.copyWith(color: AppColors.primary),
            ),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/icones/notification.svg',
                    colorFilter: const ColorFilter.mode(AppColors.blackB, BlendMode.srcIn),
                  ),
                  if (unreadNotifs > 0)
                    Positioned(
                      top: -3,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rouge,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          unreadNotifs > 99 ? '99+' : '$unreadNotifs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barre de recherche (read-only, redirige vers l'onglet search) ─────────────

class _SearchBarSliver extends ConsumerWidget {
  const _SearchBarSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      sliver: SliverToBoxAdapter(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(navigationIndexProvider.notifier).setIndex(1);
            ref.read(searchFocusTriggerProvider.notifier).trigger();
          },
          child: AbsorbPointer(
            child: SearchBarWidget(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              onSubmitted: (_) {},
              onFilter: () {},
              onClear: () {},
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header section "Récent" ───────────────────────────────────────────────────

class _RecentSectionHeader extends ConsumerWidget {
  const _RecentSectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionHeader(
      title: 'Récent',
      isHighlighted: true,
      onTapAll: () => context.push('/all-listings?sort=recent'),
    );
  }
}

// ── Liste horizontale "Récent" ────────────────────────────────────────────────

class _RecentListSliver extends ConsumerWidget {
  const _RecentListSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentListingsProvider);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 255,
        child: recentAsync.when(
          skipLoadingOnReload: true,
          data: (listings) {
            final preview = listings.take(5).toList();
            if (preview.isEmpty) {
              return Center(
                child: Text(
                  'Aucune annonce pour l\'instant',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              itemBuilder: (ctx, i) => ListingCard(listing: preview[i]),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.grey.shade300,
                  size: 32,
                ),
                const SizedBox(height: 10),
                Text(
                  'Hors ligne',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les annonces s\'afficheront\ndès que vous serez connecté',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header section "Près de vous" ────────────────────────────────────────────

class _NearbySectionHeader extends ConsumerWidget {
  const _NearbySectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref
        .watch(userLocationProvider)
        .when(
          data: (loc) => loc.hasAnyLocation,
          loading: () => false,
          error: (_, __) => false,
        );

    return SectionHeader(
      title: 'Près de vous',
      onTapAll: hasLocation
          ? () => context.push('/all-listings?sort=nearby')
          : null,
    );
  }
}

// ── Section "Près de vous" ────────────────────────────────────────────────────

class _NearbySliver extends ConsumerWidget {
  const _NearbySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(userLocationProvider);

    if (locationAsync.isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final location = locationAsync.asData?.value;

    if (location == null || !location.hasAnyLocation) {
      return SliverToBoxAdapter(
        child: _NearbyBanner(onTap: () => context.push('/profile-settings')),
      );
    }

    return const _NearbyListSliver();
  }
}

class _NearbyListSliver extends ConsumerWidget {
  const _NearbyListSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyListingsProvider);
    final location = ref.watch(userLocationProvider).asData?.value;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 255,
        child: nearbyAsync.when(
          skipLoadingOnReload: true,
          data: (listings) {
            if (listings.isEmpty) {
              return _NearbyEmptyState(
                city: location?.city,
                hasGps: location?.hasPosition ?? false,
              );
            }
            final preview = listings.take(5).toList();
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              itemBuilder: (ctx, i) => ListingCard(listing: preview[i]),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.grey.shade300,
                  size: 32,
                ),
                const SizedBox(height: 10),
                Text(
                  'Hors ligne',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les annonces s\'afficheront\ndès que vous serez connecté',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Banner "configurez votre position" ───────────────────────────────────────

class _NearbyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NearbyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Renseignez votre position pour découvrir les annonces près de chez vous dans les paramètres',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── État vide "Près de vous" ──────────────────────────────────────────────────

class _NearbyEmptyState extends StatelessWidget {
  final String? city;
  final bool hasGps;
  const _NearbyEmptyState({this.city, required this.hasGps});

  @override
  Widget build(BuildContext context) {
    final message = hasGps
        ? 'Aucune annonce à moins de 15 km${city != null ? ' à $city' : ''}'
        : 'Aucune annonce trouvée à ${city ?? 'votre ville'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}