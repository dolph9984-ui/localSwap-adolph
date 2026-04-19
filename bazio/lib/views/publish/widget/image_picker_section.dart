import 'package:bazio/core/components/app_snack_bar.dart';
import 'dart:io';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/components/auth_helpers.dart';
import 'package:bazio/viewmodels/publish/publish_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImagePickerSection extends ConsumerWidget {
  const ImagePickerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publishProvider);
    //total combine images existantes et nouvelles pour le compteur
    final totalCount =
        state.existingImageUrls.length + state.images.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos', style: AppTextStyles.bodyBold),
            Text('$totalCount / 8', style: AppTextStyles.caption),
          ],
        ),
        AppSpacing.vSmall,
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              //images existantes affichees en mode edition
              ...state.existingImageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(publishProvider.notifier)
                            .removeExistingImage(index),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              //nouvelles images locales selectionnees
              ...state.images.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(File(file.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(publishProvider.notifier)
                            .removeImage(index),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              //bouton ajouter visible tant qu'on n'a pas atteint 8 photos
              if (totalCount < 8)
                GestureDetector(
                  onTap: () async {
                    try {
                      await ref
                          .read(publishProvider.notifier)
                          .pickImages();
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackBar.showError(context, e);
                      }
                    }
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        Text('Photo',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
