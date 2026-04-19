import 'package:bazio/core/components/input_decoration.dart';
import 'package:bazio/core/constants/listing_constants.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:flutter/material.dart';

class PublishEssentialSection extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController priceController;
  final String? selectedCondition;
  final String? selectedCategory;
  final ValueChanged<String?> onConditionChanged;
  final ValueChanged<String?> onCategoryChanged;

  const PublishEssentialSection({
    super.key,
    required this.titleController,
    required this.priceController,
    required this.selectedCondition,
    required this.selectedCategory,
    required this.onConditionChanged,
    required this.onCategoryChanged,
  });

  @override
  State<PublishEssentialSection> createState() =>
      _PublishEssentialSectionState();
}

class _PublishEssentialSectionState extends State<PublishEssentialSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Essentiel'),
        AppSpacing.vSmall,
        TextFormField(
          controller: widget.titleController,
          decoration:
              AppInputDecoration.defaultStyle(hint: 'Ex: iPhone 13', label: 'Titre *'),
        ),
        AppSpacing.vMedium,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.priceController,
                keyboardType: TextInputType.number,
                decoration:
                    AppInputDecoration.defaultStyle(hint: '0', label: 'Prix (Ar) *'),
              ),
            ),
            AppSpacing.hMedium,
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: widget.selectedCondition,
                decoration: AppInputDecoration.defaultStyle(
                  hint: '',
                  label: 'État *',
                ).copyWith(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: 'État *',
                ),
                items: ListingConstants.conditions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
                onChanged: widget.onConditionChanged,
              ),
            ),
          ],
        ),
        AppSpacing.vMedium,
        DropdownButtonFormField<String>(
          initialValue: widget.selectedCategory,
          decoration: AppInputDecoration.defaultStyle(
            hint: '',
            label: 'Catégorie *',
          ).copyWith(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: 'Catégorie *',
          ),
          items: ListingConstants.categories
              .map((cat) => DropdownMenuItem<String>(
                    value: cat['value'] as String,
                    child: Text(cat['label'] as String),
                  ))
              .toList(),
          onChanged: widget.onCategoryChanged,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.captionBold.copyWith(
        color: Colors.grey[500],
        letterSpacing: 1.1,
      ),
    );
  }
}
