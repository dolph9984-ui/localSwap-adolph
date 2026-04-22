import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/components/app_button.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/components/input_decoration.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/listing/listing_model.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/messaging/chat_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ListingBottomBar extends ConsumerWidget {
  final ListingModel listing;
  const ListingBottomBar({super.key, required this.listing});

  void _showOfferDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OfferSheet(listing: listing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: AppColors.bgO,
        border: Border(top: BorderSide(color: AppColors.cardBg)),
      ),
      child: Row(
        children: [
          _ChatButton(listing: listing),
          AppSpacing.hMedium,
          Expanded(
            child: AppButton(
              text: listing.isSold ? 'Vendu' : 'Faire une offre',
              //bouton desactive si l'article est marque vendu
              onPressed: listing.isSold
                  ? null
                  : () => _showOfferDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferSheet extends ConsumerStatefulWidget {
  final ListingModel listing;
  const _OfferSheet({required this.listing});

  @override
  ConsumerState<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends ConsumerState<_OfferSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);

    //validations avant envoi
    if (raw.isEmpty) {
      setState(() => _error = 'Entrez un montant');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Montant invalide');
      return;
    }
    if (amount > widget.listing.price * 10) {
      setState(() => _error = 'Montant trop élevé');
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) {
      if (mounted) context.push('/login');
      return;
    }
    //on empeche de faire une offre sur sa propre annonce
    if (user.uid == widget.listing.sellerId) {
      setState(() => _error =
          'Vous ne pouvez pas faire une offre sur votre propre annonce');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final chatId = await ref
          .read(messageNotifierProvider.notifier)
          .getOrCreateChat(
            sellerId: widget.listing.sellerId,
            listingId: widget.listing.id,
            listingTitle: widget.listing.title,
          );

      await ref.read(messageNotifierProvider.notifier).sendOffer(
            chatId: chatId,
            amount: amount,
          );

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.show(
          context,
          message: 'Offre de ${amount.toInt()} Ar envoyée !',
          type: SnackType.success,
        );
        //on passe le titre via extra pour eviter les problemes d'encodage URI
        context.push(
          '/messages/$chatId',
          extra: widget.listing.title,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = humanizeError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestedPrice = widget.listing.price;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Proposer un prix', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Prix demandé : ${suggestedPrice.toInt()} Ar',
            style: AppTextStyles.caption.copyWith(color: AppColors.grisNeutre),
          ),
          AppSpacing.vMedium,

          //suggestions rapides a 80% 90% et 100% du prix demande
          Row(
            children: [
              _PricePill(
                label: '${(suggestedPrice * 0.8).toInt()} Ar',
                onTap: () => _controller.text =
                    (suggestedPrice * 0.8).toInt().toString(),
              ),
              const SizedBox(width: 8),
              _PricePill(
                label: '${(suggestedPrice * 0.9).toInt()} Ar',
                onTap: () => _controller.text =
                    (suggestedPrice * 0.9).toInt().toString(),
              ),
              const SizedBox(width: 8),
              _PricePill(
                label: '${suggestedPrice.toInt()} Ar',
                onTap: () =>
                    _controller.text = suggestedPrice.toInt().toString(),
              ),
            ],
          ),
          AppSpacing.vMedium,

          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: AppTextStyles.h3.copyWith(color: AppColors.blackOp),
            decoration: AppInputDecoration.defaultStyle(
              hint: 'Ex : ${suggestedPrice.toInt()}',
              label: 'Votre offre (Ar)',
            ).copyWith(
              errorText: _error,
              suffixText: 'Ar',
              suffixStyle:
                  AppTextStyles.bodyBold.copyWith(color: AppColors.grisNeutre),
            ),
          ),

          AppSpacing.vLarge,

          AppButton(
            text: _loading ? 'Envoi...' : "Envoyer l'offre",
            isLoading: _loading,
            onPressed: _loading ? null : _send,
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PricePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: AppColors.primary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ChatButton extends ConsumerStatefulWidget {
  final ListingModel listing;
  const _ChatButton({required this.listing});

  @override
  ConsumerState<_ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends ConsumerState<_ChatButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.listing.isSold
          ? null
          : () async {
              final user = ref.read(authProvider);
              if (user == null) {
                context.push('/login');
                return;
              }
              //on ignore si c'est le proprietaire
              if (user.uid == widget.listing.sellerId) return;

              setState(() => _loading = true);
              try {
                final chatId = await ref
                    .read(messageNotifierProvider.notifier)
                    .getOrCreateChat(
                      sellerId: widget.listing.sellerId,
                      listingId: widget.listing.id,
                      listingTitle: widget.listing.title,
                    );
                if (mounted) {
                  //on passe le titre via extra pour eviter les problemes d'encodage URI
                  context.push(
                    '/messages/$chatId',
                    extra: widget.listing.title,
                  );
                }
              } catch (e) {
                if (mounted) AppSnackBar.showError(context, e);
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          shape: BoxShape.circle,
        ),
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.chat_bubble_outline, color: AppColors.bleu),
      ),
    );
  }
}