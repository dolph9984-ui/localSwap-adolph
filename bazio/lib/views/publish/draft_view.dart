import 'package:bazio/core/components/confirm_dialog.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/draft_model.dart';
import 'package:bazio/viewmodels/publish/draft_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DraftView extends ConsumerWidget {
  const DraftView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(draftProvider);

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CustomAppBar(
                title: 'Mes brouillons',
                onBack: () => context.pop(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: drafts.isEmpty
                  ? const _EmptyDrafts()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
                      itemCount: drafts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => _DraftTile(
                        draft: drafts[i],
                        //on passe le brouillon en extra pour le charger directement
                        onResume: () =>
                            context.push('/publish', extra: drafts[i]),
                        onDelete: () =>
                            _confirmDelete(context, ref, drafts[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, DraftModel draft) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Supprimer ce brouillon ?',
      message:
          '"${draft.displayTitle}" sera supprimé définitivement.',
      confirmLabel: 'Supprimer',
      cancelLabel: 'Annuler',
      confirmColor: AppColors.rouge,
      icon: Icons.delete_outline,
    );
    if (confirm) {
      await ref.read(draftProvider.notifier).deleteDraft(draft);
    }
  }
}

class _DraftTile extends StatelessWidget {
  final DraftModel draft;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const _DraftTile({
    required this.draft,
    required this.onResume,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResume,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBg),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_note_rounded,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.displayTitle,
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.blackB),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      //prix si renseigne
                      if (draft.price != null) ...[
                        Text(
                          '${draft.price!.toInt()} Ar',
                          style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.primary, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                      ],
                      //nombre de photos
                      if (draft.imagePaths.isNotEmpty) ...[
                        const Icon(Icons.image_outlined,
                            size: 12, color: AppColors.grisNeutre),
                        const SizedBox(width: 3),
                        Text(
                          '${draft.imagePaths.length}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.grisNeutre, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                      ],
                      //indicateur GPS si des coordonnees sont sauvegardees
                      if (draft.latitude != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.grisNeutre),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.grisNeutre),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(draft.savedAt),
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.grisNeutre, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.delete_outline,
                    size: 20,
                    color: AppColors.rouge.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDrafts extends StatelessWidget {
  const _EmptyDrafts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun brouillon',
            style: AppTextStyles.bodyBold
                .copyWith(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 6),
          Text(
            'Tes annonces non publiées apparaîtront ici.',
            style: AppTextStyles.caption
                .copyWith(color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
