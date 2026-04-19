import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/components/input_decoration.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:flutter/material.dart';

class PublishDescriptionSection extends StatefulWidget {
  final TextEditingController descriptionController;
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController sizeController;
  final TextEditingController colorController;
  final bool initialShowMoreDetails;

  const PublishDescriptionSection({
    super.key,
    required this.descriptionController,
    required this.brandController,
    required this.modelController,
    required this.sizeController,
    required this.colorController,
    this.initialShowMoreDetails = false,
  });

  @override
  State<PublishDescriptionSection> createState() =>
      _PublishDescriptionSectionState();
}

class _PublishDescriptionSectionState extends State<PublishDescriptionSection> {
  late bool _showMoreDetails;

  @override
  void initState() {
    super.initState();
    _showMoreDetails = widget.initialShowMoreDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIPTION',
          style: AppTextStyles.captionBold.copyWith(
            color: Colors.grey[500],
            letterSpacing: 1.1,
          ),
        ),
        AppSpacing.vSmall,
        TextFormField(
          controller: widget.descriptionController,
          maxLines: 3,
          decoration: AppInputDecoration.defaultStyle(
            hint: 'Dites en plus...',
            label: 'Description',
          ),
        ),
        //bouton pour afficher ou masquer les champs optionnels
        Center(
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _showMoreDetails = !_showMoreDetails),
            icon: Icon(
              _showMoreDetails ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
            ),
            label: Text(
              _showMoreDetails
                  ? 'Moins de détails'
                  : 'Plus de détails (Marque, Taille...)',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
        if (_showMoreDetails) ...[
          TextFormField(
            controller: widget.brandController,
            decoration:
                AppInputDecoration.defaultStyle(hint: 'Ex: Nike', label: 'Marque'),
          ),
          AppSpacing.vMedium,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.sizeController,
                  decoration: AppInputDecoration.defaultStyle(
                      hint: 'Ex: 42', label: 'Taille'),
                ),
              ),
              AppSpacing.hMedium,
              Expanded(
                child: TextFormField(
                  controller: widget.colorController,
                  decoration: AppInputDecoration.defaultStyle(
                      hint: 'Noir', label: 'Couleur'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
