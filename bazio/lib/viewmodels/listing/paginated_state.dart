import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bazio/model/listing/listing_model.dart';

class PaginatedState {
  final List<ListingModel> listings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  const PaginatedState({
    this.listings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
  });

  PaginatedState copyWith({
    List<ListingModel>? listings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    bool clearLastDoc = false,
  }) {
    return PaginatedState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: clearLastDoc ? null : lastDoc ?? this.lastDoc,
    );
  }
}
