import 'package:bazio/core/constants/input_decoration.dart';
import 'package:bazio/presentation/viewmodels/publish_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CitySearchField extends ConsumerWidget {
  final List<String> cities;

  const CitySearchField({super.key, required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publishProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          initialValue: TextEditingValue(text: state.city ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return cities;
            return cities.where((String city) =>
                city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            ref.read(publishProvider.notifier).setCity(selection);
            FocusManager.instance.primaryFocus?.unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: AppInputDecoration.defaultStyle(
                hint: 'Sélectionnez une ville',
                label: 'Ville *',
              ).copyWith(
                suffixIcon: const Icon(Icons.arrow_drop_down, size: 28),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Material(
                  elevation: 4, // Ombre identique aux dropdowns
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}