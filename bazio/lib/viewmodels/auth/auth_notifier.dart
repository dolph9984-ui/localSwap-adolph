import 'package:bazio/services/auth_service.dart';
import 'package:bazio/services/local_service.dart';
import 'package:bazio/services/notification_service.dart';
import 'package:bazio/viewmodels/auth/auth_ui_provider.dart';
import 'package:bazio/viewmodels/listing_notifier.dart';
import 'package:bazio/viewmodels/user_location_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//gestion de l'etat d'authentification global de l'app
class AuthNotifier extends Notifier<User?> {
  late final AuthService _authService;

  @override
  User? build() {
    _authService = AuthService();
    //on ecoute les changements d'etat de firebase en temps reel
    final sub = FirebaseAuth.instance.userChanges().listen((user) {
      state = user;
    });
    //on nettoie l'ecouteur quand le provider est detruit
    ref.onDispose(() => sub.cancel());
    return _authService.getCurrentUser();
  }

  //creation de compte classique
  Future<void> signUp(String name, String email, String password) async {
    try {
      await _authService.signUp(name, email, password);
      //on stocke l'email pour l'afficher sur la page de verification
      ref.read(pendingVerificationEmailProvider.notifier).set(email);
    } catch (e) {
      throw _mapError(e);
    }
  }

  //connexion par email/password
  Future<void> signIn(String email, String password) async {
    try {
      state = await _authService.signIn(email, password);
      _invalidateUserProviders();
      //on enregistre le token de notification pour ce nouvel utilisateur
      NotificationService.saveTokenForCurrentUser();
    } catch (e) {
      throw _mapError(e);
    }
  }

  //connexion via le compte google
  Future<void> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) throw 'cancelled';
      state = user;
      _invalidateUserProviders();
      NotificationService.saveTokenForCurrentUser();
    } catch (e) {
      if (e.toString() == 'cancelled') rethrow;
      throw _mapError(e);
    }
  }

  //deconnexion propre du compte
  Future<void> logOut() async {
    //on vire le token FCM pour ne plus recevoir de notifications
    await NotificationService.clearToken();
    //deconnexion de firebase
    await _authService.logOut();
    state = null;
    //on reset tous les providers lies a l'utilisateur
    _invalidateUserProviders();
  }

  //on force le rafraichissement des donnees liees a l'utilisateur
  void _invalidateUserProviders() {
    ref.invalidate(userLocationProvider);
    ref.invalidate(recentListingsProvider);
    ref.invalidate(nearbyListingsProvider);
    ref.invalidate(favoritesProvider);
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

//on transforme les codes erreurs techniques en phrases comprehensibles
String _mapError(dynamic e) {
  switch (e.toString()) {
    case 'invalid-credential':
      return 'Email ou mot de passe incorrect';
    case 'email-already-in-use':
      return 'Un compte existe déjà avec cet email';
    case 'weak-password':
      return 'Le mot de passe est trop court';
    case 'network-request-failed':
      return 'Pas de connexion internet';
    case 'too-many-requests':
      return 'Trop de tentatives, réessayez plus tard';
    case 'invalid-email':
      return 'Adresse email invalide';
    case 'email-not-verified':
      return 'Veuillez vérifier votre email avant de vous connecter';
    default:
      return 'Une erreur est survenue';
  }
}