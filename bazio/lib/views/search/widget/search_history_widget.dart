import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:flutter/material.dart';

class SearchHistoryWidget extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  const SearchHistoryWidget({
    super.key,
    required this.history,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              'Aucun historique de recherche',
              style:
                  AppTextStyles.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Historique', style: AppTextStyles.h3),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Tout effacer',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.separated(
            itemCount: history.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) {
              final query = history[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.history,
                    color: Colors.grey.shade400, size: 22),
                title:
                    Text(query, style: AppTextStyles.body),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //fleche pour relancer la recherche avec ce terme
                    Icon(Icons.north_west,
                        size: 18, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onRemove(query),
                      child: Icon(Icons.close,
                          size: 18, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                onTap: () => onTap(query),
              );
            },
          ),
        ),
      ],
    );
  }
}
