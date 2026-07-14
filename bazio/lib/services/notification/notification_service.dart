import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'bazio_main';
  static const _channelName = 'Bazio';

  //configuration initiale des services de notification
  static Future<void> init() async {
    //demande des autorisations systeme
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    //canal android pour les notifications prioritaires
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Messages et avis Bazio',
      importance: Importance.high,
    );
    
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    //parametres d initialisation locaux
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    await _local.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    //recuperation du token fcm en arriere plan
    _fetchAndSaveTokenInBackground();

    //mise a jour automatique si le token change
    _messaging.onTokenRefresh.listen(_saveToken);

    //gestion de la reception de messages au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  //recuperation asynchrone pour eviter de bloquer l interface
  //note : si l uid est absent (pas encore connecte), on ne fait rien
  //le token sera sauvegarde via saveTokenForCurrentUser() appele par AuthNotifier
  static void _fetchAndSaveTokenInBackground() {
    _messaging.getToken().then((token) {
      if (token == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _saveToken(token);
    }).catchError((_) {
      //echec silencieux si pas de reseau au demarrage
    });
  }

  //enregistrement du token dans le document utilisateur sur firestore
  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
    } catch (_) {
      //erreur ignoree si l utilisateur n existe pas encore en base
    }
  }

  //methode publique pour forcer la mise a jour apres connexion
  static void saveTokenForCurrentUser() {
    _messaging.getToken().then((token) {
      if (token != null) _saveToken(token);
    }).catchError((_) {});
  }

  //suppression des tokens lors de la deconnexion
  static Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()});
      await _messaging.deleteToken();
    } catch (_) {}
  }
}