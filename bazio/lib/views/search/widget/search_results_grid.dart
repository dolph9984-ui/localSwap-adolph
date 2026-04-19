import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:flutter/material.dart';

class SearchResultsGrid extends StatelessWidget {
  final List<ListingModel> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchResultsGrid({
    super.key,
    required this.results,
    required this.isLoading,
    this.error,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (error != null) {
      return Center(
        child: Text(error!,
            style: AppTextStyles.body.copyWith(color: Colors.grey)),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Aucun résultat pour "$query"',
              style:
                  AppTextStyles.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 4,
        childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) => ListingCard(listing: results[i]),
    );
  }
}
