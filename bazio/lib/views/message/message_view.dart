import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/components/app_tab_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/model/chat/chat_model.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/messaging/chat_notifier.dart';
import 'package:bazio/views/message/widget/chat_tile.dart';
import 'package:bazio/views/message/widget/conversation_app_bar.dart';
import 'package:bazio/views/message/widget/input_bar.dart';
import 'package:bazio/views/message/widget/listing_banner.dart';
import 'package:bazio/views/message/widget/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//liste de toutes les conversations de l'utilisateur
class MessagesView extends ConsumerStatefulWidget {
  const MessagesView({super.key});

  @override
  ConsumerState<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends ConsumerState<MessagesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    //on synchronise l'onglet actif avec le provider pour filtrer les bons chats
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(chatTabProvider.notifier).setTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(filteredChatsProvider);
    final myUid = ref.watch(authProvider)?.uid ?? '';
    final unreadOnly = ref.watch(showUnreadOnlyProvider);

    //comptage independant du filtre pour afficher le bon badge sur "Non lus"
    final allChats = ref.watch(myChatsProvider).value ?? [];
    final currentUser = ref.watch(authProvider);
    final selectedTab = ref.watch(chatTabProvider);
    final unreadCount = currentUser == null
        ? 0
        : (selectedTab == 0
                ? allChats.where((c) => c.sellerId != currentUser.uid)
                : allChats.where((c) => c.sellerId == currentUser.uid))
            .where((c) => c.isUnreadFor(currentUser.uid))
            .length;

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                'Messages',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            //onglets achats et ventes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppTabBar(
                controller: _tabController,
                tabs: const ['Achats', 'Ventes'],
              ),
            ),
            const SizedBox(height: 12),

            //filtre tout / non lus
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _UnreadFilterChips(
                unreadOnly: unreadOnly,
                unreadCount: unreadCount,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: chats.isEmpty
                  ? _EmptyConversations(unreadOnly: unreadOnly)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          ChatTile(chat: chats[i], myUid: myUid),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadFilterChips extends ConsumerWidget {
  final bool unreadOnly;
  final int unreadCount;

  const _UnreadFilterChips({
    required this.unreadOnly,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _FilterChip(
          label: 'Tout',
          isSelected: !unreadOnly,
          onTap: () =>
              ref.read(showUnreadOnlyProvider.notifier).setUnreadOnly(false),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Non lus',
          isSelected: unreadOnly,
          badgeCount: unreadCount,
          onTap: () =>
              ref.read(showUnreadOnlyProvider.notifier).setUnreadOnly(true),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          //selectionne = couleur pleine sinon gris discret
          color: isSelected ? AppColors.primary : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF9AA5B1),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.rouge,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  final bool unreadOnly;
  const _EmptyConversations({required this.unreadOnly});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unreadOnly
                ? Icons.mark_chat_read_outlined
                : Icons.chat_bubble_outline_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            unreadOnly ? 'Aucun message non lu' : 'Aucune conversation',
            style: AppTextStyles.bodyBold
                .copyWith(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 6),
          Text(
            unreadOnly
                ? 'Vous êtes à jour !'
                : 'Vos échanges apparaîtront ici.',
            style:
                AppTextStyles.caption.copyWith(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

//vue d'une conversation individuelle
class MessageView extends ConsumerStatefulWidget {
  final String chatId;
  final String listingTitle;

  const MessageView({
    super.key,
    required this.chatId,
    required this.listingTitle,
  });

  @override
  ConsumerState<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends ConsumerState<MessageView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    //on marque la conversation comme lue a l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authProvider)?.uid;
      if (uid != null) {
        ref.read(messageNotifierProvider.notifier).markAsRead(widget.chatId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final uid = ref.read(authProvider)?.uid;
    if (text.isEmpty || uid == null) return;

    _controller.clear();

    //message temporaire affiche immediatement pendant l'envoi
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final pendingMsg = MessageModel(
      id: tempId,
      senderId: uid,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.pending,
    );

    ref.read(pendingMessagesProvider.notifier).add(widget.chatId, pendingMsg);

    try {
      await ref.read(messageNotifierProvider.notifier).sendMessage(
          chatId: widget.chatId, text: text);
      ref.read(pendingMessagesProvider.notifier).remove(widget.chatId, tempId);
    } catch (e) {
      //on marque le message comme echoue si l'envoi plante
      ref
          .read(pendingMessagesProvider.notifier)
          .markFailed(widget.chatId, tempId);
      if (mounted) {
        _controller.text = text;
        AppSnackBar.show(
          context,
          message: e.toString(),
          type: SnackType.error,
        );
      }
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final myUid = ref.watch(authProvider)?.uid ?? '';
    final localMsgs = ref.watch(
        pendingMessagesProvider.select((map) => map[widget.chatId] ?? const []));

    //on re-marque comme lue quand de nouveaux messages arrivent
    ref.listen(chatMessagesProvider(widget.chatId), (_, next) {
      if (next.hasValue && next.value!.isNotEmpty) {
        ref.read(messageNotifierProvider.notifier).markAsRead(widget.chatId);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            ConversationAppBar(
              chatId: widget.chatId,
              listingTitle: widget.listingTitle,
              myUid: myUid,
            ),
            ListingBanner(
              chatId: widget.chatId,
              listingTitle: widget.listingTitle,
            ),
            const SizedBox(height: 8),

            Expanded(
              child: messagesAsync.when(
                data: (msgs) {
                  //on fusionne messages confirmes et messages en attente
                  final allMsgs = [
                    ...localMsgs,
                    ...msgs.where((m) => !localMsgs.any(
                          (lm) =>
                              lm.status == MessageStatus.pending &&
                              lm.text == m.text &&
                              m.timestamp
                                      .difference(lm.timestamp)
                                      .inSeconds
                                      .abs() <
                                  15,
                        )),
                  ];

                  if (allMsgs.isEmpty) {
                    return Center(
                      child: Text(
                        'Dites bonjour 👋',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.grisNeutre),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: allMsgs.length,
                    itemBuilder: (_, i) {
                      final msg = allMsgs[i];
                      final isMe = msg.senderId == myUid;
                      //separateur de date quand le jour change
                      final showDate = i == allMsgs.length - 1 ||
                          !_sameDay(msg.timestamp, allMsgs[i + 1].timestamp);
                      //avatar seulement sur le premier message consecutif d'un autre
                      final showAvatar = !isMe &&
                          (i == 0 ||
                              allMsgs[i - 1].senderId != msg.senderId);

                      return Column(children: [
                        if (showDate) DateSeparator(date: msg.timestamp),
                        MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          chatId: widget.chatId,
                        ),
                      ]);
                    },
                  );
                },
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ),
            ),

            InputBar(
              controller: _controller,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}
