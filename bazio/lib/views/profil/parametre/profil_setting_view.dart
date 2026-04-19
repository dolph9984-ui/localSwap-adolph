import 'dart:io';

import 'package:bazio/core/components/app_button.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/components/input_decoration.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/components/auth_helpers.dart';
import 'package:bazio/core/utils/validators.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/location/location_state.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:bazio/viewmodels/profile/profile_settings_notifier.dart';
import 'package:bazio/views/profil/parametre/widget/location_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsView extends ConsumerStatefulWidget {
  const ProfileSettingsView({super.key});

  @override
  ConsumerState<ProfileSettingsView> createState() =>
      _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends ConsumerState<ProfileSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  File? _pickedImage;

  //coordonnees GPS en attente avant sauvegarde
  double? _pendingLat;
  double? _pendingLng;
  bool _gpsCleared = false;

  UserLocationState? _originalLocationState;

  @override
  void initState() {
    super.initState();

    //nom depuis authProvider sans aller chercher Firebase directement
    final user = ref.read(authProvider);
    _nameController.text = user?.displayName ?? '';

    final currentLoc = ref.read(userLocationProvider).value;
    _cityController.text = currentLoc?.city ?? '';
    _originalLocationState = currentLoc;

    if (currentLoc != null && currentLoc.hasPosition) {
      _pendingLat = currentLoc.latitude;
      _pendingLng = currentLoc.longitude;
    }

    //le telephone est charge depuis Firestore via le ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(profileSettingsProvider.notifier).loadPhone();
      final phone = ref.read(profileSettingsProvider).phone;
      if (phone != null && mounted) {
        _phoneController.text = phone;
      }
    });
  }

  @override
  void dispose() {
    //si on quitte sans sauvegarder on restaure la localisation d'origine
    final isSaved = ref.read(profileSettingsProvider).isSaved;
    if (!isSaved && _originalLocationState != null) {
      ref
          .read(userLocationProvider.notifier)
          .restoreState(_originalLocationState!);
    }
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    try {
      await ref.read(profileSettingsProvider.notifier).saveProfile(
            name: _nameController.text,
            phone: _phoneController.text,
            pickedImage: _pickedImage,
            city: _cityController.text.trim(),
            pendingLat: _pendingLat,
            pendingLng: _pendingLng,
            gpsCleared: _gpsCleared,
          );

      if (mounted) {
        setState(() => _pickedImage = null);
        showAppSnackBar(context,
            message: 'Profil mis à jour avec succès !',
            type: SnackType.success);
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(profileSettingsProvider).isSaving;
    final user = ref.watch(authProvider);
    final networkPhotoUrl = user?.photoURL;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
              left: 24, right: 24, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(
                title: 'Paramètres du profil',
                subtitle: 'Gérez vos informations personnelles',
                onBack: () => Navigator.pop(context),
              ),

              AppSpacing.vLarge,

              //avatar cliquable pour changer la photo
              Center(
                child: GestureDetector(
                  onTap: isSaving ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.12),
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!) as ImageProvider
                            : (networkPhotoUrl != null
                                ? NetworkImage(networkPhotoUrl)
                                : null),
                        child: _pickedImage == null && networkPhotoUrl == null
                            ? Text(
                                (user?.displayName ?? '?').isNotEmpty
                                    ? (user?.displayName ?? '?')[0]
                                        .toUpperCase()
                                    : '?',
                                style: AppTextStyles.h1.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 36,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isSaving
                                ? Colors.grey.shade400
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.vLarge,

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Informations'),
                    AppSpacing.vSmall,
                    TextFormField(
                      controller: _nameController,
                      enabled: !isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: AppInputDecoration.defaultStyle(
                        hint: 'Votre nom complet',
                        label: 'Nom *',
                      ),
                      validator: (v) => Validators.nameError(v ?? ''),
                    ),
                    AppSpacing.vMedium,
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !isSaving,
                      maxLength: 13, //format +261XXXXXXXXX = 13 caracteres
                      decoration: AppInputDecoration.defaultStyle(
                        hint: '0341234567',
                        label: 'Téléphone',
                      ).copyWith(counterText: ''),
                      validator: (v) => Validators.phoneError(v ?? ''),
                    ),
                  ],
                ),
              ),

              AppSpacing.vLarge,

              LocationSection(
                cityController: _cityController,
                onGpsAcquired: (lat, lng) {
                  _pendingLat = lat;
                  _pendingLng = lng;
                  _gpsCleared = false;
                },
                onGpsCleared: () {
                  _pendingLat = null;
                  _pendingLng = null;
                  _gpsCleared = true;
                },
              ),

              AppSpacing.vExtraLarge,
              AppButton(
                text: 'Enregistrer les modifications',
                isLoading: isSaving,
                onPressed: isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.captionBold
          .copyWith(color: Colors.grey[500], letterSpacing: 1.1),
    );
  }
}
