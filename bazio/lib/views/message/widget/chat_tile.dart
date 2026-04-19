import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/chat/chat_model.dart';
import 'package:bazio/views/message/widget/message_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String myUid;

  const ChatTile({super.key, required this.chat, required this.myUid});

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = chat.isUnreadFor(myUid);
    final name = chat.otherUserName ?? 'Utilisateur';
    final initials = buildInitials(name);

    return InkWell(
      onTap: () => context.push(
        '/messages/${chat.id}'
        '?listingTitle=${Uri.encodeComponent(chat.listingTitle)}',
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          //fond legerement colore si la conversation a des messages non lus
          color: isUnread ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withOpacity(0.18)
                : AppColors.cardBg,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            //avatar avec pastille bleue si non lu
            Stack(children: [
              MessageAvatar(
                  photoUrl: chat.otherUserPhotoUrl,
                  initials: initials,
                  size: 50),
              if (isUnread)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ]),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        name,
                        //nom en gras si non lu
                        style: isUnread
                            ? AppTextStyles.bodyBold
                                .copyWith(color: AppColors.blackOp)
                            : AppTextStyles.body
                                .copyWith(color: AppColors.blackOp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(chat.lastUpdate),
                      style: AppTextStyles.caption.copyWith(
                        color:
                            isUnread ? AppColors.primary : AppColors.grisNeutre,
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),

                  //titre de l'annonce concernee
                  Text(
                    chat.listingTitle,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  Text(
                    chat.lastMessage.isEmpty
                        ? 'Démarrer la conversation...'
                        : chat.lastMessage,
                    style: AppTextStyles.caption.copyWith(
                      color: isUnread ? AppColors.blackB : AppColors.grisNeutre,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
