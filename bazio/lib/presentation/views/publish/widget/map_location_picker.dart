import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/presentation/viewmodels/publish_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapLocationPicker extends ConsumerStatefulWidget {
  const MapLocationPicker({super.key});

  @override
  ConsumerState<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends ConsumerState<MapLocationPicker> {
  GoogleMapController? _mapController;

  static const _defaultTarget = LatLng(-18.8792, 47.5079);

  void _moveCamera(double lat, double lng, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publishProvider);
    final hasPosition = state.position != null;

    ref.listen(publishProvider.select((s) => s.position), (prev, next) {
      if (next != null) {
        _moveCamera(next.latitude, next.longitude, 15);
      } else {
        _moveCamera(_defaultTarget.latitude, _defaultTarget.longitude, 12);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.vSmall,
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
            initialCameraPosition: const CameraPosition(
              target: _defaultTarget,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              final pos = ref.read(publishProvider).position;
              if (pos != null) {
                _moveCamera(pos.latitude, pos.longitude, 15);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: hasPosition
                ? {
                    Marker(
                      markerId: const MarkerId('pos'),
                      position: LatLng(
                        state.position!.latitude,
                        state.position!.longitude,
                      ),
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
                    hasPosition ? Theme.of(context).primaryColor : Colors.grey.shade600,
              ),
              onPressed: () =>
                  ref.read(publishProvider.notifier).getCurrentLocation(),
              icon: Icon(
                Icons.my_location,
                color: hasPosition ? Theme.of(context).primaryColor : Colors.grey.shade600,
              ),
              label: Text(hasPosition ? 'Actualiser' : 'Me localiser'),
            ),

            if (hasPosition)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                onPressed: () =>
                    ref.read(publishProvider.notifier).clearLocation(),
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                label: const Text('Réinitialiser'),
              ),
          ],
        ),
      ],
    );
  }
}