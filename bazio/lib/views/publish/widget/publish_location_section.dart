import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/publish/publish_notifier.dart';
import 'package:bazio/views/publish/widget/map_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PublishLocationSection extends ConsumerWidget {
  const PublishLocationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publishProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOCALISATION',
          style: AppTextStyles.captionBold.copyWith(
            color: Colors.grey[500],
            letterSpacing: 1.1,
          ),
        ),
        AppSpacing.vSmall,

        // badge qui affiche la ville detectee automatiquement via GPS
        _CityDetectedBadge(city: state.city, isLocating: state.isLocating),

        AppSpacing.vSmall,

        // carte + bouton GPS (inchange)
        const MapLocationPicker(),
      ],
    );
  }
}

class _CityDetectedBadge extends StatelessWidget {
  final String? city;
  final bool isLocating;

  const _CityDetectedBadge({this.city, required this.isLocating});

  @override
  Widget build(BuildContext context) {
    if (isLocating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Detection de la ville en cours...',
              style: AppTextStyles.body.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (city == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined,
                color: Colors.orange.shade400, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Appuie sur "Me localiser" pour detecter ta ville *',
                style: AppTextStyles.body
                    .copyWith(color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city!,
                  style:
                      AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                ),
                Text(
                  'Ville detectee automatiquement via GPS',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.green.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline_rounded,
              color: Colors.green.shade400, size: 18),
        ],
      ),
    );
  }
}