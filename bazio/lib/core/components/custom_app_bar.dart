import 'package:flutter/material.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/constants/spacing.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // Couleur de fond très légère (pêche/rosé comme sur ton image)
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.primary, // Flèche en orange
                ),
              ),
            ),
            AppSpacing.hMedium,
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary, // Titre en Orange Primaire
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 52), // Aligné après le bouton retour
            child: Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}