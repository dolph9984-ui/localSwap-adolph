import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/notification/notification_model.dart';
import 'package:bazio/viewmodels/notification/notification_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bazio/core/components/app_snack_bar.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  //bouton "tout lire" visible seulement s'il y a des non lues
                  notifsAsync.when(
                    data: (notifs) {
                      final hasUnread = notifs.any((n) => !n.isRead);
                      if (!hasUnread) return const SizedBox.shrink();
                      return TextButton(
                        onPressed: () => ref
                            .read(notificationNotifierProvider.notifier)
                            .markAllAsRead(),
                        child: Text(
                          'Tout lire',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: notifsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => AppErrorWidget(message: humanizeError(e)),
                data: (notifs) {
                  if (notifs.isEmpty) return const _EmptyNotifications();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NotifTile(notif: notifs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  //icone selon le type de notification
  IconData get _icon => notif.type == NotifType.message
      ? Icons.chat_bubble_outline_rounded
      : Icons.star_outline_rounded;

  Color get _iconColor => notif.type == NotifType.message
      ? AppColors.primary
      : const Color(0xFFFACC15);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        //on marque comme lue au tap
        if (!notif.isRead) {
          ref
              .read(notificationNotifierProvider.notifier)
              .markAsRead(notif.id);
        }
        //on navigue si une route est definie dans la notif
        if (notif.routePath != null && notif.routePath!.isNotEmpty) {
          context.push(notif.routePath!);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.white
              : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? AppColors.cardBg
                : AppColors.primary.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    //titre en gras si la notif n'est pas encore lue
                    style: notif.isRead
                        ? AppTextStyles.body
                            .copyWith(color: AppColors.blackOp, fontSize: 13)
                        : AppTextStyles.bodyBold
                            .copyWith(color: AppColors.blackOp, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grisNeutre, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatTime(notif.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: notif.isRead
                          ? AppColors.grisNeutre
                          : AppColors.primary,
                      fontSize: 11,
                      fontWeight: notif.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            //pastille bleue pour les notifications non lues
            if (!notif.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: AppTextStyles.h3.copyWith(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié ici\nquand vous recevez un message ou un avis.',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.body.copyWith(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
