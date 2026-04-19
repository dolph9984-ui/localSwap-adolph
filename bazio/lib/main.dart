import 'dart:convert';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/router/app_router.dart';
import 'package:bazio/model/listing/draft_model.dart';
import 'package:bazio/services/notification/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

//gestion personnalisee du cache pour les images distantes
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'bazio_img_cache';
  static final AppImageCacheManager _instance = AppImageCacheManager._();
  factory AppImageCacheManager() => _instance;

  AppImageCacheManager._()
      : super(Config(
          key,
          maxNrOfCacheObjects: 200, 
          stalePeriod: const Duration(days: 7), 
        ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  //optimisation firestore : persistance activee et limitee a 50mo
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
  );

  await Hive.initFlutter();

  //securisation de la cle de chiffrement via android keystore / ios keychain
  //cela rend les donnees hive illisibles meme sur un telephone rooté
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  String? keyString = await secureStorage.read(key: 'hive_encryption_key');
  if (keyString == null) {
    final key = Hive.generateSecureKey();
    keyString = base64Url.encode(key);
    await secureStorage.write(key: 'hive_encryption_key', value: keyString);
  }

  final encryptionKey = base64Url.decode(keyString);

  //enregistrement de l'adapter pour stocker nos modeles personnalises dans hive
  Hive.registerAdapter(DraftModelAdapter());
  
  //ouverture de la box des brouillons avec chiffrement aes-256
  await Hive.openBox<DraftModel>(
    'drafts',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  //initialisation du service de notifications locales et push
  await NotificationService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bazio',
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgB,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}