import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:flutter/material.dart';

class ListingSpecsTable extends StatelessWidget {
  final ListingModel listing;
  const ListingSpecsTable({super.key, required this.listing});

  String _formatPrice(double price) {
    final int p = price.toInt();
    return p.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  Color _getConditionColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('neuf')) return const Color(0xFF27AE60);
    if (c.contains('très bon')) return const Color(0xFF2980B9);
    if (c.contains('bon')) return const Color(0xFFF39C12);
    return AppColors.blackB;
  }

  @override
  Widget build(BuildContext context) {
    //on prend l'adresse precise si dispo sinon juste la ville
    final location = (listing.address != null && listing.address!.isNotEmpty)
        ? listing.address!
        : listing.city;

    final rows = <_SpecRow>[
      _SpecRow('État', listing.condition, isCondition: true),
      if (listing.brand?.isNotEmpty ?? false) _SpecRow('Marque', listing.brand!),
      if (listing.modelName?.isNotEmpty ?? false) _SpecRow('Modèle', listing.modelName!),
      if (listing.size?.isNotEmpty ?? false) _SpecRow('Taille', listing.size!),
      if (listing.material?.isNotEmpty ?? false) _SpecRow('Matériau', listing.material!),
      if (listing.color?.isNotEmpty ?? false) _SpecRow('Couleur', listing.color!),
      if (listing.weight != null) _SpecRow('Poids', '${listing.weight} kg'),
      _SpecRow('Prix', 'Ar ${_formatPrice(listing.price)}', isPrice: true),
      _SpecRow('Localisation', location, isLocation: true),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Caractéristiques',
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.blackB,
              fontSize: 17,
            ),
          ),
        ),

        //tableau avec alternance de couleurs et coins arrondis
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBg.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1.5),
            },
            children: List.generate(rows.length, (index) {
              final row = rows[index];

              return TableRow(
                decoration: BoxDecoration(
                  //lignes paires claires lignes impaires un peu colorees
                  color: index.isEven
                      ? const Color.fromARGB(133, 233, 242, 255)
                      : AppColors.bgOp.withValues(alpha: 0.4),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text(
                      row.label,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grisNeutre,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text(
                      row.value,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: _getValueColor(row),
                        decoration: row.isLocation ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Color _getValueColor(_SpecRow row) {
    if (row.isPrice) return AppColors.primary;
    if (row.isLocation) return AppColors.bleu;
    if (row.isCondition) return _getConditionColor(row.value);
    return AppColors.blackB.withValues(alpha: 0.9);
  }
}

class _SpecRow {
  final String label;
  final String value;
  final bool isPrice;
  final bool isLocation;
  final bool isCondition;
  const _SpecRow(
    this.label,
    this.value, {
    this.isPrice = false,
    this.isLocation = false,
    this.isCondition = false,
  });
}
