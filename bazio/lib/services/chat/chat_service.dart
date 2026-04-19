import 'package:bazio/model/chat/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;

  //recupere mes chats et ajoute le nom/photo de l'autre personne
  Stream<List<ChatModel>> getMyChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdate', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final chats =
          snap.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
      return Future.wait(chats.map((chat) async {
        final otherId = chat.otherUserId(userId);
        if (otherId.isEmpty) return chat;
        try {
          final doc =
              await _firestore.collection('users').doc(otherId).get();
          final data = doc.data();
          return chat.copyWith(
            otherUserName: data?['name'] as String?,
            otherUserPhotoUrl: data?['photoUrl'] as String?,
          );
        } catch (_) {
          return chat;
        }
      }));
    });
  }

  //ouvre un chat existant ou en cree un nouveau pour une annonce
  Future<String> getOrCreateChat({
    required String currentUserId,
    required String sellerId,
    required String listingId,
    required String listingTitle,
  }) async {
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('listingId', isEqualTo: listingId)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.id;

    final doc = await _firestore.collection('chats').add({
      'participants': [currentUserId, sellerId],
      'listingId': listingId,
      'listingTitle': listingTitle,
      'lastMessage': '',
      'lastMessageSenderId': '',
      'sellerId': sellerId,
      'lastUpdate': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
      'isCompleted': false,
      'buyerId': null,
    });
    return doc.id;
  }

  //flux de messages triés par date
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  //enregistre le message et met a jour l'apercu du chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final batch = _firestore.batch();
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': text,
      'lastMessageSenderId': senderId,
      'lastUpdate': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });

    await batch.commit();
  }

  //ajoute l'utilisateur a la liste de ceux qui ont lu
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  //envoie un message special pour une offre de prix
  Future<void> sendOffer({
    required String chatId,
    required String senderId,
    required double amount,
  }) async {
    await sendMessage(
      chatId: chatId,
      senderId: senderId,
      text: 'Offre proposé : ${amount.toInt()} Ar',
    );
  }

  //valide la vente, bloque l'annonce et previent les autres acheteurs
  Future<void> markAsCompleted({
    required String chatId,
    required String buyerId,
    required String sellerId,
    required String listingId,
  }) async {
    final batch = _firestore.batch();
    const sysText = '✅ Transaction confirmée. Merci pour votre confiance !';

    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'isCompleted': true,
      'buyerId': buyerId,
      'lastMessage': sysText,
      'lastMessageSenderId': sellerId,
      'lastUpdate': FieldValue.serverTimestamp(),
      'readBy': [sellerId],
    });

    final msgRef = chatRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': sellerId,
      'text': sysText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isSystem': true,
    });

    final listingRef = _firestore.collection('listings').doc(listingId);
    batch.update(listingRef, {'isSold': true});

    await batch.commit();

    await broadcastSoldStatus(
      listingId: listingId,
      isSold: true,
      senderId: sellerId,
      excludeChatId: chatId,
    );
  }

  //envoie un message automatique dans tous les chats liés a cette annonce
  Future<void> broadcastSoldStatus({
    required String listingId,
    required bool isSold,
    required String senderId,
    String? excludeChatId,
  }) async {
    final snap = await _firestore
        .collection('chats')
        .where('listingId', isEqualTo: listingId)
        .get();

    final msg = isSold
        ? '🔴 Cet article a été vendu.'
        : '🟢 Cet article est à nouveau disponible.';

    for (final doc in snap.docs) {
      final chatId = doc.id;
      if (chatId == excludeChatId) continue;
      
      final batch = _firestore.batch();
      final msgRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderId': senderId,
        'text': msg,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isSystem': true,
      });

      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': msg,
        'lastMessageSenderId': senderId,
        'lastUpdate': FieldValue.serverTimestamp(),
        'readBy': [senderId],
      });

      await batch.commit();
    }
  }
}