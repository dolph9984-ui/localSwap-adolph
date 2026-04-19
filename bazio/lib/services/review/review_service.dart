import 'package:bazio/model/review/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //recuperation des avis recus par le vendeur
  Stream<List<ReviewModel>> getReviewsForSeller(String sellerId) {
    return _firestore
        .collection('users')
        .doc(sellerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  //stats du profil vendeur avec moyenne et nombre d avis
  Stream<UserRatingInfo> getRatingInfo(String sellerId) {
    return _firestore
        .collection('users')
        .doc(sellerId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return const UserRatingInfo();
      final data = doc.data()!;
      return UserRatingInfo(
        averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
        reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      );
    });
  }

  //empeche de noter plusieurs fois la meme annonce
  Future<bool> hasAlreadyReviewed({
    required String sellerId,
    required String listingId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final snap = await _firestore
        .collection('users')
        .doc(sellerId)
        .collection('reviews')
        .where('authorId', isEqualTo: uid)
        .where('listingId', isEqualTo: listingId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  //verification que la vente a bien ete finalisee dans le tchat
  Future<bool> isTransactionConfirmed({
    required String sellerId,
    required String listingId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final snap = await _firestore
        .collection('chats')
        .where('listingId', isEqualTo: listingId)
        .where('sellerId', isEqualTo: sellerId)
        .where('buyerId', isEqualTo: uid)
        .where('isCompleted', isEqualTo: true)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  //soumission de l avis avec recalcul de la moyenne en transaction
  Future<void> submitReview({
    required String sellerId,
    required String listingId,
    required String listingTitle,
    required int rating,
    required String comment,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Non authentifié');
    if (currentUser.uid == sellerId) {
      throw Exception('Vous ne pouvez pas vous noter vous-même');
    }
    if (rating < 1 || rating > 5) throw Exception('Note invalide');
    if (comment.trim().isEmpty) throw Exception('Le commentaire est requis');

    final transactionOk = await isTransactionConfirmed(
      sellerId: sellerId,
      listingId: listingId,
    );
    if (!transactionOk) {
      throw Exception(
          "Vous ne pouvez noter un vendeur qu'après une transaction confirmée");
    }

    final alreadyDone = await hasAlreadyReviewed(
      sellerId: sellerId,
      listingId: listingId,
    );
    if (alreadyDone) throw Exception('Vous avez déjà noté cette annonce');

    final sellerRef = _firestore.collection('users').doc(sellerId);
    final reviewRef = sellerRef.collection('reviews').doc();

    await _firestore.runTransaction((tx) async {
      final sellerSnap = await tx.get(sellerRef);
      final data = sellerSnap.data() ?? {};

      final currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
      final currentAvg =
          (data['averageRating'] as num?)?.toDouble() ?? 0.0;

      //calcul de la nouvelle moyenne ponderee
      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + rating) / newCount;

      tx.set(reviewRef, {
        'authorId': currentUser.uid,
        'authorName': currentUser.displayName ?? 'Anonyme',
        'authorPhotoUrl': currentUser.photoURL,
        'rating': rating,
        'comment': comment.trim(),
        'listingId': listingId,
        'listingTitle': listingTitle,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(sellerRef, {
        'reviewCount': newCount,
        'averageRating': double.parse(newAvg.toStringAsFixed(1)),
      });
    });
  }
}