import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSection extends ConsumerStatefulWidget {
  // callbacks pour transmettre les coordonnees GPS et la ville au parent
  final void Function(double lat, double lng, String city)? onGpsAcquired;
  final void Function()? onGpsCleared;

  const LocationSection({
    super.key,
    this.onGpsAcquired,
    this.onGpsCleared,
  });

  @override
  ConsumerState<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends ConsumerState<LocationSection> {
  GoogleMapController? _mapController;

  static const _defaultTarget = LatLng(-18.8792, 47.5079);

  // coordonnees et ville temporaires, ne modifient pas l'etat global avant sauvegarde
  double? _tempLat;
  double? _tempLng;
  String? _tempCity;
  bool _isLocating = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    // on precharge les coords et la ville depuis l'etat en memoire si dispo
    final loc = ref.read(userLocationProvider).value;
    if (loc != null && loc.hasPosition) {
      _tempLat = loc.latitude;
      _tempLng = loc.longitude;
      _tempCity = loc.city;
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

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Localisation desactivee';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Impossible de recuperer la position. Verifiez les permissions.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      // reverse geocoding natif - pas de cle API requise
      final city = await _cityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _tempLat = position.latitude;
        _tempLng = position.longitude;
        _tempCity = city;
        _isLocating = false;
      });

      _moveCamera(position.latitude, position.longitude, 15);

      // on notifie le parent avec les coords ET la ville deduite
      if (city != null) {
        widget.onGpsAcquired?.call(position.latitude, position.longitude, city);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _gpsError = e.toString();
      });
    }
  }

  // deduit la ville depuis les coordonnees GPS via le geocoding natif du telephone
  Future<String?> _cityFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      // locality = ville, subAdministrativeArea = region en fallback
      return place.locality ?? place.subAdministrativeArea;
    } catch (_) {
      return null;
    }
  }

  void _clearGps() {
    setState(() {
      _tempLat = null;
      _tempLng = null;
      _tempCity = null;
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
        Text('Localisation', style: AppTextStyles.bodyBold),
        AppSpacing.vSmall,

        // badge ville detectee (remplace le CitySearchField)
        _CityDetectedBadge(
          city: _tempCity,
          isLocating: _isLocating,
        ),

        AppSpacing.vSmall,

        // carte Google Maps
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

            // bouton reinitialiser visible seulement si une position est definie
            if (hasPosition)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                onPressed: _clearGps,
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                label: const Text('Reinitialiser'),
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

class _CityDetectedBadge extends StatelessWidget {
  final String? city;
  final bool isLocating;

  const _CityDetectedBadge({this.city, required this.isLocating});

  @override
  Widget build(BuildContext context) {
    if (isLocating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Detection de la ville en cours...',
              style: AppTextStyles.body.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (city == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined,
                color: Colors.grey.shade400, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aucune localisation definie',
                style:
                    AppTextStyles.body.copyWith(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city!,
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.primary),
                ),
                Text(
                  'Detectee automatiquement via GPS',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.green.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline_rounded,
              color: Colors.green.shade400, size: 18),
        ],
      ),
    );
  }
}