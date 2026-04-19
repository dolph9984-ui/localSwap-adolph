import 'package:cloud_firestore/cloud_firestore.dart';

//etats d'envoi du message
enum MessageStatus { sent, pending, failed }

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final bool isSystem;
  final MessageStatus status;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.isSystem = false,
    this.status = MessageStatus.sent,
  });

  //convertit les donnees firestore en objet message
  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
      isSystem: data['isSystem'] as bool? ?? false,
      status: MessageStatus.sent,
    );
  }

  MessageModel copyWith({MessageStatus? status}) => MessageModel(
        id: id,
        senderId: senderId,
        text: text,
        timestamp: timestamp,
        isRead: isRead,
        imageUrl: imageUrl,
        isSystem: isSystem,
        status: status ?? this.status,
      );
}

class ChatModel {
  final String id;
  final List<String> participants;
  final String listingId;
  final String listingTitle;
  final String lastMessage;
  final String lastMessageSenderId;
  final String sellerId;
  final DateTime lastUpdate;
  final List<String> readBy;
  final String? otherUserName;
  final String? otherUserPhotoUrl;

  //suivi de la transaction (si c'est vendu et a qui)
  final bool isCompleted;   
  final String? buyerId;    

  const ChatModel({
    required this.id,
    required this.participants,
    required this.listingId,
    required this.listingTitle,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.sellerId,
    required this.lastUpdate,
    this.readBy = const [],
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.isCompleted = false,
    this.buyerId,
  });

  //trouve l'id de l'autre personne
  String otherUserId(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  //check si j'ai des messages non lus
  bool isUnreadFor(String myUid) =>
      lastMessageSenderId != myUid &&
      lastMessage.isNotEmpty &&
      !readBy.contains(myUid);

  //autorise l'avis si je suis l'acheteur de cette vente
  bool canReview(String myUid) => isCompleted && buyerId == myUid;

  //map le document firestore vers le modele chat
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      listingId: data['listingId'] as String? ?? '',
      listingTitle: data['listingTitle'] as String? ?? 'Annonce',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      lastUpdate:
          (data['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
      isCompleted: data['isCompleted'] as bool? ?? false,
      buyerId: data['buyerId'] as String?,
    );
  }

  ChatModel copyWith({
    String? otherUserName,
    String? otherUserPhotoUrl,
    bool? isCompleted,
    String? buyerId,
  }) =>
      ChatModel(
        id: id,
        participants: participants,
        listingId: listingId,
        listingTitle: listingTitle,
        lastMessage: lastMessage,
        lastMessageSenderId: lastMessageSenderId,
        sellerId: sellerId,
        lastUpdate: lastUpdate,
        readBy: readBy,
        otherUserName: otherUserName ?? this.otherUserName,
        otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
        isCompleted: isCompleted ?? this.isCompleted,
        buyerId: buyerId ?? this.buyerId,
      );
}