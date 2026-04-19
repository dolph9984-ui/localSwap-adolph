import 'package:bazio/core/utils/error_helpers.dart';
import 'package:bazio/services/auth/auth_service.dart';
import 'package:bazio/services/notification/notification_service.dart';
import 'package:bazio/viewmodels/listing/favorites_notifier.dart';
import 'package:bazio/viewmodels/auth/auth_ui_provider.dart';
import 'package:bazio/viewmodels/listing/listing_providers.dart';
import 'package:bazio/viewmodels/location/user_location_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//le provider pour l'auth pour rester coherent avec les autres services
final authServiceProvider = Provider<AuthService>((_) => AuthService());

//on gere ici l'etat de connexion de toute l'appli
class AuthNotifier extends Notifier<User?> {
  late final AuthService _authService;

  @override
  User? build() {
    _authService = ref.read(authServiceProvider);
    //on surveille firebase en direct pour savoir si l'utilisateur change
    final sub = FirebaseAuth.instance.userChanges().listen((user) {
      state = user;
    });
    //on annule l'abonnement quand on quitte pour eviter les fuites de memoire
    ref.onDispose(() => sub.cancel());
    return _authService.getCurrentUser();
  }

  //inscription classique avec mail et mdp
  Future<void> signUp(String name, String email, String password) async {
    try {
      await _authService.signUp(name, email, password);
      //on retient le mail pour le mettre sur l'ecran de validation juste apres
      ref.read(pendingVerificationEmailProvider.notifier).set(email);
    } catch (e) {
      throw humanizeError(e);
    }
  }

  //connexion par mail
  Future<void> signIn(String email, String password) async {
    try {
      state = await _authService.signIn(email, password);
      _invalidateUserProviders();
      //on lie le token de notif au compte qui vient de se connecter
      NotificationService.saveTokenForCurrentUser();
    } catch (e) {
      throw humanizeError(e);
    }
  }

  //connexion via google
  Future<void> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) throw 'cancelled';
      state = user;
      _invalidateUserProviders();
      NotificationService.saveTokenForCurrentUser();
    } catch (e) {
      if (e.toString() == 'cancelled') rethrow;
      throw humanizeError(e);
    }
  }

  //on deconnecte le compte proprement
  Future<void> logOut() async {
    //on supprime le token pour plus recevoir de notifs une fois deco
    await NotificationService.clearToken();
    await _authService.logOut();
    state = null;
    _invalidateUserProviders();
  }

  //on reset les infos de l'utilisateur pour que le prochain ne voit pas les anciennes donnees
  void _invalidateUserProviders() {
    ref.invalidate(userLocationProvider);
    ref.invalidate(recentListingsProvider);
    ref.invalidate(nearbyListingsProvider);
    ref.invalidate(favoritesProvider);
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);