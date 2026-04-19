import 'package:bazio/model/notification/notification_model.dart';
import 'package:bazio/services/notification/notification_db_service.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationDbServiceProvider =
    Provider<NotificationDbService>((_) => NotificationDbService());

//on ecoute les notifications de l'utilisateur en temps reel
final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final uid = ref.watch(authProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(notificationDbServiceProvider).getNotifications(uid);
});

//on compte le nombre de notifications pas encore lues
final unreadNotifCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});

//actions pour gerer le statut de lecture des notifications
class NotificationNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markAsRead(String notifId) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) return;
    await ref
        .read(notificationDbServiceProvider)
        .markAsRead(uid, notifId);
  }

  Future<void> markAllAsRead() async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) return;
    await ref.read(notificationDbServiceProvider).markAllAsRead(uid);
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, void>(NotificationNotifier.new);