import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/components/confirm_dialog.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/chat/chat_model.dart';
import 'package:bazio/viewmodels/messaging/chat_notifier.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/views/message/widget/message_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConversationAppBar extends ConsumerWidget {
  final String chatId;
  final String listingTitle;
  final String myUid;

  const ConversationAppBar({
    super.key,
    required this.chatId,
    required this.listingTitle,
    required this.myUid,
  });

  ChatModel? _findChat(List<ChatModel>? chats) => chats?.firstWhere(
    (c) => c.id == chatId,
    orElse: () => ChatModel(
      id: chatId,
      participants: [],
      listingId: '',
      listingTitle: listingTitle,
      lastMessage: '',
      lastMessageSenderId: '',
      sellerId: '',
      lastUpdate: DateTime.now(),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = _findChat(ref.watch(myChatsProvider).value);
    final isSeller = chat?.sellerId == myUid;
    final name = chat?.otherUserName ?? 'Conversation';
    final initials = buildInitials(name);
    final otherId = chat?.otherUserId(myUid) ?? '';
    final listingId = chat?.listingId ?? '';
    final isCompleted = chat?.isCompleted ?? false;
    final buyerId = chat?.buyerId ?? '';

    //l'acheteur peut noter seulement si la transaction est confirmee et que c'est lui le buyerId
    final canReview = !isSeller && isCompleted && buyerId == myUid;

    //statut vendu ecoute en temps reel
    final isSold = listingId.isNotEmpty
        ? (ref.watch(listingDetailProvider(listingId)).asData?.value.isSold ??
              false)
        : false;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.blackB,
            ),
            onPressed: () => context.pop(),
          ),

          //avatar cliquable vers le profil de l'interlocuteur
          GestureDetector(
            onTap: otherId.isNotEmpty
                ? () => context.push(
                    '/seller/$otherId'
                    '?sellerName=${Uri.encodeComponent(name)}'
                    '&listingId=$listingId'
                    '&listingTitle=${Uri.encodeComponent(listingTitle)}',
                  )
                : null,
            child: MessageAvatar(
              photoUrl: chat?.otherUserPhotoUrl,
              initials: initials,
              size: 42,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: GestureDetector(
              onTap: otherId.isNotEmpty
                  ? () => context.push(
                      '/seller/$otherId'
                      '?sellerName=${Uri.encodeComponent(name)}'
                      '&listingId=$listingId'
                      '&listingTitle=${Uri.encodeComponent(listingTitle)}',
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.blackOp,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //statut de la transaction sous le nom
                  if (isCompleted)
                    Text(
                      '✅ Transaction confirmée',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.green.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (isSold)
                    Text(
                      'Article vendu',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.orange.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          //bouton noter visible seulement pour l'acheteur confirme
          if (canReview)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: () => context.push(
                  '/leave-review/${chat!.sellerId}'
                  '?sellerName=${Uri.encodeComponent(name)}'
                  '&listingId=$listingId'
                  '&listingTitle=${Uri.encodeComponent(listingTitle)}',
                ),
                icon: const Icon(
                  Icons.star_outline_rounded,
                  size: 16,
                  color: Color(0xFFFACC15),
                ),
                label: const Text(
                  'Noter',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFACC15),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  backgroundColor: const Color(0xFFFACC15).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          //menu contextuel avec actions differentes selon le role
          PopupMenuButton<_Action>(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.blackB,
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (action) async {
              switch (action) {
                case _Action.viewProfile:
                  if (otherId.isNotEmpty) {
                    context.push(
                      '/seller/$otherId'
                      '?sellerName=${Uri.encodeComponent(name)}'
                      '&listingId=$listingId'
                      '&listingTitle=${Uri.encodeComponent(listingTitle)}',
                    );
                  }
                  break;

                case _Action.leaveReview:
                  if (canReview) {
                    context.push(
                      '/leave-review/${chat!.sellerId}'
                      '?sellerName=${Uri.encodeComponent(name)}'
                      '&listingId=$listingId'
                      '&listingTitle=${Uri.encodeComponent(listingTitle)}',
                    );
                  }
                  break;

                case _Action.markSold:
                  if (listingId.isEmpty || isCompleted) break;

                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Confirmer la vente ?',
                    message:
                        'Vous confirmez avoir vendu cet article à ${name}. '
                        'L\'acheteur pourra ensuite laisser un avis. '
                        'Cette action est irréversible.',
                    confirmLabel: 'Confirmer la vente',
                    confirmColor: Colors.green,
                    icon: Icons.check_circle_outline_rounded,
                  );

                  if (!confirmed) break;

                  try {
                    await ref
                        .read(messageNotifierProvider.notifier)
                        .markAsCompleted(
                          chatId: chatId,
                          buyerId: otherId,
                          listingId: listingId,
                        );
                  } catch (e) {
                    if (context.mounted) AppSnackBar.showError(context, e);
                  }
                  break;
              }
            },
            itemBuilder: (_) =>
                isSeller ? _sellerItems(isCompleted) : _buyerItems(canReview),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<_Action>> _buyerItems(bool canReview) => [
    _menuItem(
      _Action.viewProfile,
      Icons.person_outline_rounded,
      'Voir le profil',
      AppColors.blackB,
    ),
    if (canReview)
      _menuItem(
        _Action.leaveReview,
        Icons.star_outline_rounded,
        'Noter le vendeur',
        const Color(0xFFFACC15),
      ),
  ];

  List<PopupMenuEntry<_Action>> _sellerItems(bool isCompleted) => [
    _menuItem(
      _Action.viewProfile,
      Icons.person_outline_rounded,
      'Voir le profil',
      AppColors.blackB,
    ),
    if (!isCompleted)
      _menuItem(
        _Action.markSold,
        Icons.check_circle_outline_rounded,
        'Confirmer la vente',
        Colors.green,
      ),
    if (isCompleted)
      _menuItem(
        _Action.markSold,
        Icons.verified_rounded,
        'Vente confirmée',
        Colors.grey,
      ),
  ];

  PopupMenuItem<_Action> _menuItem(
    _Action value,
    IconData icon,
    String label,
    Color color,
  ) => PopupMenuItem(
    value: value,
    //desactive si la vente est deja confirmee
    enabled:
        value != _Action.markSold ||
        label != 'Vente confirmée',
    child: Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: label == 'Vente confirmée' ? Colors.grey : AppColors.blackB,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

String buildInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

enum _Action { viewProfile, leaveReview, markSold }
