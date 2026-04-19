import 'package:flutter/material.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/constants/spacing.dart';

//notre barre de titre custom qu'on utilise en haut des pages
class CustomAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.hMedium,
            ],
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary, //on met le titre en orange pour que ca ressorte
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(
              left: 52,
            ), //on decale un peu pour que ce soit bien aligne avec le texte du dessus
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