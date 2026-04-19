import 'package:bazio/core/components/input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CitySearchField extends ConsumerStatefulWidget {
  final List<String> cities;
  final TextEditingController? controller;
  final Function(String)? onCitySelected;

  const CitySearchField({
    super.key,
    required this.cities,
    this.controller,
    this.onCitySelected,
  });

  @override
  ConsumerState<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends ConsumerState<CitySearchField> {
  late final TextEditingController _internalController;
  late final FocusNode _focusNode;

  TextEditingController get _controller =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _focusNode = FocusNode();

    //on scrolle vers le champ quand il prend le focus pour eviter qu'il soit masque par le clavier
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToField();
      }
    });
  }

  @override
  void dispose() {
    _internalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _scrollToField() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final context = this.context;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return widget.cities;
            //filtre les villes contenant le texte saisi sans distinction casse
            return widget.cities.where((String city) =>
                city.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ));
          },
          onSelected: (String selection) {
            if (widget.onCitySelected != null) {
              widget.onCitySelected!(selection);
            }
            _focusNode.unfocus();
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
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
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
