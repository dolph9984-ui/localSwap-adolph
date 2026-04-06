import 'package:bazio/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//gestion de l etat de l utilisateur connecte
class AuthNotifier extends Notifier<User?> {
  late final AuthService _authService;

  @override
  User? build() {
    _authService = AuthService();
    return _authService.getCurrentUser();
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      await _authService.signUp(name, email, password);
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = await _authService.signIn(email, password);
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) throw 'cancelled';
      state = user;
    } catch (e) {
      if (e.toString() == 'cancelled') throw 'cancelled';
      throw _mapError(e);
    }
  }

  Future<void> logOut() async {
    await _authService.logOut();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

//sert a transmettre des messages entre les vues via le router
class StringOrNullNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final successMessageProvider = NotifierProvider<StringOrNullNotifier, String?>(StringOrNullNotifier.new);
final pendingVerificationEmailProvider = NotifierProvider<StringOrNullNotifier, String?>(StringOrNullNotifier.new);

//notifier booleen generique pour loading et visibility
class BoolNotifier extends Notifier<bool> {
  final bool initial;
  BoolNotifier(this.initial);
  @override
  bool build() => initial;
  void toggle() => state = !state;
  void setValue(bool v) => state = v;
}

final obscureLoginPasswordProvider = NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));
final obscureRegisterPasswordProvider = NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));
final obscureConfirmPasswordProvider = NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));
final loginFormValidProvider = NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(false));
final loginLoadingProvider = NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(false));
final registerLoadingProvider = NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(false));
final googleLoadingProvider = NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(false));

String _mapError(dynamic e) {
  switch (e.toString()) {
    case 'invalid-credential': return 'Email ou mot de passe incorrect';
    case 'email-already-in-use': return 'Un compte existe déjà avec cet email';
    case 'weak-password': return 'Le mot de passe est trop court';
    case 'network-request-failed': return 'Pas de connexion internet';
    case 'too-many-requests': return 'Trop de tentatives, réessayez plus tard';
    case 'invalid-email': return 'Adresse email invalide';
    case 'email-not-verified': return 'Veuillez vérifier votre email avant de vous connecter';
    default: return 'Une erreur est survenue';
  }
}