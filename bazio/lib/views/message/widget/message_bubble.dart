import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/chat/chat_model.dart';
import 'package:bazio/viewmodels/messaging/chat_notifier.dart';
import 'package:bazio/views/message/widget/message_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

//separateur de date entre groupes de messages d'un jour different
class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return DateFormat('d MMMM yyyy', 'fr').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        const Expanded(child: Divider(color: Color(0xFFDDE3EA))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _label().toUpperCase(),
            style: AppTextStyles.captionBold.copyWith(
              color: AppColors.grisNeutre,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDE3EA))),
      ]),
    );
  }
}

//bulle de message texte normale ou message systeme
class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final String chatId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //les messages systeme s'affichent centres sans bulle
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grisNeutre,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    //on recupere l'avatar de l'interlocuteur uniquement pour les messages recus
    String? otherPhotoUrl;
    String otherInitials = '?';
    if (!isMe) {
      final chat = ref.watch(myChatsProvider).value?.firstWhere(
            (c) => c.id == chatId,
            orElse: () => ChatModel(
              id: chatId,
              participants: [],
              listingId: '',
              listingTitle: '',
              lastMessage: '',
              lastMessageSenderId: '',
              sellerId: '',
              lastUpdate: DateTime.now(),
            ),
          );
      otherPhotoUrl = chat?.otherUserPhotoUrl;
      otherInitials = buildInitials(chat?.otherUserName ?? '');
    }

    final time = DateFormat('HH:mm').format(message.timestamp);
    final isPending = message.status == MessageStatus.pending;
    final isFailed = message.status == MessageStatus.failed;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          //avatar de l'interlocuteur a gauche pour les messages recus
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: showAvatar
                  ? MessageAvatar(
                      photoUrl: otherPhotoUrl,
                      initials: otherInitials,
                      size: 30)
                  //espace reserve si pas d'avatar pour aligner les bulles
                  : const SizedBox(width: 30),
            ),

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                //bulle semi-transparente pendant l'envoi
                Opacity(
                  opacity: isPending ? 0.65 : 1.0,
                  child: _TextBubble(
                    text: message.text,
                    isMe: isMe,
                    isFailed: isFailed,
                  ),
                ),

                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //indicateur de statut uniquement sur mes messages
                    if (isMe) ...[
                      if (isPending)
                        const Padding(
                          padding: EdgeInsets.only(right: 3),
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.grisNeutre,
                            ),
                          ),
                        )
                      else if (isFailed)
                        const Padding(
                          padding: EdgeInsets.only(right: 3),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 12,
                            color: AppColors.rouge,
                          ),
                        ),
                    ],
                    Text(
                      isFailed ? 'Échec' : time,
                      style: AppTextStyles.caption.copyWith(
                        color: isFailed
                            ? AppColors.rouge
                            : AppColors.grisNeutre,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isFailed;
  const _TextBubble({
    required this.text,
    required this.isMe,
    this.isFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        //rouge si echoue bleu si moi blanc si autre
        color: isFailed
            ? AppColors.rouge.withOpacity(0.12)
            : isMe
                ? AppColors.primary
                : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        border: isFailed
            ? Border.all(color: AppColors.rouge.withOpacity(0.4), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: isFailed
              ? AppColors.rouge
              : isMe
                  ? Colors.white
                  : AppColors.blackB,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
