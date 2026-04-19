import 'package:bazio/services/user/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//on recupere les donnees du profil via le service dedié
final sellerInfoProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, sellerId) async {
    return ref.read(userServiceProvider).getUserProfile(sellerId);
  },
);