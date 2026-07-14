import 'package:bazio/core/components/confirm_dialog.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/listing/favorites_notifier.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/publish/draft_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/profile/profile_settings_notifier.dart';
import 'package:bazio/viewmodels/review/review_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// userCreatedAtProvider est defini dans viewmodels/profile/profile_settings_notifier.dart

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final uid = user?.uid ?? '';
    final name = user?.displayName ?? 'Utilisateur';
    final photoUrl = user?.photoURL;

    final emailAsync = ref.watch(userEmailProvider);
    final email = emailAsync.value ?? user?.email ?? user?.providerData.firstOrNull?.email ?? '';

    final createdAtAsync = ref.watch(userCreatedAtProvider);
    final ratingAsync = ref.watch(sellerRatingProvider(uid));

    final salesCount = uid.isNotEmpty ? ref.watch(mySalesCountProvider(uid)) : 0;
    final favoritesAsync = ref.watch(favoritesProvider);
    final favoritesCount = favoritesAsync.isLoading ? null : (favoritesAsync.value?.length ?? 0);

    final drafts = ref.watch(draftProvider);
    final draftCount = drafts.length;

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Profil', style: AppTextStyles.h2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 3)),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 36))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(name, textAlign: TextAlign.center, style: AppTextStyles.h2.copyWith(color: AppColors.blackOp, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.grisNeutre, fontSize: 14)),
                    const SizedBox(height: 6),
                    createdAtAsync.when(
                      loading: () => const SizedBox(height: 18),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (date) => Text(date != null ? 'Membre depuis ${_formatDate(date)}' : '', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.blackB, fontSize: 13)),
                    ),
                    const SizedBox(height: 10),
                    ratingAsync.when(
                      loading: () => const SizedBox(height: 22),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (info) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < info.averageRating.floor();
                            final half = !filled && i < info.averageRating;
                            return Icon(
                              filled ? Icons.star_rounded : half ? Icons.star_half_rounded : Icons.star_outline_rounded,
                              color: info.reviewCount > 0 ? AppColors.conditionBonBg : AppColors.grisNeutre,
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(info.reviewCount > 0 ? '(${info.reviewCount} AVIS)' : '(Aucun avis)', style: AppTextStyles.captionBold.copyWith(color: AppColors.blackB)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              _ProfileTile(icon: Icons.manage_accounts_outlined, label: 'PARAMETRES', onTap: () => context.push('/profile-settings')),
              const SizedBox(height: 12),
              _ProfileTile(icon: Icons.history, label: 'MES VENTES', badgeCount: salesCount > 0 ? salesCount : null, onTap: () => context.push('/my-sales')),
              const SizedBox(height: 12),
              _ProfileTile(icon: Icons.favorite_border_rounded, label: 'MES FAVORIS', badgeCount: (favoritesCount != null && favoritesCount > 0) ? favoritesCount : null, onTap: () => context.push('/favorites')),
              const SizedBox(height: 12),
              _ProfileTile(icon: Icons.edit_note_rounded, label: 'MES BROUILLONS', badgeCount: draftCount > 0 ? draftCount : null, onTap: () => context.push('/my-drafts')),
              const SizedBox(height: 12),
              ratingAsync.when(
                loading: () => _ProfileTile(icon: Icons.star_outline_rounded, label: 'MES AVIS', onTap: () => context.push('/my-reviews')),
                error: (_, __) => _ProfileTile(icon: Icons.star_outline_rounded, label: 'MES AVIS', onTap: () => context.push('/my-reviews')),
                data: (info) => _ProfileTile(icon: Icons.star_outline_rounded, label: 'MES AVIS', badgeCount: info.reviewCount > 0 ? info.reviewCount : null, onTap: () => context.push('/my-reviews')),
              ),

              const SizedBox(height: 40),

              _LogoutButton(
                onShowDialog: () => ConfirmDialog.show(
                  context,
                  title: 'Se déconnecter ?',
                  message: 'Vous devrez vous reconnecter pour accéder à votre compte.',
                  confirmLabel: 'Se déconnecter',
                  cancelLabel: 'Annuler',
                  icon: Icons.logout_rounded,
                  confirmColor: AppColors.rouge,
                ),
                onLogout: () async {
                  await ref.read(authProvider.notifier).logOut();
                  if (context.mounted) context.go('/login');
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  const _ProfileTile({required this.icon, required this.label, required this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),

      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: InkWell(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.bleu.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.bleu, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.blackOp,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount! > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: AppTextStyles.captionBold.copyWith(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              const Icon(Icons.chevron_right_rounded, color: AppColors.bleu, size: 22),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// Bouton de déconnexion avec spinner intégré pendant l'opération
class _LogoutButton extends StatefulWidget {
  final Future<bool> Function() onShowDialog;
  final Future<void> Function() onLogout;
  const _LogoutButton({required this.onShowDialog, required this.onLogout});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgOp,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _loading
            ? null
            : () async {
                final confirmed = await widget.onShowDialog();
                if (!confirmed) return;
                // spinner s'active uniquement après confirmation
                setState(() => _loading = true);
                try {
                  await widget.onLogout();
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.rouge),
                )
              else
                const Icon(Icons.logout_rounded, color: AppColors.rouge, size: 22),
              const SizedBox(width: 10),
              Text(
                _loading ? 'Déconnexion...' : 'SE DECONNECTER',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.rouge, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}