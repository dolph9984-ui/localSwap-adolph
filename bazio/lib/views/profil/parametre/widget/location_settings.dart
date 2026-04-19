import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/madagascar_cities.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:bazio/views/publish/widget/city_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSection extends ConsumerStatefulWidget {
  final TextEditingController cityController;

  //callbacks pour transmettre les coordonnees GPS temporaires au parent
  final void Function(double lat, double lng)? onGpsAcquired;
  final void Function()? onGpsCleared;

  const LocationSection({
    super.key,
    required this.cityController,
    this.onGpsAcquired,
    this.onGpsCleared,
  });

  @override
  ConsumerState<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends ConsumerState<LocationSection> {
  GoogleMapController? _mapController;

  static const _defaultTarget = LatLng(-18.8792, 47.5079);

  //coordonnees temporaires locales qui ne modifient pas l'etat global avant sauvegarde
  double? _tempLat;
  double? _tempLng;
  bool _isLocating = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    //on precharge les coords depuis l'etat en memoire si dispo
    final loc = ref.read(userLocationProvider).value;
    if (loc != null && loc.hasPosition) {
      _tempLat = loc.latitude;
      _tempLng = loc.longitude;
    }
  }

  void _moveCamera(double lat, double lng, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom),
      );
    });
  }

  Future<void> _locateMe() async {
    setState(() {
      _isLocating = true;
      _gpsError = null;
    });

    final notifier = ref.read(userLocationProvider.notifier);
    final result = await notifier.fetchLocationPreview();

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isLocating = false;
        _gpsError = 'Impossible de récupérer la position. Vérifiez les permissions.';
      });
      return;
    }

    setState(() {
      _tempLat = result.latitude;
      _tempLng = result.longitude;
      _isLocating = false;
    });

    _moveCamera(result.latitude, result.longitude, 15);

    //on notifie le parent pour qu'il stocke les coords jusqu'a la sauvegarde
    widget.onGpsAcquired?.call(result.latitude, result.longitude);
  }

  void _clearGps() {
    setState(() {
      _tempLat = null;
      _tempLng = null;
      _gpsError = null;
    });
    _moveCamera(_defaultTarget.latitude, _defaultTarget.longitude, 12);
    widget.onGpsCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasPosition = _tempLat != null && _tempLng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Localisation', style: AppTextStyles.bodyBold),
          ],
        ),
        AppSpacing.vSmall,

        CitySearchField(
          cities: madagascarCities,
          controller: widget.cityController,
        ),

        AppSpacing.vSmall,

        //bordure verte si une position GPS est definie
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasPosition ? Colors.green : Colors.grey.shade300,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: hasPosition
                  ? LatLng(_tempLat!, _tempLng!)
                  : _defaultTarget,
              zoom: hasPosition ? 15 : 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (hasPosition) {
                _moveCamera(_tempLat!, _tempLng!, 15);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: hasPosition
                ? {
                    Marker(
                      markerId: const MarkerId('pos'),
                      position: LatLng(_tempLat!, _tempLng!),
                    ),
                  }
                : {},
          ),
        ),

        AppSpacing.vSmall,

        Row(
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor:
                    hasPosition ? AppColors.primary : Colors.grey.shade600,
              ),
              onPressed: _isLocating ? null : _locateMe,
              icon: _isLocating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: hasPosition
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                    )
                  : Icon(
                      Icons.my_location,
                      color: hasPosition
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
              label: Text(hasPosition ? 'Actualiser' : 'Me localiser'),
            ),

            //bouton reinitialiser visible seulement si une position est definie
            if (hasPosition)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                onPressed: _clearGps,
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                label: const Text('Réinitialiser'),
              ),
          ],
        ),

        if (_gpsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _gpsError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
