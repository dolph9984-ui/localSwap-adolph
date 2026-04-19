import 'package:bazio/core/constants/madagascar_cities.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/publish/publish_notifier.dart';
import 'package:bazio/views/publish/widget/city_search_field.dart';
import 'package:bazio/views/publish/widget/map_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PublishLocationSection extends ConsumerWidget {
  final TextEditingController cityController;

  const PublishLocationSection({
    super.key,
    required this.cityController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        //selection de la ville avec autocompletion
        CitySearchField(
          cities: madagascarCities,
          controller: cityController,
          onCitySelected: (city) {
            ref.read(publishProvider.notifier).setCity(city);
          },
        ),
        AppSpacing.vSmall,
        //carte optionnelle pour affiner la position GPS
        const MapLocationPicker(),
      ],
    );
  }
}
