import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/components/app_button.dart';
import 'package:bazio/core/components/confirm_dialog.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/components/auth_helpers.dart';
import 'package:bazio/model/listing/draft_model.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/viewmodels/publish/draft_notifier.dart';
import 'package:bazio/viewmodels/publish/publish_notifier.dart';
import 'package:bazio/views/publish/widget/image_picker_section.dart';
import 'package:bazio/views/publish/widget/publish_description_section.dart';
import 'package:bazio/views/publish/widget/publish_essential_section.dart';
import 'package:bazio/views/publish/widget/publish_location_section.dart';
import 'package:bazio/views/publish/widget/publish_upload_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PublishView extends ConsumerStatefulWidget {
  final ListingModel? existingListing;
  final DraftModel? draftToLoad; //passe depuis DraftView via extra
  const PublishView({super.key, this.existingListing, this.draftToLoad});

  @override
  ConsumerState<PublishView> createState() => _PublishViewState();
}

class _PublishViewState extends ConsumerState<PublishView> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _cityController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;
  bool _showMoreDetails = false;

  //brouillon en cours d'edition null si nouvelle annonce fraiche
  DraftModel? _editingDraft;

  @override
  void initState() {
    super.initState();
    final listing = widget.existingListing;

    if (listing != null) {
      //mode edition on prefill les champs avec l'annonce existante
      _titleController.text = listing.title;
      _priceController.text = listing.price.toStringAsFixed(0);
      _descriptionController.text = listing.description;
      _brandController.text = listing.brand ?? '';
      _modelController.text = listing.modelName ?? '';
      _sizeController.text = listing.size ?? '';
      _colorController.text = listing.color ?? '';
      _cityController.text = listing.city;
      _selectedCategory = listing.category;
      _selectedCondition = listing.condition;
      _showMoreDetails = [
        listing.brand,
        listing.modelName,
        listing.size,
        listing.color,
      ].any((v) => v != null && v.isNotEmpty);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(publishProvider.notifier).loadFromListing(listing);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.draftToLoad != null) {
          //vient de DraftView on charge directement sans dialog
          _editingDraft = widget.draftToLoad;
          _loadDraftIntoForm(widget.draftToLoad!);
        } else {
          _checkAndOfferDraft();
        }
      });
    }
  }

  //propose de reprendre le brouillon le plus recent si un existe
  Future<void> _checkAndOfferDraft() async {
    final drafts = ref.read(draftProvider);
    if (drafts.isEmpty || !mounted) return;
    final draft = drafts.first;

    final draftPreview = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title.isNotEmpty ? draft.title : 'Sans titre',
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.blackB),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (draft.price != null)
                  Text(
                    '${draft.price!.toInt()} Ar',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final resumeResult = await AppChoiceDialog.show(
      context,
      icon: Icons.edit_note_rounded,
      title: 'Brouillon sauvegardé',
      message: 'Tu as un brouillon non publié :',
      content: draftPreview,
      barrierDismissible: false,
      actions: [
        const AppDialogAction(
          label: 'Ignorer',
          value: 'ignore',
          isOutlined: true,
        ),
        const AppDialogAction(
          label: 'Reprendre',
          value: 'resume',
          icon: Icons.edit_rounded,
        ),
      ],
    );
    final resume = resumeResult == 'resume';

    if (resume == true && mounted) {
      _editingDraft = draft;
      _loadDraftIntoForm(draft);
    }
  }

  void _loadDraftIntoForm(DraftModel draft) {
    setState(() {
      _titleController.text = draft.title;
      _priceController.text = draft.price?.toStringAsFixed(0) ?? '';
      _descriptionController.text = draft.description;
      _brandController.text = draft.brand ?? '';
      _modelController.text = draft.modelName ?? '';
      _sizeController.text = draft.size ?? '';
      _colorController.text = draft.color ?? '';
      _cityController.text = draft.city ?? '';
      _selectedCategory = draft.category;
      _selectedCondition = draft.condition;
      _showMoreDetails = [draft.brand, draft.modelName, draft.size, draft.color]
          .any((v) => v != null && v.isNotEmpty);
    });

    //on restaure aussi les images locales et le GPS dans le provider
    ref.read(publishProvider.notifier).restoreFromDraft(
      imagePaths: draft.imagePaths,
      latitude: draft.latitude,
      longitude: draft.longitude,
      city: draft.city,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (!mounted) return;
    final publishState = ref.read(publishProvider);

    //on bloque le retour pendant un upload en cours
    if (publishState.isLoading) return;

    //on capture la city avant que autoDispose ne detruise le state
    final currentCity = publishState.city;

    final hasContent = _titleController.text.isNotEmpty ||
        _priceController.text.isNotEmpty ||
        publishState.imageItems.isNotEmpty ||
        publishState.existingImageUrls.isNotEmpty ||
        publishState.city != null ||
        publishState.position != null;

    //formulaire vide on quitte directement
    if (!hasContent) {
      context.go('/home');
      return;
    }

    //formulaire rempli on propose de sauvegarder en brouillon ou quitter
    final result = await AppChoiceDialog.show(
      context,
      icon: Icons.help_outline_rounded,
      title: 'Que veux-tu faire ?',
      message: "Ton annonce n'est pas encore publiée.",
      actions: [
        AppDialogAction(
          label: 'Quitter sans sauvegarder',
          value: 'discard',
          color: AppColors.rouge,
          icon: Icons.logout_rounded,
        ),
        const AppDialogAction(
          label: 'Sauvegarder en brouillon',
          value: 'draft',
          icon: Icons.save_outlined,
        ),
      ],
    );

    //null signifie que l'utilisateur a ferme le dialog on reste sur la page
    if (!mounted || result == null) return;

    if (result == 'draft') {
      final publishState2 = ref.read(publishProvider);
      final notifier = ref.read(draftProvider.notifier);
      if (_editingDraft != null) {
        await notifier.updateDraft(
          _editingDraft!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.tryParse(
                _priceController.text.replaceAll(',', '.')),
            category: _selectedCategory,
            condition: _selectedCondition,
            city: currentCity,
            brand: _brandController.text.isEmpty
                ? null
                : _brandController.text,
            modelName: _modelController.text.isEmpty
                ? null
                : _modelController.text,
            size: _sizeController.text.isEmpty
                ? null
                : _sizeController.text,
            color: _colorController.text.isEmpty
                ? null
                : _colorController.text,
            imagePaths: publishState2.imageItems
                .map((e) => e.file.path)
                .toList(),
            latitude: publishState2.position?.latitude,
            longitude: publishState2.position?.longitude,
          );
        } else {
          await notifier.saveDraft(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.tryParse(
                _priceController.text.replaceAll(',', '.')),
            category: _selectedCategory,
            condition: _selectedCondition,
            city: currentCity,
            brand: _brandController.text.isEmpty ? null : _brandController.text,
            modelName: _modelController.text.isEmpty ? null : _modelController.text,
            size: _sizeController.text.isEmpty ? null : _sizeController.text,
            color: _colorController.text.isEmpty ? null : _colorController.text,
            imagePaths: publishState2.imageItems.map((e) => e.file.path).toList(),
            latitude: publishState2.position?.latitude,
            longitude: publishState2.position?.longitude,
          );
        }

      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Brouillon sauvegardé',
          type: SnackType.success,
        );
        context.go('/home');
      }
    } else if (result == 'discard') {
      //on supprime uniquement le brouillon en cours les autres restent intacts
      if (_editingDraft != null) {
        await ref.read(draftProvider.notifier).deleteDraft(_editingDraft!);
      }
      if (mounted) context.go('/home');
    }
  }

  Future<void> _publish() async {
    final double? price =
        double.tryParse(_priceController.text.replaceAll(',', '.'));

    //validations avant publication
    if (_titleController.text.trim().isEmpty) {
      showAppSnackBar(context,
          message: 'Le titre est requis', type: SnackType.error);
      return;
    }
    if (price == null || price <= 0) {
      showAppSnackBar(context,
          message: 'Prix invalide', type: SnackType.error);
      return;
    }
    if (ref.read(publishProvider).city == null) {
      showAppSnackBar(context,
          message: 'Veuillez sélectionner une ville',
          type: SnackType.error);
      return;
    }
    if (_selectedCategory == null || _selectedCondition == null) {
      showAppSnackBar(context,
          message: 'Catégorie et état obligatoires',
          type: SnackType.error);
      return;
    }

    try {
      await ref.read(publishProvider.notifier).publishListing(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            category: _selectedCategory!,
            condition: _selectedCondition!,
            brand: _brandController.text.isEmpty
                ? null
                : _brandController.text,
            modelName: _modelController.text.isEmpty
                ? null
                : _modelController.text,
            size: _sizeController.text.isEmpty
                ? null
                : _sizeController.text,
            color: _colorController.text.isEmpty
                ? null
                : _colorController.text,
          );

      //publication reussie on supprime uniquement le brouillon en cours
      if (_editingDraft != null) {
        await ref.read(draftProvider.notifier).deleteDraft(_editingDraft!);
      }

      if (mounted) {
        final isEditing = widget.existingListing != null;
        showAppSnackBar(
          context,
          message: isEditing
              ? 'Annonce modifiée avec succès !'
              : 'Annonce publiée avec succès !',
          type: SnackType.success,
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publishProvider);
    final isEditing = widget.existingListing != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 20, bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomAppBar(
                      title: isEditing
                          ? 'Modifier l\'annonce'
                          : 'Publier une annonce',
                      subtitle: 'Les champs avec * sont obligatoires',
                      onBack: _handleBack,
                    ),
                    AppSpacing.vLarge,

                    const ImagePickerSection(),
                    AppSpacing.vLarge,

                    PublishEssentialSection(
                      titleController: _titleController,
                      priceController: _priceController,
                      selectedCondition: _selectedCondition,
                      selectedCategory: _selectedCategory,
                      onConditionChanged: (val) =>
                          setState(() => _selectedCondition = val),
                      onCategoryChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                    AppSpacing.vLarge,

                    PublishLocationSection(
                        cityController: _cityController),
                    AppSpacing.vLarge,

                    PublishDescriptionSection(
                      descriptionController: _descriptionController,
                      brandController: _brandController,
                      modelController: _modelController,
                      sizeController: _sizeController,
                      colorController: _colorController,
                      initialShowMoreDetails: _showMoreDetails,
                    ),
                    AppSpacing.vExtraLarge,

                    AppButton(
                      text: isEditing
                          ? 'Enregistrer les modifications'
                          : 'Publier maintenant',
                      //pas de spinner si l'upload est en cours il a son propre overlay
                      isLoading: state.isLoading && !state.isUploading,
                      onPressed: state.isLoading ? null : _publish,
                    ),
                  ],
                ),
              ),
            ),

            //overlay d'upload affiché par dessus tout pendant l'envoi des photos
            if (state.isUploading)
              PublishUploadOverlay(imageItems: state.imageItems),
          ],
        ),
      ),
    );
  }
}
