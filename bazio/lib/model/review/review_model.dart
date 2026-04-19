import 'package:cloud_firestore/cloud_firestore.dart';

//modele pour un avis laisse sur un profil
class ReviewModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final int rating;
  final String comment;
  final String listingId;
  final String listingTitle;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.rating,
    required this.comment,
    required this.listingId,
    required this.listingTitle,
    required this.createdAt,
  });

  //construit l'avis depuis firestore
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? 'Anonyme',
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      comment: d['comment'] as String? ?? '',
      listingId: d['listingId'] as String? ?? '',
      listingTitle: d['listingTitle'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

//resume des notes d'un utilisateur
class UserRatingInfo {
  final double averageRating;
  final int reviewCount;

  const UserRatingInfo({
    this.averageRating = 0,
    this.reviewCount = 0,
  });
}