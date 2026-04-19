import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/services/listing/listing_service.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:bazio/core/utils/geo_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listingServiceProvider = Provider<ListingService>((ref) {
  ref.keepAlive();
  return ListingService();
});

final recentListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  ref.keepAlive();
  return ref.watch(listingServiceProvider).getRecentListings();
});

final myListingsProvider = StreamProvider.family<List<ListingModel>, String>((ref, sellerId) {
  return ref.watch(listingServiceProvider).getMyListings(sellerId);
});

final mySalesCountProvider = Provider.family<int, String>((ref, sellerId) {
  final listings = ref.watch(myListingsProvider(sellerId)).value ?? [];
  return listings.where((l) => !l.isSold).length;
});

final listingDetailProvider = StreamProvider.family<ListingModel, String>((ref, id) {
  return ref.watch(listingServiceProvider).getListingById(id);
});

//on recupere les annonces a proximite en se basant sur le stream principal
final nearbyListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  ref.keepAlive();
  final locationAsync = ref.watch(userLocationProvider);
  final recentAsync = ref.watch(recentListingsProvider);

  //on check si la loc ou les datas sont pretes sinon on renvoie rien
  if (locationAsync is AsyncLoading || locationAsync is AsyncError) {
    return const Stream.empty();
  }

  final location = locationAsync.value;
  if (location == null || !location.hasAnyLocation) return const Stream.empty();

  if (recentAsync is AsyncLoading) return const Stream.empty();
  if (recentAsync is AsyncError) return const Stream.empty();

  final listings = recentAsync.value ?? [];

  final List<ListingModel> result;
  if (location.hasPosition) {
    //filtrage par distance gps avec la formule haversine
    final byGps = listings.where((l) {
      if (l.location == null) return false;
      return haversineKm(
            location.latitude!,
            location.longitude!,
            l.location!.latitude,
            l.location!.longitude,
          ) <= nearbyRadiusKm;
    }).toList();

    if (location.city != null) {
      final lowerCity = location.city!.toLowerCase();
      final gpsIds = byGps.map((l) => l.id).toSet();
      //on ajoute aussi les annonces de la meme ville si pas deja trouvees par gps
      final byCity = listings.where((l) {
        if (gpsIds.contains(l.id)) return false;
        if (l.location == null) return l.city.toLowerCase() == lowerCity;
        final dist = haversineKm(
          location.latitude!,
          location.longitude!,
          l.location!.latitude,
          l.location!.longitude,
        );
        return dist > nearbyRadiusKm && l.city.toLowerCase() == lowerCity;
      }).toList();
      result = [...byGps, ...byCity];
    } else {
      result = byGps;
    }
  } else {
    //si pas de gps on filtre juste sur le nom de la ville
    final lowerCity = location.city!.toLowerCase();
    result = listings.where((l) => l.city.toLowerCase() == lowerCity).toList();
  }

  return Stream.value(result);
});