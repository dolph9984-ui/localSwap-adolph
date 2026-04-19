import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/review/review_model.dart';
import 'package:bazio/views/profil/page/widget/star_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerHeader extends StatelessWidget {
  final String sellerName;
  final AsyncValue<Map<String, dynamic>> sellerInfoAsync;
  final AsyncValue<UserRatingInfo> ratingAsync;

  const SellerHeader({
    super.key,
    required this.sellerName,
    required this.sellerInfoAsync,
    required this.ratingAsync,
  });

  String get _initials => sellerName.isNotEmpty
      ? sellerName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
      : '?';

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = sellerInfoAsync.asData?.value['photoUrl'] as String?;
    final createdAt = sellerInfoAsync.asData?.value['createdAt'] as DateTime?;
    final phone = sellerInfoAsync.asData?.value['phone'] as String?;
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.bleu.withOpacity(0.15),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(_initials,
                        style: AppTextStyles.h2.copyWith(color: AppColors.bleu))
                    : null,
              ),
              AppSpacing.hMedium,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.blackOp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.vExtraSmall,
                    if (createdAt != null)
                      Text(
                        'Membre depuis ${_formatDate(createdAt)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grisNeutre),
                      ),
                    AppSpacing.vExtraSmall,
                    ratingAsync.when(
                      loading: () => const SizedBox(height: 16),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (info) => Row(
                        children: [
                          StarRow(rating: info.averageRating, size: 16),
                          AppSpacing.hSmall,
                          Text(
                            info.reviewCount > 0
                                ? '${info.averageRating.toStringAsFixed(1)} (${info.reviewCount} avis)'
                                : 'Aucun avis',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grisNeutre),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          //section telephone avec boutons appel et sms
          if (hasPhone) ...[
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    phone.trim(),
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.blackOp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _ContactButton(
                  icon: Icons.phone_outlined,
                  onTap: () => _call(phone.trim()),
                ),
                AppSpacing.hSmall,
                _ContactButton(
                  icon: Icons.chat_bubble_outline,
                  onTap: () => _sms(phone.trim()),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ContactButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
