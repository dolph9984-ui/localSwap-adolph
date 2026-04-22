import 'dart:io';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/publish/publish_state.dart';
import 'package:flutter/material.dart';

//overlay semi-transparent affiche pendant l'envoi des photos
class PublishUploadOverlay extends StatelessWidget {
  final List<ImageUploadItem> imageItems;

  const PublishUploadOverlay({
    super.key,
    required this.imageItems,
  });

  @override
  Widget build(BuildContext context) {
    final total = imageItems.length;
    final done =
        imageItems.where((e) => e.status == ImageUploadStatus.done).length;

    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Envoi des photos...',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.blackOp,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$done sur $total envoyée${done > 1 ? 's' : ''}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              //vignettes avec statut pour chaque photo
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: imageItems
                    .map((item) => _ImageThumb(item: item))
                    .toList(),
              ),
              const SizedBox(height: 16),
              //barre de progression globale
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ne fermez pas l\'application',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final ImageUploadItem item;
  const _ImageThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUploading = item.status == ImageUploadStatus.uploading;
    final isDone = item.status == ImageUploadStatus.done;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(item.file.path),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              //assombrit la photo en cours d'envoi ou en attente
              color: isUploading
                  ? Colors.black.withOpacity(0.35)
                  : isDone
                      ? null
                      : Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          if (isUploading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          //coche verte quand l'envoi est termine
          if (isDone)
            Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
