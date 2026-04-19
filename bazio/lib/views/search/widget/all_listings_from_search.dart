import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/views/home/widget/listing_card.dart';
import 'package:flutter/material.dart';

//affiche tous les resultats d'une recherche textuelle recus depuis SearchNotifier
class AllListingsFromSearch extends StatelessWidget {
  final List<ListingModel> results;
  final String query;

  const AllListingsFromSearch({
    super.key,
    required this.results,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CustomAppBar(
                title: 'Résultats (${results.length})',
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            if (query.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'pour "$query"',
                    style: AppTextStyles.caption.copyWith(color: Colors.grey),
                  ),
                ),
              ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 20),
                          Text('Aucun résultat',
                              style: AppTextStyles.bodyBold),
                          const SizedBox(height: 10),
                          Text(
                            'Essayez avec d\'autres mots-clés ou filtres.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: results.length,
                      itemBuilder: (ctx, i) =>
                          ListingCard(listing: results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
