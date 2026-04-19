import 'package:cloud_firestore/cloud_firestore.dart';

//type de notif (nouveau message ou nouvel avis)
enum NotifType { message, review }

class NotificationModel {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final String? routePath; 
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.routePath,
    this.isRead = false,
    required this.createdAt,
  });

  //cree la notification depuis les donnees firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: (d['type'] as String?) == 'review'
          ? NotifType.review
          : NotifType.message,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      routePath: d['routePath'] as String?,
      isRead: d['isRead'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}