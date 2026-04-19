import 'package:bazio/core/utils/error_helpers.dart';
import 'package:bazio/model/review/review_model.dart';
import 'package:bazio/services/review/review_service.dart';
import 'package:bazio/viewmodels/review/review_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//accès au service des avis
final reviewServiceProvider =
    Provider<ReviewService>((_) => ReviewService());

//récupère la liste des avis d'un vendeur en temps réel
final sellerReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, sellerId) {
  return ref.watch(reviewServiceProvider).getReviewsForSeller(sellerId);
});

//moyenne et nombre total d'avis pour le profil
final sellerRatingProvider =
    StreamProvider.family<UserRatingInfo, String>((ref, sellerId) {
  return ref.watch(reviewServiceProvider).getRatingInfo(sellerId);
});

class LeaveReviewNotifier extends Notifier<LeaveReviewState> {
  late final ReviewService _service;

  @override
  LeaveReviewState build() {
    _service = ref.read(reviewServiceProvider);
    return const LeaveReviewState();
  }

  void setRating(int rating) {
    state = state.copyWith(selectedRating: rating, clearError: true);
  }

  Future<void> submit({
    required String sellerId,
    required String listingId,
    required String listingTitle,
    required String comment,
  }) async {
    //on vérifie que les champs sont remplis avant d'envoyer
    if (state.selectedRating == 0) {
      state = state.copyWith(error: 'Veuillez choisir une note');
      return;
    }
    if (comment.trim().isEmpty) {
      state = state.copyWith(error: 'Le commentaire est requis');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.submitReview(
        sellerId: sellerId,
        listingId: listingId,
        listingTitle: listingTitle,
        rating: state.selectedRating,
        comment: comment,
      );
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      //gestion d'erreur simplifiée pour l'UI
      state = state.copyWith(
        isLoading: false,
        error: humanizeError(e),
      );
    }
  }
}

final leaveReviewProvider =
    NotifierProvider.autoDispose<LeaveReviewNotifier, LeaveReviewState>(
  LeaveReviewNotifier.new,
);
