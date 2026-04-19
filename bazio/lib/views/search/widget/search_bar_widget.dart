import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilter;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 52;

    return SizedBox(
      height: barHeight,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: barHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icones/search_outline.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Colors.grey.shade400,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: onSubmitted,
                      textInputAction: TextInputAction.search,
                      style: AppTextStyles.body,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Chercher un article...',
                        border: InputBorder.none,
                        hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        //croix de suppression visible seulement si le champ n'est pas vide
                        suffixIcon: controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: onClear,
                                child: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade400,
                                  size: 18
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          //bouton filtre carre de meme hauteur que le champ
          GestureDetector(
            onTap: onFilter,
            child: Container(
              width: barHeight,
              height: barHeight,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icones/filter.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
