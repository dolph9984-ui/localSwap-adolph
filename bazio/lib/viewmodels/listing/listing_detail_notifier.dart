import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/messaging/chat_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//gestion des actions sur les annonces pour eviter que la vue touche aux services
class ListingDetailNotifier extends Notifier<void> {
  @override
  void build() {}

  //on change le statut de vente et on previent direct les chats concernes
  Future<void> toggleSoldStatus(
    String listingId,
    bool isSold, {
    required String sellerId,
  }) async {
    await ref
        .read(listingServiceProvider)
        .toggleSoldStatus(listingId, isSold);
    
    //maj automatique pour toutes les convos liees a l'annonce
    await ref.read(chatServiceProvider).broadcastSoldStatus(
          listingId: listingId,
          isSold: isSold,
          senderId: sellerId,
        );
  }

  Future<void> deleteListing(ListingModel listing) async {
    await ref.read(listingServiceProvider).deleteListing(listing);
  }
}

final listingDetailNotifierProvider =
    NotifierProvider<ListingDetailNotifier, void>(ListingDetailNotifier.new);