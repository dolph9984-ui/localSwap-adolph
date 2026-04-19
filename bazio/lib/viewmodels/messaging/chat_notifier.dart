import 'package:bazio/core/utils/error_helpers.dart';
import 'package:bazio/services/chat/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bazio/model/chat/chat_model.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';

final chatServiceProvider = Provider<ChatService>((_) => ChatService());

//recupere toutes les convos du user
final myChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return const Stream.empty();
  return ref.read(chatServiceProvider).getMyChats(user.uid);
});

//gestion de l'onglet actif 0 achat 1 vente
class ChatTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final chatTabProvider =
    NotifierProvider<ChatTabNotifier, int>(ChatTabNotifier.new);

//filtre pour voir que les non lus
class ShowUnreadOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setUnreadOnly(bool value) => state = value;
}

final showUnreadOnlyProvider =
    NotifierProvider<ShowUnreadOnlyNotifier, bool>(ShowUnreadOnlyNotifier.new);

//application des filtres onglet et statut de lecture
final filteredChatsProvider = Provider<List<ChatModel>>((ref) {
  final allChats = ref.watch(myChatsProvider).value ?? [];
  final currentUser = ref.watch(authProvider);
  final selectedTab = ref.watch(chatTabProvider);
  final unreadOnly = ref.watch(showUnreadOnlyProvider);

  if (currentUser == null) return [];

  final byTab = selectedTab == 0
      ? allChats.where((c) => c.sellerId != currentUser.uid)
      : allChats.where((c) => c.sellerId == currentUser.uid);

  if (unreadOnly) {
    return byTab.where((c) => c.isUnreadFor(currentUser.uid)).toList();
  }
  return byTab.toList();
});

//compteur pour la pastille dans la barre de nav
final unreadChatsCountProvider = Provider<int>((ref) {
  final allChats = ref.watch(myChatsProvider).value ?? [];
  final uid = ref.watch(authProvider)?.uid;
  if (uid == null) return 0;
  return allChats.where((c) => c.isUnreadFor(uid)).length;
});

//stream des messages pour une convo precise
final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<MessageModel>, String>(
  (ref, chatId) => ref.read(chatServiceProvider).getMessages(chatId),
);

//stocke les messages en memoire pendant l'envoi reseau pour eviter les bugs d'affichage
class PendingMessagesNotifier
    extends Notifier<Map<String, List<MessageModel>>> {
  @override
  Map<String, List<MessageModel>> build() => {};

  void add(String chatId, MessageModel msg) {
    final current = Map<String, List<MessageModel>>.from(state);
    current[chatId] = [msg, ...(current[chatId] ?? [])];
    state = current;
  }

  void markFailed(String chatId, String tempId) {
    final current = Map<String, List<MessageModel>>.from(state);
    final msgs = List<MessageModel>.from(current[chatId] ?? []);
    final idx = msgs.indexWhere((m) => m.id == tempId);
    if (idx != -1) {
      msgs[idx] = msgs[idx].copyWith(status: MessageStatus.failed);
      current[chatId] = msgs;
      state = current;
    }
  }

  void remove(String chatId, String tempId) {
    final current = Map<String, List<MessageModel>>.from(state);
    final msgs = current[chatId] ?? [];
    current[chatId] = msgs.where((m) => m.id != tempId).toList();
    state = current;
  }

  List<MessageModel> forChat(String chatId) => state[chatId] ?? [];

  void clearFailed(String chatId) {
    final current = Map<String, List<MessageModel>>.from(state);
    current[chatId] = (current[chatId] ?? [])
        .where((m) => m.status != MessageStatus.failed)
        .toList();
    state = current;
  }
}

final pendingMessagesProvider =
    NotifierProvider<PendingMessagesNotifier, Map<String, List<MessageModel>>>(
        PendingMessagesNotifier.new);

//centralise toutes les actions de messagerie evite de passer par le service dans l'ui
class MessageNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markAsRead(String chatId) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) return;
    await ref.read(chatServiceProvider).markAsRead(chatId, uid);
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) return;
    try {
      await ref.read(chatServiceProvider).sendMessage(
            chatId: chatId,
            senderId: uid,
            text: text,
          );
    } catch (e) {
      throw humanizeError(e);
    }
  }

  Future<String> getOrCreateChat({
    required String sellerId,
    required String listingId,
    required String listingTitle,
  }) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) throw Exception('Non connecté');
    try {
      return await ref.read(chatServiceProvider).getOrCreateChat(
            currentUserId: uid,
            sellerId: sellerId,
            listingId: listingId,
            listingTitle: listingTitle,
          );
    } catch (e) {
      throw humanizeError(e);
    }
  }

  Future<void> sendOffer({
    required String chatId,
    required double amount,
  }) async {
    final uid = ref.read(authProvider)?.uid;
    if (uid == null) return;
    try {
      await ref.read(chatServiceProvider).sendOffer(
            chatId: chatId,
            senderId: uid,
            amount: amount,
          );
    } catch (e) {
      throw humanizeError(e);
    }
  }

  Future<void> markAsCompleted({
    required String chatId,
    required String buyerId,
    required String listingId,
  }) async {
    final sellerId = ref.read(authProvider)?.uid;
    if (sellerId == null) return;
    try {
      await ref.read(chatServiceProvider).markAsCompleted(
            chatId: chatId,
            buyerId: buyerId,
            sellerId: sellerId,
            listingId: listingId,
          );
    } catch (e) {
      throw humanizeError(e);
    }
  }
}

final messageNotifierProvider =
    NotifierProvider<MessageNotifier, void>(MessageNotifier.new);