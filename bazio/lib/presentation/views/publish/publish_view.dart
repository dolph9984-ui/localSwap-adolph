import 'package:bazio/core/components/button_text.dart';
import 'package:bazio/core/components/custom_app_bar.dart'; // oublie pas de créer ce fichier
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/input_decoration.dart';
import 'package:bazio/core/constants/listing_constants.dart';
import 'package:bazio/core/constants/madagascar_cities.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/utils.dart/auth_helpers.dart';
import 'package:bazio/main_wrapper.dart';
import 'package:bazio/presentation/viewmodels/publish_notifier.dart';
import 'package:bazio/presentation/views/publish/widget/city_search_field.dart';
import 'package:bazio/presentation/views/publish/widget/image_picker_section.dart';
import 'package:bazio/presentation/views/publish/widget/map_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PublishView extends ConsumerStatefulWidget {
  const PublishView({super.key});

  @override
  ConsumerState<PublishView> createState() => _PublishViewState();
}

class _PublishViewState extends ConsumerState<PublishView> {
  // tous les controllers pour ramasser le texte
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;
  bool _showMoreDetails = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // la fonction pour envoyer l annonce
  Future<void> _publish() async {
    final state = ref.read(publishProvider);
    final double? price = double.tryParse(_priceController.text.replaceAll(',', '.'));

    // on check si tout est rempli avant d envoyer
    if (_titleController.text.trim().isEmpty) {
      showAppSnackBar(context, message: 'Le titre est requis', type: SnackType.error);
      return;
    }
    if (price == null || price <= 0) {
      showAppSnackBar(context, message: 'Prix invalide', type: SnackType.error);
      return;
    }
    if (state.city == null) {
      showAppSnackBar(context, message: 'Veuillez sélectionner une ville', type: SnackType.error);
      return;
    }
    if (_selectedCategory == null || _selectedCondition == null) {
      showAppSnackBar(context, message: 'Catégorie et état obligatoires', type: SnackType.error);
      return;
    }

    try {
      await ref.read(publishProvider.notifier).publishListing(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            category: _selectedCategory!,
            condition: _selectedCondition!,
            brand: _brandController.text.isEmpty ? null : _brandController.text,
            modelName: _modelController.text.isEmpty ? null : _modelController.text,
            size: _sizeController.text.isEmpty ? null : _sizeController.text,
            color: _colorController.text.isEmpty ? null : _colorController.text,
          );

      if (mounted) {
        showAppSnackBar(context, message: 'Annonce publiée avec succès !', type: SnackType.success);
        _resetForm();
        // on ramene l utilisateur a l accueil apres
        ref.read(navigationIndexProvider.notifier).setIndex(0);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, message: e.toString(), type: SnackType.error);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _brandController.clear();
    _modelController.clear();
    _sizeController.clear();
    _colorController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedCondition = null;
      _showMoreDetails = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publishProvider);

    return Scaffold(
      backgroundColor: AppColors.bgO,
      body: SafeArea(
        child: SingleChildScrollView(
          // padding large en bas pour pas que la nav bar gene
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // l en tête réutilisable avec le style orange
              CustomAppBar(
                title: 'Publier une annonce',
                subtitle: 'Les champs avec * sont obligatoires',
                onBack: () => ref.read(navigationIndexProvider.notifier).setIndex(0),
              ),

              AppSpacing.vLarge,
              const ImagePickerSection(),
              AppSpacing.vLarge,

              _sectionHeader('Essentiel'),
              AppSpacing.vSmall,
              TextFormField(
                controller: _titleController,
                decoration: AppInputDecoration.defaultStyle(hint: 'Ex: iPhone 13', label: 'Titre *'),
              ),
              AppSpacing.vMedium,

              // prix et etat cote a cote c est plus beau
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: AppInputDecoration.defaultStyle(hint: '0', label: 'Prix (Ar) *'),
                    ),
                  ),
                  AppSpacing.hMedium,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: AppInputDecoration.defaultStyle(hint: '', label: 'État *'),
                      items: ListingConstants.conditions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCondition = val),
                    ),
                  ),
                ],
              ),
              AppSpacing.vMedium,

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: AppInputDecoration.defaultStyle(hint: '', label: 'Catégorie *'),
                items: ListingConstants.categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),

              AppSpacing.vLarge,
              _sectionHeader('Localisation'),
              AppSpacing.vSmall,
              CitySearchField(cities: madagascarCities),
              AppSpacing.vSmall,
              const MapLocationPicker(), // petit rappel de la map ici

              AppSpacing.vLarge,
              _sectionHeader('Description'),
              AppSpacing.vSmall,
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: AppInputDecoration.defaultStyle(hint: 'Dites en plus...', label: 'Description'),
              ),

              // bouton pour les options facultatives
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showMoreDetails = !_showMoreDetails),
                  icon: Icon(_showMoreDetails ? Icons.expand_less : Icons.expand_more, color: AppColors.primary),
                  label: Text(_showMoreDetails ? 'Moins de détails' : 'Plus de détails (Marque, Taille...)', 
                    style: TextStyle(color: AppColors.primary)),
                ),
              ),

              if (_showMoreDetails) ...[
                TextFormField(
                  controller: _brandController,
                  decoration: AppInputDecoration.defaultStyle(hint: 'Ex: Nike', label: 'Marque'),
                ),
                AppSpacing.vMedium,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sizeController,
                        decoration: AppInputDecoration.defaultStyle(hint: 'Ex: 42', label: 'Taille'),
                      ),
                    ),
                    AppSpacing.hMedium,
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: AppInputDecoration.defaultStyle(hint: 'Noir', label: 'Couleur'),
                      ),
                    ),
                  ],
                ),
              ],

              AppSpacing.vExtraLarge,
              AppButton(
                text: 'Publier maintenant',
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : _publish,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // petit widget pour les titres de zone
  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.captionBold.copyWith(color: Colors.grey[500], letterSpacing: 1.1),
    );
  }
}