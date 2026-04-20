import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/components/app_button.dart';
import 'package:bazio/core/components/app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/components/input_decoration.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/review/review_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveReviewView extends ConsumerStatefulWidget {
  final String sellerId;
  final String sellerName;
  final String listingId;
  final String listingTitle;

  const LeaveReviewView({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  ConsumerState<LeaveReviewView> createState() => _LeaveReviewViewState();
}

class _LeaveReviewViewState extends ConsumerState<LeaveReviewView> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveReviewProvider);
    final notifier = ref.read(leaveReviewProvider.notifier);

    //on ferme automatiquement apres un envoi reussi
    ref.listen(leaveReviewProvider, (_, next) {
      if (next.success) {
        AppSnackBar.show(
          context,
          message: 'Avis publié avec succès !',
          type: SnackType.success,
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgB,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(
                title: 'Laisser un avis',
                subtitle: 'Partagez votre expérience',
                onBack: () => Navigator.pop(context),
              ),

              AppSpacing.vLarge,

              //carte du vendeur concerne par l'avis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.bleu.withOpacity(0.15),
                      child: Text(
                        widget.sellerName.isNotEmpty
                            ? widget.sellerName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.bleu),
                      ),
                    ),
                    AppSpacing.hMedium,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.sellerName,
                              style: AppTextStyles.bodyBold
                                  .copyWith(color: AppColors.blackO)),
                          Text(
                            widget.listingTitle,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grisNeutre),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.vLarge,

              Text(
                'VOTRE NOTE',
                style: AppTextStyles.captionBold.copyWith(
                    color: Colors.grey[500], letterSpacing: 1.1),
              ),
              AppSpacing.vSmall,
              //etoiles interactives pour choisir la note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final active = i < state.selectedRating;
                  return GestureDetector(
                    onTap: () => notifier.setRating(i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        active
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: active
                            ? const Color(0xFFFACC15)
                            : AppColors.grisNeutre,
                        size: 42,
                      ),
                    ),
                  );
                }),
              ),

              //label textuel de la note selectionnee
              if (state.selectedRating > 0) ...[
                AppSpacing.vSmall,
                Center(
                  child: Text(
                    _ratingLabel(state.selectedRating),
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],

              AppSpacing.vLarge,

              Text(
                'COMMENTAIRE',
                style: AppTextStyles.captionBold.copyWith(
                    color: Colors.grey[500], letterSpacing: 1.1),
              ),
              AppSpacing.vSmall,
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 300,
                decoration: AppInputDecoration.defaultStyle(
                  hint: 'Décrivez votre expérience avec ce vendeur...',
                  label: 'Commentaire',
                ),
              ),

              //message d'erreur si la soumission echoue
              if (state.error != null) ...[
                AppSpacing.vSmall,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.rouge.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.rouge, size: 18),
                      AppSpacing.hSmall,
                      Expanded(
                        child: Text(
                          state.error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.rouge),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              AppSpacing.vExtraLarge,

              AppButton(
                text: 'Publier l\'avis',
                isLoading: state.isLoading,
                onPressed: state.isLoading
                    ? null
                    : () => notifier.submit(
                          sellerId: widget.sellerId,
                          listingId: widget.listingId,
                          listingTitle: widget.listingTitle,
                          comment: _commentController.text,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //texte selon la note choisie
  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent !';
      default:
        return '';
    }
  }
}
